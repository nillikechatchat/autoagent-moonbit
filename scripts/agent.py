#!/usr/bin/env python3
"""AutoAgent - real LLM agent with tool execution and memory persistence."""

import json
import os
import sys
import subprocess
import urllib.request
import urllib.error
from pathlib import Path
from datetime import datetime

# ============================================================
# Configuration
# ============================================================

AUTOAGENT_HOME = os.environ.get("AUTOAGENT_HOME", ".autoagent")
WORKSPACE = Path(AUTOAGENT_HOME) / "workspace"
MEMORY_DIR = WORKSPACE / "memory"
SESSIONS_DIR = WORKSPACE / "sessions"
CONFIG_FILE = Path(AUTOAGENT_HOME) / "config.json"
MEMORY_FILE = WORKSPACE / "memory.json"

def load_config():
    # Load from config file
    config = {
        "provider": {
            "name": "llm",
            "api_key": "",
            "base_url": "https://proxy.monkeycode-ai.com/v1",
            "model": "monkeycode-basic/qwen3.5-plus",
            "timeout_seconds": 60,
        },
        "agent": {
            "name": "AutoAgent",
            "system_prompt": "You are AutoAgent, a helpful AI assistant.",
            "max_steps": 10,
            "max_goal_length": 4000,
            "max_tool_output_length": 4000,
        },
    }
    if CONFIG_FILE.exists():
        try:
            with open(CONFIG_FILE) as f:
                file_config = json.load(f)
            for key in file_config:
                if key in config:
                    if isinstance(config[key], dict):
                        config[key].update(file_config[key])
                    else:
                        config[key] = file_config[key]
        except Exception:
            pass

    # Environment variables override config file
    if os.environ.get("MCAI_LLM_API_KEY"):
        config["provider"]["api_key"] = os.environ["MCAI_LLM_API_KEY"]
    if os.environ.get("OPENAI_API_KEY") and not config["provider"]["api_key"]:
        config["provider"]["api_key"] = os.environ["OPENAI_API_KEY"]
    if os.environ.get("MCAI_LLM_BASE_URL"):
        config["provider"]["base_url"] = os.environ["MCAI_LLM_BASE_URL"]
    if os.environ.get("MCAI_LLM_MODEL"):
        config["provider"]["model"] = os.environ["MCAI_LLM_MODEL"]

    return config

# ============================================================
# Memory - persistent JSON storage
# ============================================================

class Memory:
    def __init__(self):
        self.messages = []
        self.file = MEMORY_FILE
        self.load()

    def load(self):
        if self.file.exists():
            try:
                with open(self.file) as f:
                    self.messages = json.load(f)
            except Exception:
                self.messages = []

    def save(self):
        self.file.parent.mkdir(parents=True, exist_ok=True)
        with open(self.file, "w") as f:
            json.dump(self.messages, f, ensure_ascii=False, indent=2)

    def add(self, role, content):
        self.messages.append({"role": role, "content": content, "time": datetime.now().isoformat()})
        self.save()

    def get_context(self, max_chars=4000):
        """Return recent messages as context string."""
        result = []
        total = 0
        for msg in reversed(self.messages):
            entry = f"[{msg['role']}]: {msg['content']}"
            if total + len(entry) > max_chars:
                break
            result.append(entry)
            total += len(entry)
        result.reverse()
        return "\n".join(result)

    def get_messages_for_api(self, max_messages=20):
        """Return messages in OpenAI API format."""
        api_msgs = []
        for msg in self.messages[-max_messages:]:
            role = msg["role"]
            if role == "tool":
                role = "user"
            api_msgs.append({"role": role, "content": msg["content"]})
        return api_msgs

# ============================================================
# LLM Provider
# ============================================================

def call_llm(messages, config):
    """Call OpenAI-compatible API. Returns None if unavailable."""
    provider = config["provider"]
    api_key = provider.get("api_key", "")
    base_url = provider.get("base_url", "https://api.openai.com/v1").rstrip("/")
    model = provider.get("model", "gpt-4o-mini")
    timeout = provider.get("timeout_seconds", 30)

    if not api_key:
        return None

    url = f"{base_url}/chat/completions"
    payload = json.dumps({
        "model": model,
        "messages": messages,
        "temperature": 0.7,
        "max_tokens": 2000,
    }).encode("utf-8")

    req = urllib.request.Request(url, data=payload, headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}",
    })

    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            return data["choices"][0]["message"]["content"]
    except Exception:
        return None


def rule_based_respond(user_input, memory, config):
    """Rule-based fallback when LLM is unavailable. Actually executes tools."""
    import re

    lower = user_input.lower()

    # File creation: "create/write/make a FILE with CONTENT" - check BEFORE greeting
    create_match = re.search(r'(?:create|write|make|新建|创建)\s+(?:a\s+)?(?:file\s+)?[\'"]*(\S+\.\w+)', user_input, re.IGNORECASE)
    if create_match:
        filename = create_match.group(1)
        # Check if there's content specified
        content_match = re.search(r'(?:with|containing|内容)\s+[\'"]*(.+)', user_input, re.IGNORECASE)
        if content_match:
            content = content_match.group(1)
            result = execute_tool("write_file", json.dumps({"path": filename, "content": content}))
            return f"Created {filename}:\n{result}", [{"tool": "write_file", "input": filename, "result": result}]
        else:
            ext = filename.rsplit(".", 1)[-1] if "." in filename else ""
            templates = {
                "py": '#!/usr/bin/env python3\n\ndef main():\n    print("Hello, World!")\n\nif __name__ == "__main__":\n    main()\n',
                "js": 'console.log("Hello, World!");\n',
                "html": '<!DOCTYPE html>\n<html>\n<head><title>Page</title></head>\n<body><h1>Hello, World!</h1></body>\n</html>\n',
                "md": '# Title\n\nContent here.\n',
                "json": '{\n  "name": "project"\n}\n',
                "sh": '#!/bin/bash\necho "Hello, World!"\n',
                "txt": 'Hello, World!\n',
            }
            content = templates.get(ext, f"# {filename}\n")
            result = execute_tool("write_file", json.dumps({"path": filename, "content": content}))
            return f"Created {filename}:\n{result}", [{"tool": "write_file", "input": filename, "result": result}]

    # Greeting
    if any(w in lower for w in ["hello", "hi ", "hey", "你好"]) and len(user_input) < 20:
        return "Hi! I'm AutoAgent. I can read files, write files, run commands, and search the web. What would you like to do?", []

    # Generic
    return "I understand. You can ask me to:\n- read README.md\n- list files in src\n- create hello.py\n- run echo hello\n- search web for something", []

# ============================================================
# Tool execution
# ============================================================

TOOLS = [
    {
        "name": "read_file",
        "description": "Read a file from the workspace. Input: file path",
        "risk": "low",
    },
    {
        "name": "write_file",
        "description": "Write content to a file in the workspace. Input: JSON with 'path' and 'content'",
        "risk": "low",
    },
    {
        "name": "list_files",
        "description": "List files in a directory. Input: directory path (default: current dir)",
        "risk": "low",
    },
    {
        "name": "run_command",
        "description": "Run a shell command and return output. Input: command string",
        "risk": "medium",
    },
    {
        "name": "search_web",
        "description": "Search the web for information. Input: search query",
        "risk": "low",
    },
    {
        "name": "create_directory",
        "description": "Create a directory. Input: directory path",
        "risk": "low",
    },
]

def execute_tool(tool_name, tool_input):
    """Execute a tool and return the result."""
    try:
        if tool_name == "read_file":
            path = tool_input.strip()
            if not os.path.exists(path):
                return f"Error: File not found: {path}"
            with open(path) as f:
                content = f.read()
            if len(content) > 8000:
                content = content[:8000] + "\n... [truncated]"
            return content

        elif tool_name == "write_file":
            try:
                data = json.loads(tool_input)
                path = data["path"]
                content = data["content"]
            except (json.JSONDecodeError, KeyError):
                return "Error: Invalid input. Use JSON format: {\"path\": \"...\", \"content\": \"...\"}"
            Path(path).parent.mkdir(parents=True, exist_ok=True)
            with open(path, "w") as f:
                f.write(content)
            return f"Wrote {len(content)} bytes to {path}"

        elif tool_name == "list_files":
            path = tool_input.strip() or "."
            if not os.path.isdir(path):
                return f"Error: Not a directory: {path}"
            entries = []
            for entry in sorted(os.listdir(path)):
                full = os.path.join(path, entry)
                if os.path.isdir(full):
                    entries.append(f"  {entry}/")
                else:
                    size = os.path.getsize(full)
                    entries.append(f"  {entry} ({size} bytes)")
            if not entries:
                return f"Directory is empty: {path}"
            return "\n".join(entries)

        elif tool_name == "run_command":
            cmd = tool_input.strip()
            if not cmd:
                return "Error: Empty command"
            try:
                result = subprocess.run(
                    cmd, shell=True, capture_output=True, text=True, timeout=30,
                    cwd=os.getcwd()
                )
                output = result.stdout + result.stderr
                if len(output) > 4000:
                    output = output[:4000] + "\n... [truncated]"
                return output if output else "(no output)"
            except subprocess.TimeoutExpired:
                return "Error: Command timed out (30s limit)"

        elif tool_name == "search_web":
            query = tool_input.strip()
            url = f"https://html.duckduckgo.com/html/?q={urllib.request.quote(query)}"
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            try:
                with urllib.request.urlopen(req, timeout=10) as resp:
                    html = resp.read().decode("utf-8", errors="replace")
                import re
                snippets = re.findall(r'class="result__snippet"[^>]*>(.*?)</a>', html, re.DOTALL)
                results = []
                for i, s in enumerate(snippets[:5]):
                    clean = re.sub(r'<[^>]+>', '', s).strip()
                    if clean:
                        results.append(f"{i+1}. {clean}")
                return "\n".join(results) if results else f"No web results for: {query}"
            except Exception as e:
                return f"Web search unavailable ({type(e).__name__}). Try using run_command with curl instead."

        elif tool_name == "create_directory":
            path = tool_input.strip()
            Path(path).mkdir(parents=True, exist_ok=True)
            return f"Created directory: {path}"

        else:
            return f"Unknown tool: {tool_name}"

    except Exception as e:
        return f"Tool error: {e}"

# ============================================================
# Agent loop
# ============================================================

SYSTEM_PROMPT = """You are AutoAgent, a helpful AI assistant running in a terminal.

You have access to these tools:
- read_file: Read a file. Input: file path
- write_file: Write to a file. Input: JSON {"path": "...", "content": "..."}
- list_files: List directory contents. Input: path
- run_command: Run a shell command. Input: command
- search_web: Search the web. Input: query
- create_directory: Create a directory. Input: path

When you need to use a tool, respond with a JSON block:
```tool
{"name": "tool_name", "input": "tool_input"}
```

Rules:
1. When asked to build something, CREATE ACTUAL FILES with working code.
2. When asked to fix something, READ the relevant files first, then WRITE the fix.
3. Be concise. Show code, not explanations.
4. After creating files, verify they work (run commands if needed).
5. If you need to search for information, use search_web.
"""

def agent_turn(user_input, memory, config):
    """Run one agent turn: call LLM, handle tool calls, return response."""
    import re

    lower = user_input.lower()

    # Auto-detect tool calls from natural language
    auto_tools = []

    # File reading - match file paths case-insensitively for keywords but preserve path
    read_match = re.search(r'(?:read|show|cat|查看|读)\s+(?:file\s+)?[\'"]*([^\s\'"]+\.\w+)', user_input, re.IGNORECASE)
    if read_match:
        path = read_match.group(1)
        result = execute_tool("read_file", path)
        auto_tools.append({"tool": "read_file", "input": path, "result": result})

    # File listing - only match explicit list commands, not "ls" inside "run ls"
    if re.match(r'^(?:list|ls|dir)\b', lower) or any(w in lower for w in ["列出", "查看目录", "what files", "show files"]):
        path = "."
        dir_match = re.search(r'(?:in|of|at|from)\s+[\'"]*([^\s\'"]+)', lower)
        if dir_match:
            path = dir_match.group(1)
        result = execute_tool("list_files", path)
        auto_tools.append({"tool": "list_files", "input": path, "result": result})

    # Command execution
    cmd_match = re.search(r'^(?:run|execute|执行|运行)\s+[\'"]*(.+)', user_input, re.IGNORECASE)
    if cmd_match:
        cmd = cmd_match.group(1).strip()
        result = execute_tool("run_command", cmd)
        auto_tools.append({"tool": "run_command", "input": cmd, "result": result})

    # If auto-detected tools, show results
    if auto_tools:
        response_parts = []
        for tr in auto_tools:
            response_parts.append(f"[{tr['tool']}]\n{tr['result']}")
        return "\n\n".join(response_parts), auto_tools

    # Try LLM
    messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    context = memory.get_context(max_chars=2000)
    if context:
        messages.append({"role": "user", "content": f"Previous:\n{context}\n\nNow: {user_input}"})
    else:
        messages.append({"role": "user", "content": user_input})

    llm_response = call_llm(messages, config)

    if llm_response:
        # Check for tool calls in LLM response
        tool_call = parse_tool_call(llm_response)
        if tool_call:
            result = execute_tool(tool_call["name"], tool_call.get("input", ""))
            # Remove the tool call block from response
            clean = re.sub(r'```tool\s*\n.*?\n```', '', llm_response, flags=re.DOTALL).strip()
            return f"{clean}\n\n[{tool_call['name']}]\n{result}", [{"tool": tool_call["name"], "input": tool_call.get("input", ""), "result": result}]
        return llm_response, []

    # Fallback to rule-based
    return rule_based_respond(user_input, memory, config)

def parse_tool_call(response):
    """Parse tool call from LLM response."""
    import re
    match = re.search(r'```tool\s*\n(.*?)\n```', response, re.DOTALL)
    if match:
        try:
            return json.loads(match.group(1))
        except json.JSONDecodeError:
            pass
    return None

# ============================================================
# CLI interface
# ============================================================

def cmd_chat(args):
    """Interactive chat mode."""
    config = load_config()
    memory = Memory()

    provider = config["provider"]
    has_llm = bool(provider.get("api_key"))

    print("\033[1;36m  AutoAgent\033[0m \033[2mv0.2.0\033[0m")
    if has_llm:
        print(f"  \033[2mModel: {provider.get('model', 'unknown')}\033[0m")
    else:
        print("  \033[2mMode: rule-based (no LLM API key)\033[0m")
    print(f"  \033[2mMemory: {len(memory.messages)} messages\033[0m")
    print()
    print("  I can read files, write files, run commands, and search the web.")
    print("  Just tell me what you need. Commands: /clear /history /quit")
    print()

    while True:
        try:
            user_input = input("\033[1;35m> \033[0m").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nGoodbye!")
            break

        if not user_input:
            continue

        if user_input == "/quit" or user_input == "/exit":
            print("Goodbye!")
            break

        if user_input == "/clear":
            memory.messages = []
            memory.save()
            print("  Memory cleared.")
            continue

        if user_input == "/history":
            for msg in memory.messages[-10:]:
                print(f"  [{msg['role']}] {msg['content'][:100]}...")
            continue

        # Add user message to memory
        memory.add("user", user_input)

        # Run agent turn
        print("\033[33m  thinking...\033[0m", end="", flush=True)
        response, tool_results = agent_turn(user_input, memory, config)
        print("\r                      \r", end="", flush=True)

        # Show tool results
        for tr in tool_results:
            print(f"\033[33m  [{tr['tool']}]\033[0m {tr['result'][:200]}")
            print()

        # Show response
        print(response)
        print()

        # Save response to memory
        memory.add("assistant", response)

def cmd_run(args):
    """Single-shot mode."""
    config = load_config()
    memory = Memory()

    if not args:
        print("Usage: autoagent.py run <message>")
        return

    user_input = " ".join(args)
    memory.add("user", user_input)

    response, tool_results = agent_turn(user_input, memory, config)

    # Print response (includes tool results)
    print(response)
    memory.add("assistant", response)

def cmd_tools(args):
    """List available tools."""
    print("Available tools:")
    for t in TOOLS:
        print(f"  {t['name']}: {t['description']}")

def cmd_memory(args):
    """Show memory status."""
    memory = Memory()
    print(f"Messages: {len(memory.messages)}")
    print(f"File: {memory.file}")
    if memory.messages:
        print("\nRecent:")
        for msg in memory.messages[-5:]:
            print(f"  [{msg['role']}] {msg['content'][:80]}...")

def main():
    if len(sys.argv) < 2:
        cmd_chat([])
        return

    cmd = sys.argv[1]
    args = sys.argv[2:]

    if cmd == "chat":
        cmd_chat(args)
    elif cmd == "run":
        cmd_run(args)
    elif cmd == "tools":
        cmd_tools(args)
    elif cmd == "memory":
        cmd_memory(args)
    elif cmd == "help" or cmd == "--help":
        print("AutoAgent - real LLM agent with tools and memory")
        print()
        print("Usage:")
        print("  autoagent.py              Start interactive chat")
        print("  autoagent.py chat         Start interactive chat")
        print("  autoagent.py run <msg>    Single-shot mode")
        print("  autoagent.py tools        List available tools")
        print("  autoagent.py memory       Show memory status")
    else:
        # Treat unknown command as a message
        cmd_run([cmd] + args)

if __name__ == "__main__":
    main()
