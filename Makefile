.PHONY: all build build-native build-wasm test check clean dist help run repl chat init

# Default target
all: check test build-native

# Version
VERSION := 0.1.0
BUILD_DIR := _build/dist
BINARY_NAME := autoagent

help:
	@echo "AutoAgent Build Targets:"
	@echo ""
	@echo "  make all           - Run check, tests, and build native binary"
	@echo "  make build         - Build wasm-gc (default target)"
	@echo "  make build-native  - Build native binary"
	@echo "  make build-wasm    - Build wasm-gc binary"
	@echo "  make test          - Run all tests"
	@echo "  make check         - Run type checker"
	@echo "  make dist          - Create distribution package"
	@echo "  make init          - Initialize AutoAgent workspace"
	@echo "  make chat          - Start interactive AutoAgent session"
	@echo "  make clean         - Clean build artifacts"
	@echo "  make run           - Run with default goal"
	@echo "  make run ARGS=     - Run with custom args"
	@echo "  make help          - Show this help"

check:
	PATH="$$HOME/.moon/bin:$$PATH" moon check

test:
	PATH="$$HOME/.moon/bin:$$PATH" moon test

build:
	PATH="$$HOME/.moon/bin:$$PATH" moon build

build-native:
	PATH="$$HOME/.moon/bin:$$PATH" moon build --target native --release
	@echo "Native binary: _build/native/release/build/src/main/main.exe"

build-wasm:
	PATH="$$HOME/.moon/bin:$$PATH" moon build --target wasm-gc --release
	@echo "Wasm binary: _build/wasm-gc/release/build/src/main/main.wasm"

dist: build-native
	@echo "Creating distribution package..."
	@rm -rf $(BUILD_DIR)
	@mkdir -p $(BUILD_DIR)/.autoagent
	@cp _build/native/release/build/src/main/main.exe $(BUILD_DIR)/$(BINARY_NAME)
	@test -f .autoagent/config.json && cp .autoagent/config.json $(BUILD_DIR)/.autoagent/ || echo '{"provider":{"name":"deterministic","api_key":"","base_url":"","model":"","timeout_seconds":30},"agent":{"name":"AutoAgent","system_prompt":"Help users build lightweight agents from scratch and use agents well.","max_steps":3,"max_goal_length":1000,"max_tool_output_length":500}}' > $(BUILD_DIR)/.autoagent/config.json
	@cd $(BUILD_DIR) && chmod +x $(BINARY_NAME) && tar -czf ../autoagent-$(VERSION)-linux-x86_64.tar.gz $(BINARY_NAME) .autoagent/
	@echo ""
	@echo "Distribution: _build/autoagent-$(VERSION)-linux-x86_64.tar.gz"
	@echo "Contents:"
	@tar -tzf _build/autoagent-$(VERSION)-linux-x86_64.tar.gz

clean:
	rm -rf _build

run: build-native
	./_build/native/release/build/src/main/main.exe $(ARGS)

run-wasm: build-wasm
	PATH="$$HOME/.moon/bin:$$PATH" moon run src/main $(ARGS)

repl: build-native
	@chmod +x scripts/autoagent.sh scripts/repl.sh
	@./scripts/autoagent.sh chat

chat: repl

init: build-native
	@chmod +x scripts/autoagent.sh
	@./scripts/autoagent.sh init
