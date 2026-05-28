#!/bin/bash
# AutoAgent - real LLM agent shell
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

AGENT_PY="$ROOT_DIR/scripts/agent.py"
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
    "timeout_seconds": 60
  },
  "agent": {
    "name": "AutoAgent",
    "system_prompt": "You are AutoAgent, a helpful AI assistant. Create actual files with working code when asked.",
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
    python3 "$AGENT_PY" chat
    ;;
  run)
    shift
    init_workspace
    python3 "$AGENT_PY" run "$@"
    ;;
  tools)
    python3 "$AGENT_PY" tools
    ;;
  memory)
    python3 "$AGENT_PY" memory
    ;;
  help|--help|-h)
    echo "AutoAgent - real LLM agent"
    echo ""
    echo "Usage:"
    echo "  autoagent.sh              Start interactive chat"
    echo "  autoagent.sh chat         Start interactive chat"
    echo "  autoagent.sh run <msg>    Single-shot mode"
    echo "  autoagent.sh init         Initialize workspace"
    echo "  autoagent.sh tools        List tools"
    echo "  autoagent.sh memory       Show memory status"
    ;;
  *)
    init_workspace
    python3 "$AGENT_PY" run "$@"
    ;;
esac
