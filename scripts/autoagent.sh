#!/bin/bash
# AutoAgent - MoonBit brain, Shell hands
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

AUTOAGENT_HOME="${AUTOAGENT_HOME:-.autoagent}"
WORKSPACE="$AUTOAGENT_HOME/workspace"
MEMORY_FILE="$WORKSPACE/memory.json"

# Build MoonBit binary
BINARY=""
build() {
  if [ -f "_build/native/release/build/src/main/main.exe" ]; then
    BINARY="_build/native/release/build/src/main/main.exe"
    return
  fi
  echo "Building..." >&2
  PATH="$HOME/.moon/bin:$PATH" make build-native 2>&1 >&2
  BINARY="_build/native/release/build/src/main/main.exe"
}

# Initialize workspace
init() {
  mkdir -p "$WORKSPACE/sessions" "$WORKSPACE/memory"
  [ ! -f "$AUTOAGENT_HOME/config.json" ] && cat > "$AUTOAGENT_HOME/config.json" <<'JSON'
{"provider":{"name":"llm","api_key":"","base_url":"https://proxy.monkeycode-ai.com/v1","model":"monkeycode-basic/qwen3.5-plus","timeout_seconds":30},"agent":{"name":"AutoAgent","system_prompt":"You are AutoAgent.","max_steps":10,"max_goal_length":4000,"max_tool_output_length":4000}}
JSON
  [ ! -f "$MEMORY_FILE" ] && echo "[]" > "$MEMORY_FILE"
}

# Read/write memory
mem_read() { cat "$MEMORY_FILE" 2>/dev/null || echo "[]"; }
mem_write() { echo "$1" > "$MEMORY_FILE"; }
mem_add() {
  local role="$1" content="$2"
  python3 -c "
import json, sys
m = json.loads(sys.stdin.read())
m.append({'role': '$role', 'content': sys.argv[1]})
print(json.dumps(m))
" "$content" | mem_write "$(cat)"
}

# Call MoonBit brain
moonbit_plan() {
  local goal="$1"
  "$BINARY" --json "{\"cmd\":\"plan\",\"goal\":\"$goal\"}"
}

moonbit_parse() {
  local response="$1"
  "$BINARY" --json "{\"cmd\":\"parse\",\"response\":\"$response\"}"
}

moonbit_tool_result() {
  local tool="$1" result="$2"
  "$BINARY" --json "{\"cmd\":\"tool_result\",\"tool\":\"$tool\",\"result\":\"$result\"}"
}

# Call LLM API
call_llm() {
  local messages_json="$1"
  local api_key="${MCAI_LLM_API_KEY:-${OPENAI_API_KEY:-}}"
  local base_url="${MCAI_LLM_BASE_URL:-https://proxy.monkeycode-ai.com/v1}"
  local model="${MCAI_LLM_MODEL:-monkeycode-basic/qwen3.5-plus}"

  if [ -z "$api_key" ]; then
    python3 -c "
import json
with open('$AUTOAGENT_HOME/config.json') as f:
    c = json.load(f)
p = c.get('provider', {})
print(p.get('api_key', ''))
print(p.get('base_url', 'https://proxy.monkeycode-ai.com/v1'))
print(p.get('model', 'monkeycode-basic/qwen3.5-plus'))
" | {
    read -r api_key
    read -r base_url
    read -r model
  }
  fi

  if [ -z "$api_key" ]; then
    echo '{"error":"No API key configured"}'
    return
  fi

  local payload
  payload=$(python3 -c "
import json, sys
msgs = json.loads(sys.argv[1])
print(json.dumps({'model': sys.argv[2], 'messages': msgs, 'temperature': 0.7, 'max_tokens': 2000}))
" "$messages_json" "$model")

  curl -s --max-time 30 \
    "$base_url/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $api_key" \
    -d "$payload" 2>/dev/null | python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    print(d['choices'][0]['message']['content'])
except: print('')
" 2>/dev/null || echo ""
}

# Execute tool
exec_tool() {
  local name="$1" input="$2"
  case "$name" in
    read_file)
      [ -f "$input" ] && cat "$input" | head -c 8000 || echo "Error: File not found: $input"
      ;;
    write_file)
      python3 -c "
import json, sys, os
d = json.loads(sys.argv[1])
os.makedirs(os.path.dirname(d['path']) or '.', exist_ok=True)
open(d['path'],'w').write(d['content'])
print(f'Wrote {len(d[\"content\"])} bytes to {d[\"path\"]}')
" "$input"
      ;;
    list_files)
      local dir="${input:-.}"
      [ -d "$dir" ] && ls -la "$dir" 2>&1 | head -30 || echo "Error: Not a directory: $dir"
      ;;
    run_command)
      eval "$input" 2>&1 | head -c 4000 || true
      ;;
    search_web)
      python3 -c "
import urllib.request, re, sys
q = sys.argv[1]
u = f'https://html.duckduckgo.com/html/?q={urllib.request.quote(q)}'
r = urllib.request.Request(u, headers={'User-Agent':'Mozilla/5.0'})
try:
    h = urllib.request.urlopen(r, timeout=10).read().decode('utf-8','replace')
    for i,s in enumerate(re.findall(r'class=\"result__snippet\"[^>]*>(.*?)</a>',h,re.DOTALL)[:5]):
        c = re.sub(r'<[^>]+>','',s).strip()
        if c: print(f'{i+1}. {c}')
except Exception as e: print(f'Search unavailable: {e}')
" "$input" 2>&1
      ;;
    *)
      echo "Unknown tool: $name"
      ;;
  esac
}

# Main agent loop
agent_run() {
  local user_input="$1"
  local session_file="$2"
  local max_rounds=5

  # MoonBit: plan
  local plan
  plan=$(moonbit_plan "$user_input")
  local action
  action=$(echo "$plan" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('action',''))")

  if [ "$action" = "error" ]; then
    echo "$plan" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('message',''))"
    return
  fi

  # Build LLM messages from memory
  local messages
  messages=$(python3 -c "
import json, sys
mem = json.loads(open('$MEMORY_FILE').read())
msgs = [{'role':'system','content':'You are AutoAgent. You can read files, write files, run commands, and search the web.\n\nTools:\n- read_file: Input: file path\n- write_file: Input: JSON {\"path\":\"...\",\"content\":\"...\"}\n- list_files: Input: path\n- run_command: Input: command\n- search_web: Input: query\n\nTo use a tool:\n```tool\n{\"name\":\"...\",\"input\":\"...\"}\n```\nBe concise. Create actual files when asked.'}]
for m in mem[-10:]:
    msgs.append({'role':m['role'],'content':m['content']})
msgs.append({'role':'user','content':sys.argv[1]})
print(json.dumps(msgs))
" "$user_input")

  local round=0
  while [ $round -lt $max_rounds ]; do
    # Call LLM
    printf '\033[33m  thinking...\033[0m\r' >&2
    local llm_response
    llm_response=$(call_llm "$messages")

    if [ -z "$llm_response" ]; then
      echo "LLM returned empty response. Check API key and network."
      return
    fi

    # MoonBit: parse response
    local parsed
    parsed=$(moonbit_parse "$llm_response")
    action=$(echo "$parsed" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('action',''))")

    if [ "$action" = "reply" ]; then
      # Final answer
      local text
      text=$(echo "$parsed" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('text',''))")
      echo "$text"

      # Save to memory and session
      mem_add "user" "$user_input"
      mem_add "assistant" "$text"
      printf '## User\n%s\n\n## Assistant\n%s\n\n' "$user_input" "$text" >> "$session_file"
      return

    elif [ "$action" = "tool" ]; then
      # Execute tool
      local tool_name tool_input
      tool_name=$(echo "$parsed" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('name',''))")
      tool_input=$(echo "$parsed" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('input',''))")

      printf '\033[33m  [%s]\033[0m\n' "$tool_name" >&2
      local tool_result
      tool_result=$(exec_tool "$tool_name" "$tool_input")
      echo "$tool_result" | head -5 >&2

      # MoonBit: process tool result
      local tool_parsed
      tool_parsed=$(moonbit_tool_result "$tool_name" "$tool_result")
      local tool_action
      tool_action=$(echo "$tool_parsed" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('action',''))")

      # Add to conversation for next LLM call
      messages=$(python3 -c "
import json, sys
msgs = json.loads(sys.argv[1])
msgs.append({'role':'assistant','content':sys.argv[2]})
msgs.append({'role':'user','content':'[' + sys.argv[3] + ' result]:\n' + sys.argv[4]})
print(json.dumps(msgs))
" "$messages" "$llm_response" "$tool_name" "$tool_result")

    elif [ "$action" = "think" ]; then
      local reason
      reason=$(echo "$parsed" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('reason',''))")
      echo "$reason" >&2

    else
      echo "Unknown action: $action"
      return
    fi

    round=$((round + 1))
  done

  echo "Reached max rounds ($max_rounds)."
}

# Interactive chat
chat() {
  init
  build

  local session="$WORKSPACE/sessions/$(date +%Y%m%d-%H%M%S).md"
  printf '# Session\n\n' > "$session"

  local mem_count
  mem_count=$(mem_read | python3 -c "import json,sys; print(len(json.loads(sys.stdin.read())))")

  printf '\n  \033[1;36mAutoAgent\033[0m \033[2mv0.2.0\033[0m\n'
  printf '  \033[2mBrain: MoonBit | Hands: Shell\033[0m\n'
  printf '  \033[2mMemory: %s messages\033[0m\n\n' "$mem_count"
  printf '  I can read/write files, run commands, search the web.\n'
  printf '  Commands: /clear /history /quit\n\n'

  while true; do
    printf '\033[1;35m>\033[0m '
    IFS= read -r input || break
    input=$(printf '%s' "$input" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "$input" ] && continue

    case "$input" in
      /quit|/exit) echo "Goodbye!"; break ;;
      /clear) echo "[]" > "$MEMORY_FILE"; echo "  Memory cleared." ;;
      /history) [ -f "$session" ] && cat "$session" ;;
      *) agent_run "$input" "$session" ; echo ;;
    esac
  done
}

# Entry
case "${1:-chat}" in
  init) init; echo "Initialized." ;;
  chat|repl|"") chat ;;
  run) shift; init; build; agent_run "$*" "$WORKSPACE/sessions/oneshot.md" ;;
  tools) echo "Tools: read_file, write_file, list_files, run_command, search_web" ;;
  memory) mem_read | python3 -c "import json,sys; m=json.loads(sys.stdin.read()); print(f'{len(m)} messages')" ;;
  *) init; build; agent_run "$*" "$WORKSPACE/sessions/oneshot.md" ;;
esac
