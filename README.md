# AutoAgent

AutoAgent 是一个纯 MoonBit 实现的轻量 Agent CLI/runtime。MoonBit 负责所有逻辑（规划、对话、工具选择、JSON 解析、记忆管理、REPL）；C FFI 仅负责 I/O 原语（HTTP、文件、进程、环境变量）。

## 架构

```
用户输入 → MoonBit REPL → MoonBit 规划 → MoonBit 调 LLM API (C FFI HTTP)
         → MoonBit 解析响应 → MoonBit 执行工具 (C FFI 文件/进程)
         → MoonBit 记忆持久化 (C FFI 文件) → 循环直到完成
```

**单一二进制，无外部依赖：** `_build/native/release/build/src/main/main.exe`

## 快速开始

```bash
# 类型检查
make check

# 运行测试 (89 tests)
make test

# 构建原生二进制 (含 C I/O 层)
make build-native

# 初始化工作区
make init

# 启动交互式 REPL
make chat

# 单次运行
./_build/native/release/build/src/main/main.exe run "build a chatbot"
```

## LLM 配置

```bash
export MCAI_LLM_API_KEY="your-key"
export MCAI_LLM_BASE_URL="https://proxy.monkeycode-ai.com/v1"
export MCAI_LLM_MODEL="monkeycode-basic/qwen3.5-plus"
```

或编辑 `.autoagent/config.json`。无 API key 时使用 deterministic fallback。

## 技能系统 (7 Skills, 14 Tools)

| 技能 | 工具 | 用途 |
|------|------|------|
| research | research-search, research-summarize | 信息搜索与综合 |
| code-review | review-analyze, review-suggest | 代码质量分析 |
| docs | docs-generate, docs-explain | 文档生成与解释 |
| testing | test-create, test-coverage | 测试计划与覆盖率 |
| code-gen | codegen-implement, codegen-scaffold | TDD 代码生成 |
| debug | debug-diagnose, debug-fix | 5 步调试法 |
| refactor | refactor-extract, refactor-simplify | 安全重构 |

## 工具

| 工具 | 说明 |
|------|------|
| read_file | 读取项目内文件 |
| write_file | 写入项目内文件 (JSON input) |
| list_files | 列出项目内目录 |
| run_command | 执行本地命令 (带安全拒绝列表) |
| search_web | DuckDuckGo 搜索 |

## 项目结构

```
.
├── Makefile                    # 构建系统 (含 C 编译链接)
├── native/
│   └── io.c                    # C I/O 层 (HTTP/文件/进程/环境变量)
├── src/
│   ├── autoagent/
│   │   ├── io_native.mbt       # MoonBit FFI 声明 (#borrow 注解)
│   │   ├── io_stub.mbt         # wasm-gc/js 的 no-op stub
│   │   ├── llm_provider.mbt    # LLM API 客户端
│   │   ├── tools.mbt           # 工具执行 + 安全策略
│   │   ├── repl.mbt            # REPL + Agent Loop + 记忆持久化
│   │   ├── skill.mbt           # 7 技能 / 14 工具
│   │   ├── eval.mbt            # 质量评估系统
│   │   ├── agent.mbt           # Agent 核心
│   │   ├── planner.mbt         # 规划器
│   │   ├── memory.mbt          # 记忆管理
│   │   └── terminal.mbt        # ANSI 终端格式化
│   └── main/
│       └── main.mbt            # CLI 入口
└── .monkeycode/docs/           # 项目文档
```

## 质量门

```bash
make all    # check + test + build-native
```

当前状态：
- `moon check`：0 errors
- `moon test`：89 passed, 0 failed
- `make build-native`：成功生成原生二进制

## 测试策略

遵循 Codex 原则：**集成测试优先于单元测试**。

- 单元测试：验证单个函数的正确性
- 集成测试：验证技能注册表、工具链、LLM 解析、响应动作检测
- Eval 系统：验证 agent 行为的端到端正确性

## 安全基线

- MoonBit core 默认只执行 `RiskLevel.Low` 工具
- Shell I/O 层限制文件路径在项目目录内
- `run_command` 拒绝删除、提权、系统管理和高风险命令
- 默认测试和 deterministic provider 不依赖真实网络或 LLM

## 参考

- Claude Code：REPL 交互模式、工具执行显示
- Hermes：自进化记忆、分层记忆架构
- Pi：极简工具集、扩展系统
- Google agents-cli：7 技能包模式
- Codex：集成测试优先、Snapshot 测试
- Superpowers：TDD 强制流程
