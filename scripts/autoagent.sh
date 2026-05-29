#!/usr/bin/env bash
# AutoAgent runtime shell: MoonBit decides, shell performs I/O.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

AUTOAGENT_HOME="${AUTOAGENT_HOME:-.autoagent}"
WORKSPACE="$AUTOAGENT_HOME/workspace"
MEMORY_FILE="$WORKSPACE/memory.json"
SESSION_DIR="$WORKSPACE/sessions"
BINARY=""

build() {
  if [ -f "_build/native/release/build/src/main/main.exe" ]; then
    BINARY="_build/native/release/build/src/main/main.exe"
    return
  fi

  printf 'Building MoonBit runtime...\n' >&2
  PATH="$HOME/.moon/bin:$PATH" make build-native >/dev/null
  BINARY="_build/native/release/build/src/main/main.exe"
}

init() {
  mkdir -p "$SESSION_DIR" "$WORKSPACE/memory"
  if [ ! -f "$AUTOAGENT_HOME/config.json" ]; then
    python3 - <<'PY'
import json
from pathlib import Path

config = {
    "provider": {
        "name": "llm",
        "api_key": "",
        "base_url": "https://proxy.monkeycode-ai.com/v1",
        "model": "monkeycode-basic/qwen3.5-plus",
        "timeout_seconds": 30,
    },
    "agent": {
        "name": "AutoAgent",
        "system_prompt": "You are AutoAgent. Use tools only when needed and keep answers concise.",
        "max_steps": 10,
        "max_goal_length": 4000,
        "max_tool_output_length": 4000,
    },
}

path = Path(".autoagent/config.json")
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
PY
  fi

  if [ ! -f "$MEMORY_FILE" ]; then
    python3 - "$MEMORY_FILE" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text("[]\n", encoding="utf-8")
PY
  fi
}

json_request() {
  python3 - "$@" <<'PY'
import json
import sys

cmd = sys.argv[1]
payload = {"cmd": cmd}

if cmd == "plan":
    payload["goal"] = sys.argv[2]
elif cmd == "parse":
    payload["response"] = sys.argv[2]
elif cmd == "tool_result":
    payload["tool"] = sys.argv[2]
    payload["result"] = sys.argv[3]
else:
    raise SystemExit(f"unknown request command: {cmd}")

print(json.dumps(payload, ensure_ascii=False))
PY
}

json_get() {
  local field="$1"
  python3 -c '
import json
import sys

field = sys.argv[1]
try:
    data = json.loads(sys.stdin.read())
except json.JSONDecodeError:
    print("")
    raise SystemExit(0)

value = data.get(field, "")
if value is None:
    value = ""
print(value)
' "$field"
}

moonbit_plan() {
  local request
  request=$(json_request plan "$1")
  "$BINARY" --json "$request"
}

moonbit_parse() {
  local request
  request=$(json_request parse "$1")
  "$BINARY" --json "$request"
}

moonbit_tool_result() {
  local request
  request=$(json_request tool_result "$1" "$2")
  "$BINARY" --json "$request"
}

mem_count() {
  python3 - "$MEMORY_FILE" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    print(len(json.loads(path.read_text(encoding="utf-8"))))
except Exception:
    print(0)
PY
}

mem_add() {
  local role="$1"
  local content="$2"
  python3 - "$MEMORY_FILE" "$role" "$content" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
role = sys.argv[2]
content = sys.argv[3]

try:
    data = json.loads(path.read_text(encoding="utf-8"))
except Exception:
    data = []

data.append({"role": role, "content": content})
path.write_text(json.dumps(data[-40:], ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
}

build_messages() {
  local user_input="$1"
  python3 - "$MEMORY_FILE" "$user_input" <<'PY'
import json
import sys
from pathlib import Path

memory_path = Path(sys.argv[1])
user_input = sys.argv[2]

system = """You are AutoAgent. MoonBit owns planning, tool-call parsing, state, and response decisions. The shell only performs I/O.

Available tools:
- read_file: input is a path inside the current project
- write_file: input is JSON {"path":"...","content":"..."}
- list_files: input is a directory inside the current project
- run_command: input is a bounded local development command
- search_web: input is a search query

To use a tool, return exactly one fenced block:
```tool
{"name":"read_file","input":"README.md"}
```

When no tool is needed, answer normally. Keep responses concise."""

try:
    memory = json.loads(memory_path.read_text(encoding="utf-8"))
except Exception:
    memory = []

messages = [{"role": "system", "content": system}]
for item in memory[-12:]:
    role = item.get("role", "user")
    content = item.get("content", "")
    if role in {"user", "assistant"} and content:
        messages.append({"role": role, "content": content})
messages.append({"role": "user", "content": user_input})
print(json.dumps(messages, ensure_ascii=False))
PY
}

append_messages() {
  local messages="$1"
  local assistant_text="$2"
  local tool_name="$3"
  local tool_result="$4"
  python3 - "$messages" "$assistant_text" "$tool_name" "$tool_result" <<'PY'
import json
import sys

messages = json.loads(sys.argv[1])
messages.append({"role": "assistant", "content": sys.argv[2]})
messages.append({"role": "user", "content": f"[{sys.argv[3]} result]:\n{sys.argv[4]}"})
print(json.dumps(messages, ensure_ascii=False))
PY
}

load_provider_config() {
  python3 - "$AUTOAGENT_HOME/config.json" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    provider = json.loads(path.read_text(encoding="utf-8")).get("provider", {})
except Exception:
    provider = {}

print(provider.get("api_key", ""))
print(provider.get("base_url", "https://proxy.monkeycode-ai.com/v1"))
print(provider.get("model", "monkeycode-basic/qwen3.5-plus"))
print(str(provider.get("timeout_seconds", 30)))
PY
}

call_llm() {
  local messages_json="$1"
  local api_key="${MCAI_LLM_API_KEY:-${OPENAI_API_KEY:-}}"
  local base_url="${MCAI_LLM_BASE_URL:-}"
  local model="${MCAI_LLM_MODEL:-}"
  local timeout_seconds="30"

  if [ -z "$api_key" ] || [ -z "$base_url" ] || [ -z "$model" ]; then
    mapfile -t provider_config < <(load_provider_config)
    if [ -z "$api_key" ]; then api_key="${provider_config[0]:-}"; fi
    if [ -z "$base_url" ]; then base_url="${provider_config[1]:-https://proxy.monkeycode-ai.com/v1}"; fi
    if [ -z "$model" ]; then model="${provider_config[2]:-monkeycode-basic/qwen3.5-plus}"; fi
    timeout_seconds="${provider_config[3]:-30}"
  fi

  if [ -z "$api_key" ]; then
    printf ''
    return
  fi

  local payload
  payload=$(python3 - "$messages_json" "$model" <<'PY'
import json
import sys

messages = json.loads(sys.argv[1])
payload = {
    "model": sys.argv[2],
    "messages": messages,
    "temperature": 0.2,
    "max_tokens": 2000,
}
print(json.dumps(payload, ensure_ascii=False))
PY
)

  curl -sS --max-time "$timeout_seconds" \
    "$base_url/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $api_key" \
    -d "$payload" 2>/dev/null | python3 -c '
import json
import sys

try:
    data = json.loads(sys.stdin.read())
    print(data["choices"][0]["message"]["content"])
except Exception:
    print("")
'
}

safe_project_path() {
  local raw_path="$1"
  python3 - "$ROOT_DIR" "$raw_path" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
target = (root / sys.argv[2]).resolve()
try:
    target.relative_to(root)
except ValueError:
    raise SystemExit(1)
print(target)
PY
}

deny_unsafe_command() {
  local command="$1"
  python3 - "$command" <<'PY'
import re
import sys

command = sys.argv[1].strip()
blocked = [
    r"(^|\s)rm(\s|$)",
    r"(^|\s)rmdir(\s|$)",
    r"(^|\s)unlink(\s|$)",
    r"(^|\s)git\s+rm(\s|$)",
    r"(^|\s)git\s+clean(\s|$)",
    r"(^|\s)docker\s+(rm|rmi|system\s+prune|volume\s+rm)(\s|$)",
    r"(^|\s)(shutdown|reboot|poweroff|sudo|su)(\s|$)",
    r"--delete(\s|$)",
    r"\bDROP\s+(TABLE|DATABASE)\b",
    r"\bTRUNCATE\s+TABLE\b",
]

if any(re.search(pattern, command, flags=re.IGNORECASE) for pattern in blocked):
    raise SystemExit(1)
PY
}

exec_tool() {
  local name="$1"
  local input="$2"
  case "$name" in
    read_file)
      local path
      if ! path=$(safe_project_path "$input"); then
        printf 'Error: path is outside project: %s\n' "$input"
        return
      fi
      python3 - "$path" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
if not path.is_file():
    print(f"Error: file not found: {path}")
else:
    print(path.read_text(encoding="utf-8", errors="replace")[:8000])
PY
      ;;
    write_file)
      python3 - "$ROOT_DIR" "$input" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
data = json.loads(sys.argv[2])
target = (root / data["path"]).resolve()
try:
    target.relative_to(root)
except ValueError:
    print(f"Error: path is outside project: {data['path']}")
    raise SystemExit(0)

target.parent.mkdir(parents=True, exist_ok=True)
content = data.get("content", "")
target.write_text(content, encoding="utf-8")
print(f"Wrote {len(content)} bytes to {target.relative_to(root)}")
PY
      ;;
    list_files)
      local dir_path
      if ! dir_path=$(safe_project_path "${input:-.}"); then
        printf 'Error: path is outside project: %s\n' "${input:-.}"
        return
      fi
      python3 - "$ROOT_DIR" "$dir_path" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
path = Path(sys.argv[2])
if not path.is_dir():
    print(f"Error: not a directory: {path}")
else:
    for child in sorted(path.iterdir(), key=lambda item: (not item.is_dir(), item.name.lower()))[:80]:
        suffix = "/" if child.is_dir() else ""
        print(f"{child.relative_to(root)}{suffix}")
PY
      ;;
    run_command)
      if ! deny_unsafe_command "$input"; then
        printf 'Error: command refused by local safety policy\n'
        return
      fi
      /bin/bash -lc "$input" 2>&1 | python3 - <<'PY'
import sys

print(sys.stdin.read()[:4000])
PY
      ;;
    search_web)
      python3 - "$input" <<'PY'
import re
import sys
import urllib.parse
import urllib.request

query = urllib.parse.quote(sys.argv[1])
url = f"https://html.duckduckgo.com/html/?q={query}"
request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
try:
    html = urllib.request.urlopen(request, timeout=10).read().decode("utf-8", "replace")
    snippets = re.findall(r'class="result__snippet"[^>]*>(.*?)</a>', html, re.DOTALL)[:5]
    for index, snippet in enumerate(snippets, 1):
        text = re.sub(r"<[^>]+>", "", snippet).strip()
        if text:
            print(f"{index}. {text}")
except Exception as exc:
    print(f"Search unavailable: {exc}")
PY
      ;;
    *)
      printf 'Unknown tool: %s\n' "$name"
      ;;
  esac
}

print_preview() {
  python3 -c '
import sys

lines = sys.stdin.read().splitlines()
for line in lines[:5]:
    print(line)
'
}

agent_run() {
  local user_input="$1"
  local session_file="$2"
  local max_rounds=6

  local plan action messages round
  plan=$(moonbit_plan "$user_input")
  action=$(printf '%s' "$plan" | json_get action)

  if [ "$action" = "error" ]; then
    printf '%s\n' "$plan" | json_get message
    return
  fi

  messages=$(build_messages "$user_input")
  round=0

  while [ "$round" -lt "$max_rounds" ]; do
    printf '\033[33m  thinking...\033[0m\r' >&2
    local llm_response parsed
    llm_response=$(call_llm "$messages")

    if [ -z "$llm_response" ]; then
      "$BINARY" "$user_input"
      return
    fi

    parsed=$(moonbit_parse "$llm_response")
    action=$(printf '%s' "$parsed" | json_get action)

    if [ "$action" = "reply" ]; then
      local text
      text=$(printf '%s' "$parsed" | json_get text)
      printf '%s\n' "$text"
      mem_add "user" "$user_input"
      mem_add "assistant" "$text"
      printf '## User\n%s\n\n## Assistant\n%s\n\n' "$user_input" "$text" >> "$session_file"
      return
    fi

    if [ "$action" = "tool" ]; then
      local tool_name tool_input tool_result
      tool_name=$(printf '%s' "$parsed" | json_get name)
      tool_input=$(printf '%s' "$parsed" | json_get input)
      printf '\033[33m  [%s]\033[0m\n' "$tool_name" >&2
      tool_result=$(exec_tool "$tool_name" "$tool_input")
      printf '%s\n' "$tool_result" | print_preview >&2
      moonbit_tool_result "$tool_name" "$tool_result" >/dev/null
      messages=$(append_messages "$messages" "$llm_response" "$tool_name" "$tool_result")
    elif [ "$action" = "think" ]; then
      printf '%s\n' "$parsed" | json_get reason >&2
    else
      printf 'Unknown action: %s\n' "$action"
      return
    fi

    round=$((round + 1))
  done

  printf 'Reached max rounds (%s).\n' "$max_rounds"
}

chat() {
  init
  build

  local session="$SESSION_DIR/$(date +%Y%m%d-%H%M%S).md"
  printf '# Session\n\n' > "$session"

  printf '\n  \033[1;36mAutoAgent\033[0m \033[2mv0.2.0\033[0m\n'
  printf '  \033[2mBrain: MoonBit | Hands: Shell\033[0m\n'
  printf '  \033[2mMemory: %s messages\033[0m\n\n' "$(mem_count)"
  printf '  Commands: /clear /history /skills /skill NAME /quit\n\n'

  while true; do
    printf '\033[1;35m>\033[0m '
    IFS= read -r input || break
    input="$(python3 - "$input" <<'PY'
import sys
print(sys.argv[1].strip())
PY
)"
    [ -z "$input" ] && continue

    case "$input" in
      /quit|/exit) printf 'Goodbye.\n'; break ;;
      /clear) python3 - "$MEMORY_FILE" <<'PY'
from pathlib import Path
import sys
Path(sys.argv[1]).write_text("[]\n", encoding="utf-8")
PY
        printf 'Memory cleared.\n' ;;
      /history) python3 - "$session" <<'PY'
from pathlib import Path
import sys
print(Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace"))
PY
        ;;
      /skills) "$BINARY" --skills ;;
      /skill\ *) "$BINARY" --skill "${input#/skill }" ;;
      *) agent_run "$input" "$session"; printf '\n' ;;
    esac
  done
}

case "${1:-chat}" in
  init)
    init
    printf 'Initialized.\n'
    ;;
  chat|repl|"")
    chat
    ;;
  run)
    shift
    init
    build
    agent_run "$*" "$SESSION_DIR/oneshot.md"
    ;;
  tools)
    printf 'Tools: read_file, write_file, list_files, run_command, search_web\n'
    ;;
  memory)
    init
    printf '%s messages\n' "$(mem_count)"
    ;;
  *)
    init
    build
    agent_run "$*" "$SESSION_DIR/oneshot.md"
    ;;
esac
