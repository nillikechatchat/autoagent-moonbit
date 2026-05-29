#!/bin/bash
# AutoAgent Install Script
# Installs the AutoAgent native binary to /usr/local/bin

set -euo pipefail

VERSION="0.2.0"
BINARY_NAME="autoagent"
INSTALL_DIR="/usr/local/bin"
REPO_URL="https://github.com/nillikechatchat/autoagent-moonbit"

echo "Installing AutoAgent v${VERSION}..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Note: You may need to run with sudo for system-wide installation."
  echo "  sudo ./install.sh"
  echo ""
  echo "Installing to current directory instead..."
  INSTALL_DIR="."
fi

# Check for required dependencies
check_dep() {
  if ! command -v "$1" &>/dev/null; then
    echo "Error: $1 is required but not installed."
    echo "Please install $1 first."
    exit 1
  fi
}

check_dep gcc
check_dep curl

# Build if needed
if [ ! -f "_build/native/release/build/src/main/main.exe" ]; then
  echo "Building native binary..."
  if command -v moon &>/dev/null; then
    make build-native
  else
    echo "Error: MoonBit toolchain not found."
    echo "Install with: curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash"
    exit 1
  fi
fi

# Install binary
echo "Installing binary to ${INSTALL_DIR}/${BINARY_NAME}..."
cp _build/native/release/build/src/main/main.exe "${INSTALL_DIR}/${BINARY_NAME}"
chmod +x "${INSTALL_DIR}/${BINARY_NAME}"

# Verify installation
if "${INSTALL_DIR}/${BINARY_NAME}" --version &>/dev/null; then
  echo ""
  echo "AutoAgent v${VERSION} installed successfully!"
  echo ""
  echo "Usage:"
  echo "  ${BINARY_NAME} chat          Start interactive REPL"
  echo "  ${BINARY_NAME} run <goal>    Run single-shot agent"
  echo "  ${BINARY_NAME} --help        Show help"
  echo ""
  echo "Configuration:"
  echo "  export MCAI_LLM_API_KEY='your-key'"
  echo "  export MCAI_LLM_BASE_URL='https://proxy.monkeycode-ai.com/v1'"
  echo "  export MCAI_LLM_MODEL='monkeycode-basic/qwen3.5-plus'"
  echo ""
  echo "Or edit .autoagent/config.json with your provider settings."
else
  echo "Error: Installation verification failed."
  exit 1
fi
