# AutoAgent 使用手册

## 目录

- [快速开始](#快速开始)
- [CLI 用法](#cli-用法)
- [配置文件](#配置文件)
- [技能系统](#技能系统)
- [工具系统](#工具系统)
- [REPL 命令](#repl-命令)
- [安全模型](#安全模型)
- [测试指南](#测试指南)
- [故障排查](#故障排查)

---

## 快速开始

### 环境要求

- MoonBit 工具链：`moonc v0.9.3+`、`moon 0.1.20260522+`
- GCC（用于编译 C I/O 层）
- libcurl（用于 HTTP 请求）

### 安装

```bash
# Install MoonBit toolchain on Linux or macOS
curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash

# Verify installation
PATH="$HOME/.moon/bin:$PATH" moon version
```

### 构建和运行

```bash
# Type check
make check

# Run tests (89 tests)
make test

# Build native binary (with C I/O layer)
make build-native

# Initialize workspace
make init

# Start interactive REPL
make chat

# Single-shot mode
./_build/native/release/build/src/main/main.exe run "build a chatbot"
```

---

## CLI 用法

### 命令格式

```bash
./_build/native/release/build/src/main/main.exe [OPTIONS] [GOAL]
```

### 参数

| 参数 | 说明 |
|------|------|
| `[GOAL]` | Agent 要完成的目标 |
| `chat` | 启动交互式 REPL |
| `run <goal>` | 单次运行模式 |
| `--help, -h` | 显示帮助信息 |
| `--version, -v` | 显示版本信息 |
| `--config` | 显示当前配置 |
| `--skills` | 列出可用工具 |

### 示例

```bash
# 初始化工作区
make init

# 启动交互式会话
make chat

# 显示帮助
./_build/native/release/build/src/main/main.exe --help

# 显示版本
./_build/native/release/build/src/main/main.exe --version

# 显示当前配置
./_build/native/release/build/src/main/main.exe --config

# 运行自定义目标
./_build/native/release/build/src/main/main.exe run "build a chatbot for my website"
```

---

## 配置文件

### 配置目录

配置文件位于项目根目录的 `.autoagent/config.json`。

### 配置结构

```json
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
    "system_prompt": "You are AutoAgent.",
    "max_steps": 10,
    "max_goal_length": 4000,
    "max_tool_output_length": 4000
  }
}
```

### 环境变量

| 变量 | 说明 |
|------|------|
| `MCAI_LLM_API_KEY` | LLM API 密钥 |
| `MCAI_LLM_BASE_URL` | LLM API 基础 URL |
| `MCAI_LLM_MODEL` | 模型名称 |

环境变量优先级高于配置文件。

---

## 技能系统

AutoAgent 支持 7 个内置技能，提供 14 个专用工具：

| 技能 | 工具 | 说明 |
|------|------|------|
| research | research-search, research-summarize | 信息搜索与综合 |
| code-review | review-analyze, review-suggest | 代码质量分析 |
| docs | docs-generate, docs-explain | 文档生成与解释 |
| testing | test-create, test-coverage | 测试计划与覆盖率 |
| code-gen | codegen-implement, codegen-scaffold | TDD 代码生成 |
| debug | debug-diagnose, debug-fix | 5 步调试法 |
| refactor | refactor-extract, refactor-simplify | 安全重构 |

技能根据 goal 关键词自动选择。

---

## 工具系统

| 工具 | 说明 | 输入格式 |
|------|------|---------|
| read_file | 读取项目内文件 | 文件路径 |
| write_file | 写入项目内文件 | `{"path":"...","content":"..."}` |
| list_files | 列出项目内目录 | 目录路径 |
| run_command | 执行本地命令 | Shell 命令 |
| search_web | DuckDuckGo 搜索 | 搜索查询 |

### 安全策略

- 文件路径限制在项目目录内
- `run_command` 拒绝危险操作（rm, sudo, git clean 等）
- 默认只执行 `RiskLevel.Low` 工具

---

## REPL 命令

| 命令 | 说明 |
|------|------|
| `/help` | 显示帮助信息 |
| `/clear` | 清空对话记忆 |
| `/history` | 显示会话历史 |
| `/skills` | 列出可用工具和技能 |
| `/config` | 显示当前配置 |
| `/status` | 显示会话状态 |
| `/quit` | 退出 |

---

## 安全模型

- MoonBit core 默认只执行 `RiskLevel.Low` 工具
- 文件路径限制在项目目录内
- `run_command` 拒绝删除、提权、系统管理和高风险命令
- 默认测试和 deterministic provider 不依赖真实网络或 LLM

---

## 测试指南

### 运行测试

```bash
# Run all tests
make test

# Run type checker
make check

# Run full quality gate
make all
```

### 测试策略

遵循 Codex 原则：**集成测试优先于单元测试**。

- 单元测试：验证单个函数的正确性
- 集成测试：验证技能注册表、工具链、LLM 解析、响应动作检测
- Eval 系统：验证 agent 行为的端到端正确性

### 添加测试

在 `src/autoagent/agent_test.mbt` 中添加测试：

```moonbit
///|
test "my new test" {
  let result = my_function("input")
  assert_eq(result, "expected")
}
```

---

## 故障排查

### 构建失败

```bash
# Clean and rebuild
make clean
make all
```

### 测试失败

```bash
# Run tests with verbose output
PATH="$HOME/.moon/bin:$PATH" moon test 2>&1
```

### LLM 不响应

1. 检查 API key 是否配置：`./_build/native/release/build/src/main/main.exe --config`
2. 检查网络连接
3. 检查 `.autoagent/config.json` 配置

### 工具执行失败

1. 检查文件路径是否在项目目录内
2. 检查命令是否被安全策略拒绝
3. 检查文件权限
