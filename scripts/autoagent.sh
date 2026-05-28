#!/bin/bash
# AutoAgent - conversational agent shell
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BINARY=""
if [ -f "_build/native/release/build/src/main/main.exe" ]; then
  BINARY="_build/native/release/build/src/main/main.exe"
elif [ -f "_build/dist/autoagent" ]; then
  BINARY="_build/dist/autoagent"
else
  echo "AutoAgent binary not found. Building..."
  PATH="$HOME/.moon/bin:$PATH" make build-native
  BINARY="_build/native/release/build/src/main/main.exe"
fi

AUTOAGENT_HOME="${AUTOAGENT_HOME:-.autoagent}"
WORKSPACE_DIR="$AUTOAGENT_HOME/workspace"
SESSIONS_DIR="$WORKSPACE_DIR/sessions"
MEMORY_DIR="$WORKSPACE_DIR/memory"
CONFIG_FILE="$AUTOAGENT_HOME/config.json"
MAX_STEPS="${AUTOAGENT_MAX_STEPS:-5}"
FIRST_RUN_FLAG="$AUTOAGENT_HOME/.initialized"

FIRST_RUN=false

init_workspace() {
  mkdir -p "$SESSIONS_DIR" "$MEMORY_DIR"
  if [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$AUTOAGENT_HOME"
    cat > "$CONFIG_FILE" <<'JSON'
{
  "provider": { "name": "deterministic", "api_key": "", "base_url": "", "model": "", "timeout_seconds": 30 },
  "agent": { "name": "AutoAgent", "system_prompt": "Help users build useful agents with initialization, interaction, memory, safe tools, and production checks.", "max_steps": 5, "max_goal_length": 2000, "max_tool_output_length": 2000 }
}
JSON
  fi
  [ ! -f "$MEMORY_DIR/user.md" ] && printf '# User Memory\n\nStable preferences.\n' > "$MEMORY_DIR/user.md"
  [ ! -f "$MEMORY_DIR/experiences.md" ] && printf '# Experience Memory\n\nValidated outcomes.\n' > "$MEMORY_DIR/experiences.md"
  if [ ! -f "$FIRST_RUN_FLAG" ]; then
    echo "initialized" > "$FIRST_RUN_FLAG"
    FIRST_RUN=true
  fi
}

show_welcome() {
  printf '\n'
  printf '  \033[1;36mAutoAgent\033[0m \033[2mv0.1.0\033[0m\n'
  printf '  \033[2mA lightweight MoonBit agent runtime\033[0m\n'
  printf '\n'
  printf '  Just type what you want. Examples:\n'
  printf '  \033[36m> build a chatbot for my website\033[0m\n'
  printf '  \033[36m> research the best database for my project\033[0m\n'
  printf '  \033[36m> write tests for my auth module\033[0m\n'
  printf '\n'
  printf '  Commands: \033[2m/skills /help /quit\033[0m\n'
  printf '\n'
}

show_help() {
  printf '\n'
  printf '  \033[1mCommands\033[0m\n'
  printf '  /skills        List available skills\n'
  printf '  /skill NAME    Show skill details\n'
  printf '  /history       Show session log\n'
  printf '  /memory        Show memory locations\n'
  printf '  /save TEXT     Save to experience memory\n'
  printf '  /clear         Clear screen\n'
  printf '  /quit          Exit\n'
  printf '\n'
  printf '  \033[2mEverything else is sent to the agent.\033[0m\n'
  printf '\n'
}

thinking() {
  printf '\033[33m  thinking...\033[0m\r'
}

done_msg() {
  printf '                      \r'
}

new_session_file() {
  echo "$SESSIONS_DIR/$(date +%Y%m%d-%H%M%S).md"
}

run_agent() {
  local session_file="$1"
  local input="$2"

  printf '\n'
  printf '  \033[1;36m>\033[0m %s\n' "$input"
  printf '\n'

  # Step 0: plan
  thinking
  local plan_output
  plan_output=$("$BINARY" --max-steps "$MAX_STEPS" --step 0 "$input" 2>&1) || true
  done_msg

  printf '%s\n' "$plan_output"
  printf '\n'

  # Save to session
  printf '## User\n%s\n\n' "$input" >> "$session_file"
  printf '## Assistant (step 0)\n%s\n\n' "$plan_output" >> "$session_file"

  # Multi-turn: ask to continue
  local step=1
  while [ "$step" -lt "$MAX_STEPS" ]; do
    printf '\033[2m  Continue? [Y/n]\033[0m '
    local cont=""
    IFS= read -r cont || break
    cont=$(printf '%s' "$cont" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Default to yes on empty input
    [ -z "$cont" ] && cont="y"

    case "$cont" in
      [yY]|[yY][eE][sS])
        thinking
        local step_output
        step_output=$("$BINARY" --max-steps "$MAX_STEPS" --step "$step" "$input" 2>&1) || true
        done_msg

        printf '\n%s\n' "$step_output"
        printf '\n'

        printf '## Assistant (step %d)\n%s\n\n' "$step" "$step_output" >> "$session_file"

        # Check if all steps done
        if echo "$step_output" | grep -q "All steps completed"; then
          break
        fi
        ;;
      [nN]|[nN][oO])
        printf '  \033[2mStopped at step %d.\033[0m\n' "$step"
        printf '## Assistant\nStopped at step %d.\n\n' "$step" >> "$session_file"
        break
      ;;
      *)
        printf '  \033[2mStopped.\033[0m\n'
        break
        ;;
    esac
    step=$((step + 1))
  done
}

chat_loop() {
  init_workspace

  local session_file
  session_file="$(new_session_file)"
  printf '# AutoAgent Session\n\n- Started: %s\n\n' "$(date -Iseconds)" > "$session_file"

  show_welcome

  if $FIRST_RUN; then
    printf '  \033[2mWorkspace initialized at %s\033[0m\n' "$AUTOAGENT_HOME"
    printf '  \033[2mSession log: %s\033[0m\n' "$session_file"
    printf '\n'
  fi

  while true; do
    printf '\033[1;35m>\033[0m '
    IFS= read -r input || break

    # Trim whitespace
    input=$(printf '%s' "$input" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "$input" ] && continue

    case "$input" in
      /help|/h)
        show_help
        ;;
      /skills)
        "$BINARY" --skills
        ;;
      /skill\ *)
        "$BINARY" --skill "${input#/skill }"
        ;;
      /history)
        if [ -f "$session_file" ]; then
          printf '\n\033[2m--- Session Log ---\033[0m\n'
          cat "$session_file"
          printf '\033[2m--- End ---\033[0m\n'
        fi
        ;;
      /memory)
        printf '\n  Memory files:\n'
        printf '  %s/user.md\n' "$MEMORY_DIR"
        printf '  %s/experiences.md\n' "$MEMORY_DIR"
        ;;
      /save\ *)
        printf '\n## Saved Experience\n%s\n' "${input#/save }" >> "$MEMORY_DIR/experiences.md"
        printf '  Saved to experiences.md\n'
        ;;
      /clear)
        clear
        show_welcome
        ;;
      /quit|/exit)
        printf '\n  Session saved: %s\n\n' "$session_file"
        break
        ;;
      /*)
        printf '  Unknown command. Type /help for commands.\n'
        ;;
      *)
        run_agent "$session_file" "$input"
        ;;
    esac
  done
}

# Entry
case "${1:-chat}" in
  init)
    init_workspace
    echo "Workspace initialized at $AUTOAGENT_HOME"
    ;;
  chat|repl|shell)
    chat_loop
    ;;
  run)
    shift
    init_workspace
    "$BINARY" "$@"
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    chat_loop
    ;;
esac
