#!/bin/bash
# AutoAgent - entry point
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

AUTOAGENT_HOME="${AUTOAGENT_HOME:-.autoagent}"

init_workspace() {
  mkdir -p "$AUTOAGENT_HOME/workspace/memory" "$AUTOAGENT_HOME/workspace/sessions"
  if [ ! -f "$AUTOAGENT_HOME/config.json" ]; then
    cat > "$AUTOAGENT_HOME/config.json" <<'JSON'
{
  "provider": {
    "name": "llm",
    "api_key": "",
    "base_url": "https://proxy.monkeycode-ai.com/v1",
    "model": "monkeycode-basic/qwen3.5-plus",
    "timeout_seconds": 30
  },
  "agent": {
    "name": "AutoAgent",
    "system_prompt": "You are AutoAgent, a helpful AI assistant.",
    "max_steps": 10,
    "max_goal_length": 4000,
    "max_tool_output_length": 4000
  }
}
JSON
  fi
}

case "${1:-chat}" in
  init)
    init_workspace
    echo "Workspace initialized at $AUTOAGENT_HOME"
    ;;
  chat|shell|repl|"")
    init_workspace
    exec python3 "$ROOT_DIR/scripts/agent.py" chat
    ;;
  run)
    shift
    init_workspace
    exec python3 "$ROOT_DIR/scripts/agent.py" run "$@"
    ;;
  tools)
    python3 "$ROOT_DIR/scripts/agent.py" tools
    ;;
  memory)
    python3 "$ROOT_DIR/scripts/agent.py" memory
    ;;
  help|--help|-h)
    echo "AutoAgent"
    echo ""
    echo "Usage:"
    echo "  autoagent.sh           Start interactive chat"
    echo "  autoagent.sh run <msg> Single-shot mode"
    echo "  autoagent.sh init      Initialize workspace"
    echo "  autoagent.sh tools     List tools"
    echo "  autoagent.sh memory    Show memory"
    ;;
  *)
    init_workspace
    exec python3 "$ROOT_DIR/scripts/agent.py" run "$@"
    ;;
esac
