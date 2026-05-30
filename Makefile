.PHONY: all build build-native build-wasm test check clean dist help run repl chat init

# Default target
all: check test build-native

# Version
VERSION := 1.0.0
BUILD_DIR := _build/dist-autoagent-$(VERSION)
BINARY_NAME := autoagent

# Native build paths
NATIVE_BUILD := _build/native/release/build/src/main
NATIVE_C := $(NATIVE_BUILD)/main.c
NATIVE_EXE := $(NATIVE_BUILD)/main.exe
IO_C := native/io.c
IO_O := _build/native/release/build/io.o
RUNTIME_O := _build/native/release/build/runtime.o

# Linker flags (no external dependencies for portability)
LDFLAGS := -lm

help:
	@echo "AutoAgent Build Targets:"
	@echo ""
	@echo "  make all           - Run check, tests, and build native binary"
	@echo "  make build         - Build wasm-gc (default target)"
	@echo "  make build-native  - Build native binary (with C I/O layer)"
	@echo "  make build-wasm    - Build wasm-gc binary"
	@echo "  make test          - Run all tests"
	@echo "  make check         - Run type checker"
	@echo "  make dist          - Create distribution package"
	@echo "  make clean         - Clean build artifacts"
	@echo "  make run           - Run with default goal"
	@echo "  make run ARGS=     - Run with custom args"
	@echo "  make chat          - Start interactive REPL"
	@echo "  make help          - Show this help"

check:
	PATH="$$HOME/.moon/bin:$$PATH" moon check

test:
	PATH="$$HOME/.moon/bin:$$PATH" moon test

build:
	PATH="$$HOME/.moon/bin:$$PATH" moon build

build-native:
	@mkdir -p _build/native/release/build
	PATH="$$HOME/.moon/bin:$$PATH" moon build --target native --release || true
	@echo "Compiling C I/O layer..."
	gcc -c -O2 -fwrapv -fno-strict-aliasing -I$$HOME/.moon/include $(IO_C) -o $(IO_O)
	@echo "Linking native binary..."
	gcc -o $(NATIVE_EXE) -I$$HOME/.moon/include -fwrapv -fno-strict-aliasing -O2 \
		$$HOME/.moon/lib/libmoonbitrun.o \
		$(NATIVE_C) \
		$(RUNTIME_O) \
		$$HOME/.moon/lib/moonbit_simdutf.o \
		$$HOME/.moon/lib/simdutf.o \
		$(IO_O) \
		$(LDFLAGS) \
		$$HOME/.moon/lib/libbacktrace.a
	@chmod +x $(NATIVE_EXE)
	@echo "Native binary: $(NATIVE_EXE)"

build-wasm:
	PATH="$$HOME/.moon/bin:$$PATH" moon build --target wasm-gc --release
	@echo "Wasm binary: _build/wasm-gc/release/build/src/main/main.wasm"

dist: build-native
	@echo "Creating distribution package..."
	@mkdir -p $(BUILD_DIR)/.autoagent
	@cp $(NATIVE_EXE) $(BUILD_DIR)/$(BINARY_NAME)
	@test -f .autoagent/config.json && cp .autoagent/config.json $(BUILD_DIR)/.autoagent/ || echo '{"provider":{"name":"deterministic","api_key":"","base_url":"","model":"","timeout_seconds":30},"agent":{"name":"AutoAgent","system_prompt":"Help users build lightweight agents from scratch and use agents well.","max_steps":3,"max_goal_length":1000,"max_tool_output_length":500}}' > $(BUILD_DIR)/.autoagent/config.json
	@cd $(BUILD_DIR) && chmod +x $(BINARY_NAME) && tar -czf ../autoagent-$(VERSION)-linux-x86_64.tar.gz $(BINARY_NAME) .autoagent/
	@echo ""
	@echo "Distribution: _build/autoagent-$(VERSION)-linux-x86_64.tar.gz"
	@echo "Contents:"
	@tar -tzf _build/autoagent-$(VERSION)-linux-x86_64.tar.gz

clean:
	@echo "Clean build artifacts manually if needed: _build"

run: build-native
	./$(NATIVE_EXE) $(ARGS)

run-wasm: build-wasm
	PATH="$$HOME/.moon/bin:$$PATH" moon run src/main $(ARGS)

chat: build-native
	@./$(NATIVE_EXE) chat

repl: chat

init:
	@mkdir -p .autoagent/workspace/sessions .autoagent/workspace/memory
	@test -f .autoagent/config.json || echo '{"provider":{"name":"llm","api_key":"","base_url":"https://proxy.monkeycode-ai.com/v1","model":"monkeycode-basic/qwen3.5-plus","timeout_seconds":60},"agent":{"name":"AutoAgent","system_prompt":"You are AutoAgent.","max_steps":10,"max_goal_length":4000,"max_tool_output_length":4000}}' > .autoagent/config.json
	@test -f .autoagent/workspace/memory.json || echo '[]' > .autoagent/workspace/memory.json
	@echo "Initialized .autoagent/workspace"
