#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/autoagent.sh" chat "$@"

# AutoAgent Interactive REPL - Beginner Friendly
# Usage: ./scripts/repl.sh [OPTIONS]

set -e

BINARY=""
if [ -f "_build/native/release/build/src/main/main.exe" ]; then
  BINARY="_build/native/release/build/src/main/main.exe"
elif [ -f "_build/dist/autoagent" ]; then
  BINARY="_build/dist/autoagent"
else
  echo "Binary not found. Run 'make build-native' first."
  exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Banner
echo ""
echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}  ║${RESET}      ${BOLD}AutoAgent v0.1.0 REPL${RESET}            ${BOLD}${CYAN}║${RESET}"
echo -e "${BOLD}${CYAN}  ║${RESET}  ${DIM}A lightweight MoonBit Agent${RESET}         ${BOLD}${CYAN}║${RESET}"
echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════╝${RESET}"
echo ""
echo -e "${DIM}  Welcome! Type your goal and press Enter.${RESET}"
echo ""
echo -e "${DIM}  Quick Start:${RESET}"
echo -e "${DIM}    1. Type what you want to build${RESET}"
echo -e "${DIM}    2. Press Enter to get a plan${RESET}"
echo -e "${DIM}    3. Follow the step-by-step guidance${RESET}"
echo ""
echo -e "${DIM}  Commands:${RESET}"
echo -e "${DIM}    /help       - Show detailed help${RESET}"
echo -e "${DIM}    /tutorial   - Interactive tutorial${RESET}"
echo -e "${DIM}    /examples   - Browse example goals${RESET}"
echo -e "${DIM}    /beginner   - Beginner's guide${RESET}"
echo -e "${DIM}    /config     - Show configuration${RESET}"
echo -e "${DIM}    /history    - Show session history${RESET}"
echo -e "${DIM}    /clear      - Clear screen${RESET}"
echo -e "${DIM}    /quit       - Exit${RESET}"
echo -e "${DIM}    /run <N>    - Set max-steps to N${RESET}"
echo ""

HISTORY_FILE="/tmp/autoagent_history_$$"
touch "$HISTORY_FILE"
MAX_STEPS=""
TUTORIAL_STEP=0

cleanup() {
  rm -f "$HISTORY_FILE"
  echo ""
  echo -e "${DIM}Thank you for using AutoAgent! Goodbye!${RESET}"
  exit 0
}

trap cleanup INT TERM

show_tutorial() {
  echo ""
  echo -e "${BOLD}${CYAN}=== AutoAgent Tutorial ===${RESET}"
  echo ""
  echo -e "${BOLD}Step 1: What is AutoAgent?${RESET}"
  echo -e "  AutoAgent is a lightweight Agent runtime that helps you"
  echo -e "  build and use AI agents. It takes a 'goal' and creates"
  echo -e "  a plan to achieve it."
  echo ""
  echo -e "${BOLD}Step 2: How does it work?${RESET}"
  echo -e "  1. You provide a goal (e.g., 'build a chatbot')"
  echo -e "  2. AutoAgent creates a plan with steps"
  echo -e "  3. Each step uses a tool to generate guidance"
  echo -e "  4. You get a complete action plan"
  echo ""
  echo -e "${BOLD}Step 3: Try your first goal!${RESET}"
  echo -e "  Type something like:"
  echo -e "    ${CYAN}build a todo list app${RESET}"
  echo -e "    ${CYAN}create a blog with comments${RESET}"
  echo -e "    ${CYAN}design a user authentication system${RESET}"
  echo ""
  echo -e "${BOLD}Step 4: Understanding the output${RESET}"
  echo -e "  - ${GREEN}Goal${RESET}: What you asked for"
  echo -e "  - ${GREEN}State${RESET}: Whether it completed successfully"
  echo -e "  - ${GREEN}Steps${RESET}: The tools that were used"
  echo -e "  - Each step gives you actionable advice"
  echo ""
  echo -e "${BOLD}Step 5: Customize your experience${RESET}"
  echo -e "  - /config    - See current settings"
  echo -e "  - /examples  - Browse example goals"
  echo -e "  - /run <N>   - Set max steps (try /run 5)"
  echo ""
  echo -e "${BOLD}Ready to start? Type your first goal below!${RESET}"
  echo ""
}

show_examples() {
  echo ""
  echo -e "${BOLD}${CYAN}=== Example Goals ===${RESET}"
  echo ""
  echo -e "${DIM}Try these examples to get started:${RESET}"
  echo ""
  echo -e "  ${CYAN}1.${RESET} ${BOLD}Create a Chatbot${RESET} ${GREEN}[beginner]${RESET}"
  echo -e "     Build a chatbot that answers FAQ about my product"
  echo ""
  echo -e "  ${CYAN}2.${RESET} ${BOLD}Build a Research Assistant${RESET} ${GREEN}[beginner]${RESET}"
  echo -e "     Create a research assistant that can plan and teach"
  echo ""
  echo -e "  ${CYAN}3.${RESET} ${BOLD}Design a REST API${RESET} ${YELLOW}[intermediate]${RESET}"
  echo -e "     Design a REST API for a todo list application"
  echo ""
  echo -e "  ${CYAN}4.${RESET} ${BOLD}Plan a Database Migration${RESET} ${RED}[advanced]${RESET}"
  echo -e "     Plan a migration from MySQL to PostgreSQL"
  echo ""
  echo -e "  ${CYAN}5.${RESET} ${BOLD}Create a CLI Tool${RESET} ${YELLOW}[intermediate]${RESET}"
  echo -e "     Build a command-line tool for CSV processing"
  echo ""
  echo -e "  ${CYAN}6.${RESET} ${BOLD}Write Unit Tests${RESET} ${YELLOW}[intermediate]${RESET}"
  echo -e "     Write comprehensive unit tests for auth module"
  echo ""
  echo -e "  ${CYAN}7.${RESET} ${BOLD}Set Up CI/CD${RESET} ${YELLOW}[intermediate]${RESET}"
  echo -e "     Set up CI/CD pipeline with GitHub Actions"
  echo ""
  echo -e "  ${CYAN}8.${RESET} ${BOLD}Create Documentation${RESET} ${GREEN}[beginner]${RESET}"
  echo -e "     Write comprehensive API documentation"
  echo ""
  echo -e "${DIM}Just type the goal to try it!${RESET}"
  echo ""
}

show_beginner_guide() {
  echo ""
  echo -e "${BOLD}${CYAN}=== Beginner's Guide ===${RESET}"
  echo ""
  echo -e "${BOLD}What is a goal?${RESET}"
  echo -e "  A goal is what you want to accomplish. Be specific!"
  echo ""
  echo -e "${BOLD}Good goals:${RESET}"
  echo -e "  ${GREEN}✓${RESET} 'build a chatbot for customer support'"
  echo -e "  ${GREEN}✓${RESET} 'create a REST API for a todo app'"
  echo -e "  ${GREEN}✓${RESET} 'write unit tests for the auth module'"
  echo ""
  echo -e "${BOLD}Less effective goals:${RESET}"
  echo -e "  ${RED}✗${RESET} 'help' (too vague)"
  echo -e "  ${RED}✗${RESET} 'fix my code' (no specifics)"
  echo -e "  ${RED}✗${RESET} 'do something' (unclear intent)"
  echo ""
  echo -e "${BOLD}Tips for better results:${RESET}"
  echo -e "  1. Be specific about what you want"
  echo -e "  2. Include the technology or framework"
  echo -e "  3. Mention constraints or requirements"
  echo -e "  4. Use action verbs: build, create, design, write"
  echo ""
  echo -e "${BOLD}Try these commands:${RESET}"
  echo -e "  /tutorial   - Interactive walkthrough"
  echo -e "  /examples   - Browse example goals"
  echo -e "  /beginner   - Show this guide"
  echo ""
}

suggest_improvement() {
  local input="$1"
  local suggestions=""

  if [ ${#input} -lt 5 ]; then
    suggestions="${suggestions}\n  ${BLUE}ℹ${RESET} Your goal is very short. Try being more specific."
  fi

  if [[ "$input" == how\ to* ]] || [[ "$input" == how\ do* ]]; then
    suggestions="${suggestions}\n  ${BLUE}ℹ${RESET} Consider rephrasing: 'build a ...' or 'create a ...'"
  fi

  if [[ "$input" == *fix* ]] || [[ "$input" == *bug* ]] || [[ "$input" == *error* ]]; then
    suggestions="${suggestions}\n  ${BLUE}ℹ${RESET} For debugging: 'debug and fix [issue description]'"
  fi

  if [ -n "$suggestions" ]; then
    echo -e "\n${BOLD}${CYAN}💡 Suggestions${RESET}"
    echo -e "$suggestions"
    echo ""
  fi
}

while true; do
  echo -en "${BOLD}${MAGENTA}❯ ${RESET}"
  read -r input || break

  # Skip empty input
  if [ -z "$input" ]; then
    continue
  fi

  # Handle commands
  if [[ "$input" == /* ]]; then
    case "$input" in
      /help|/h)
        echo ""
        echo -e "${BOLD}${CYAN}=== Commands ===${RESET}"
        echo ""
        echo -e "  ${BOLD}/help${RESET}       - Show this help"
        echo -e "  ${BOLD}/tutorial${RESET}   - Interactive tutorial"
        echo -e "  ${BOLD}/examples${RESET}   - Browse example goals"
        echo -e "  ${BOLD}/beginner${RESET}   - Beginner's guide"
        echo -e "  ${BOLD}/config${RESET}     - Show configuration"
        echo -e "  ${BOLD}/history${RESET}    - Show session history"
        echo -e "  ${BOLD}/clear${RESET}      - Clear screen"
        echo -e "  ${BOLD}/quit${RESET}       - Exit"
        echo -e "  ${BOLD}/run <N>${RESET}    - Set max-steps to N"
        echo ""
        echo -e "${DIM}  Just type your goal to get started!${RESET}"
        echo ""
        ;;
      /tutorial|/t)
        show_tutorial
        ;;
      /examples|/e)
        show_examples
        ;;
      /beginner|/b)
        show_beginner_guide
        ;;
      /config|/c)
        $BINARY --config
        ;;
      /history)
        if [ -s "$HISTORY_FILE" ]; then
          echo ""
          echo -e "${BOLD}${CYAN}=== Session History ===${RESET}"
          nl -ba "$HISTORY_FILE" | while read -r line; do
            echo -e "  ${DIM}${line}${RESET}"
          done
          echo ""
        else
          echo -e "${DIM}No session history yet. Try typing a goal!${RESET}"
        fi
        ;;
      /clear)
        clear
        ;;
      /quit|/q)
        cleanup
        ;;
      /run\ *)
        steps="${input#/run }"
        if [[ "$steps" =~ ^[0-9]+$ ]]; then
          MAX_STEPS="$steps"
          echo -e "${BLUE}ℹ ${RESET}Max-steps set to ${BOLD}${MAX_STEPS}${RESET}"
        else
          echo -e "${RED}✗ ${RESET}Invalid number: ${steps}"
        fi
        ;;
      *)
        echo -e "${YELLOW}⚠ ${RESET}Unknown command: ${input}"
        echo -e "${DIM}  Type /help for available commands${RESET}"
        ;;
    esac
    continue
  fi

  # Show suggestions for short or unclear input
  suggest_improvement "$input"

  # Run agent
  echo "$input" >> "$HISTORY_FILE"
  echo ""
  echo -e "${YELLOW}⟳ ${RESET}Thinking about: ${BOLD}${input}${RESET}"
  echo -e "${DIM}  (This may take a moment...)${RESET}"
  echo ""

  if [ -n "$MAX_STEPS" ]; then
    $BINARY --max-steps "$MAX_STEPS" "$input"
  else
    $BINARY "$input"
  fi

  echo ""
  echo -e "${DIM}  Tip: Try /examples for more ideas, or /tutorial for a walkthrough${RESET}"
  echo ""
done

cleanup
