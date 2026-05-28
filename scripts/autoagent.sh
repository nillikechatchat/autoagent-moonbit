#!/bin/bash
# AutoAgent interactive shell with initialization, sessions, and workspace memory.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BINARY=""
if [ -f "_build/native/release/build/src/main/main.exe" ]; then
  BINARY="_build/native/release/build/src/main/main.exe"
elif [ -f "_build/dist/autoagent" ]; then
  BINARY="_build/dist/autoagent"
else
  echo "AutoAgent binary is missing. Run: make build-native"
  exit 1
fi

AUTOAGENT_HOME="${AUTOAGENT_HOME:-.autoagent}"
WORKSPACE_DIR="$AUTOAGENT_HOME/workspace"
SESSIONS_DIR="$WORKSPACE_DIR/sessions"
MEMORY_DIR="$WORKSPACE_DIR/memory"
ARTIFACTS_DIR="$WORKSPACE_DIR/artifacts"
CONFIG_FILE="$AUTOAGENT_HOME/config.json"
MAX_STEPS="${AUTOAGENT_MAX_STEPS:-3}"

init_workspace() {
  mkdir -p "$SESSIONS_DIR" "$MEMORY_DIR" "$ARTIFACTS_DIR"

  if [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$AUTOAGENT_HOME"
    cat > "$CONFIG_FILE" <<'JSON'
{
  "provider": {
    "name": "deterministic",
    "api_key": "",
    "base_url": "",
    "model": "",
    "timeout_seconds": 30
  },
  "agent": {
    "name": "AutoAgent",
    "system_prompt": "Help users build useful agents with initialization, interaction, memory, safe tools, and production checks.",
    "max_steps": 5,
    "max_goal_length": 2000,
    "max_tool_output_length": 2000
  }
}
JSON
  fi

  if [ ! -f "$MEMORY_DIR/user.md" ]; then
    printf '# User Memory\n\nStable preferences and repeated user facts go here.\n' > "$MEMORY_DIR/user.md"
  fi

  if [ ! -f "$MEMORY_DIR/experiences.md" ]; then
    printf '# Experience Memory\n\nValidated outcomes, regressions, and useful answers go here.\n' > "$MEMORY_DIR/experiences.md"
  fi

  if [ ! -f "$MEMORY_DIR/archive.md" ]; then
    printf '# Archive Memory\n\nLong transcripts and low-frequency notes go here.\n' > "$MEMORY_DIR/archive.md"
  fi

  echo "Initialized AutoAgent workspace:"
  echo "  config:    $CONFIG_FILE"
  echo "  sessions:  $SESSIONS_DIR"
  echo "  memory:    $MEMORY_DIR"
  echo "  artifacts: $ARTIFACTS_DIR"
}

new_session_file() {
  local session_id
  session_id="$(date +%Y%m%d-%H%M%S)"
  echo "$SESSIONS_DIR/$session_id.md"
}

show_help() {
  echo "AutoAgent interactive commands:"
  echo "  /help            Show commands"
  echo "  /status          Show workspace and session status"
  echo "  /config          Show runtime configuration"
  echo "  /history         Show current session log"
  echo "  /memory          Show memory files"
  echo "  /run N           Set max steps for future turns"
  echo "  /save TEXT       Append TEXT to experience memory"
  echo "  /quit            Exit"
}

show_memory() {
  echo "Memory files:"
  echo "  $MEMORY_DIR/user.md"
  echo "  $MEMORY_DIR/experiences.md"
  echo "  $MEMORY_DIR/archive.md"
}

run_turn() {
  local session_file="$1"
  local input="$2"
  local turn_output

  printf '\n## User\n%s\n' "$input" >> "$session_file"
  echo ""
  echo "Agent is thinking with max_steps=$MAX_STEPS ..."
  echo ""
  turn_output="$($BINARY --max-steps "$MAX_STEPS" "$input")"
  printf '%s\n' "$turn_output"
  printf '\n## Assistant\n%s\n' "$turn_output" >> "$session_file"
  echo ""
  echo "Saved turn: $session_file"
}

chat_loop() {
  init_workspace >/dev/null
  local session_file
  session_file="$(new_session_file)"
  printf '# AutoAgent Session\n\n- Started: %s\n- Max steps: %s\n\n' "$(date -Iseconds)" "$MAX_STEPS" > "$session_file"

  echo "AutoAgent session initialized."
  echo "  session: $session_file"
  echo "  config:  $CONFIG_FILE"
  echo "  memory:  $MEMORY_DIR"
  echo ""
  echo "Type a goal or message. Use /help for commands."

  while true; do
    printf '\nautoagent> '
    IFS= read -r input || break

    if [ -z "$input" ]; then
      continue
    fi

    case "$input" in
      /help|/h)
        show_help
        ;;
      /status)
        echo "Workspace: $WORKSPACE_DIR"
        echo "Session:   $session_file"
        echo "Max steps: $MAX_STEPS"
        ;;
      /config)
        "$BINARY" --config
        ;;
      /history)
        sed -n '1,220p' "$session_file"
        ;;
      /memory)
        show_memory
        ;;
      /quit|/exit)
        echo "Session saved: $session_file"
        break
        ;;
      /run\ *)
        MAX_STEPS="${input#/run }"
        echo "Max steps set to $MAX_STEPS"
        ;;
      /save\ *)
        printf '\n## Saved Experience\n%s\n' "${input#/save }" >> "$MEMORY_DIR/experiences.md"
        echo "Saved to $MEMORY_DIR/experiences.md"
        ;;
      /*)
        echo "Unknown command. Use /help."
        ;;
      *)
        run_turn "$session_file" "$input"
        ;;
    esac
  done
}

case "${1:-chat}" in
  init)
    init_workspace
    ;;
  chat|repl)
    chat_loop
    ;;
  run)
    shift
    "$BINARY" "$@"
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    chat_loop
    ;;
esac
