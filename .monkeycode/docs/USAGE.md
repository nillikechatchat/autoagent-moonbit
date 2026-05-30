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

# Run tests (282 tests)
make test

# Build native binary (with C I/O layer)
make build-native

# Initialize workspace
make init

# Start interactive REPL (default, Hermes-style)
./_build/native/release/build/src/main/main.exe

# Or use make shortcut
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
| (无参数) | 启动交互式 REPL (默认，像 Hermes 一样) |
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

AutoAgent 支持 10 个内置技能，提供 20 个专用工具：

| 技能 | 工具 | 说明 |
|------|------|------|
| research | research-search, research-summarize | 信息搜索与综合 |
| code-review | review-analyze, review-suggest | 代码质量分析 |
| docs | docs-generate, docs-explain | 文档生成与解释 |
| testing | test-create, test-coverage | 测试计划与覆盖率 |
| code-gen | codegen-implement, codegen-scaffold | TDD 代码生成 |
| debug | debug-diagnose, debug-fix | 5 步调试法 |
| refactor | refactor-extract, refactor-simplify | 安全重构 |
| security | security-scan, security-fix | 安全审查与修复 |
| performance | perf-analyze, perf-optimize | 性能分析与优化 |
| architecture | arch-design, arch-review | 架构设计与评审 |

技能根据 goal 关键词自动选择。

### 员工角色说明

- `research`：调研员，整理来源、事实、风险和下一步建议。
- `code-review`：代码审查员，从正确性、可读性、设计、安全和性能维度审查。
- `docs`：文档工程师，生成结构化文档草稿和概念解释。
- `testing`：测试工程师，输出测试计划、覆盖率缺口和下一条高价值测试。
- `code-gen`：实现工程师，按 TDD 顺序拆解实现和脚手架。
- `debug`：排障工程师，按复现、隔离、根因、修复、预防流程定位问题。
- `refactor`：重构工程师，执行小步、可验证、行为保持的代码改善。
- `security`：安全工程师，检查常见漏洞并给出修复策略。
- `performance`：性能工程师，定位瓶颈、建立测量基线并提出优化方案。
- `architecture`：架构师，拆分组件、定义接口、评审边界和权衡。

### 功能完整性与边界

当前 CLI/runtime 已覆盖完整交互链路：配置加载、LLM 调用、流式输出、工具调用解析、runtime tools、会话持久化、记忆恢复、skill 注册、Eval 和测试。`io_stub.mbt` 是非 native target 的测试替身，native 运行时通过 C FFI 执行真实 I/O。

当前增强方向包括结构化 tool schema、人工批准、dry-run 审计、跨平台发布矩阵和更细粒度的权限策略。真实 LLM 能力依赖 API key、base URL 和网络环境。

---

## 工具系统 (83 Runtime Tools)

| 工具 | 说明 | 输入格式 |
|------|------|---------|
| read_file | 读取项目内文件 | 文件路径 |
| write_file | 写入项目内文件 | `{"path":"...","content":"..."}` |
| edit_file | 局部 find/replace 编辑 | `{"path":"...","old":"...","new":"..."}` |
| list_files | 列出项目内目录 | 目录路径 |
| run_command | 执行本地命令 | Shell 命令 |
| search_web | DuckDuckGo 搜索 | 搜索查询 |
| find_files | 按名称模式查找文件 | glob/name pattern |
| code_search | 按内容搜索代码 | `{"pattern":"...","path":"..."}` |
| git_status | 查看工作区状态 | 空字符串 |
| git_diff | 查看 diff 统计 | 文件路径或空字符串 |
| memory_write | 写入 agent 记忆 | `{"key":"...","value":"..."}` |
| memory_read | 读取 agent 记忆 | 空字符串 |
| env_info | 查看环境信息 | 空字符串 |
| project_info | 查看项目摘要 | 空字符串 |
| http_get | HTTP GET 请求 | URL |
| file_info | 获取文件元数据 | 文件路径 |
| timestamp | 获取当前时间戳 | 空字符串 |
| env_get | 获取环境变量 | 变量名 |
| string_replace | 字符串替换 | `{"text":"...","old":"...","new":"..."}` |
| uuid_generate | 生成 UUID | 空字符串 |
| get_cwd | 获取当前工作目录 | 空字符串 |
| head_file | 读取文件前 N 行 | `{"path":"...","lines":10}` |
| tail_file | 读取文件后 N 行 | `{"path":"...","lines":10}` |
| count_lines | 统计文件行数 | 文件路径 |
| grep_file | 在文件中搜索模式 | `{"path":"...","pattern":"..."}` |
| diff_files | 比较两个文件 | `{"file1":"...","file2":"..."}` |
| copy_file | 复制文件 | `{"source":"...","destination":"..."}` |
| move_file | 移动/重命名文件 | `{"source":"...","destination":"..."}` |
| append_file | 追加到文件 | `{"path":"...","content":"..."}` |
| dir_size | 获取目录大小 | 目录路径 |
| disk_usage | 获取磁盘使用情况 | 空字符串 |
| sort_file | 排序文件行 | `{"path":"...","reverse":false}` |
| uniq_file | 去除重复行 | 文件路径 |
| wc_file | 统计字数 | 文件路径 |
| basename | 获取文件名 | 文件路径 |
| dirname | 获取目录名 | 文件路径 |
| realpath | 获取绝对路径 | 文件路径 |
| which | 查找命令位置 | 命令名 |
| date | 获取当前日期/时间 | 格式字符串或空字符串 |
| mkdir | 创建目录 | 目录路径 |
| is_dir | 检查是否为目录 | 文件路径 |
| truncate_file | 截断文件到 N 行 | `{"path":"...","lines":100}` |
| grep_count | 统计模式匹配次数 | `{"path":"...","pattern":"..."}` |
| grep_context | 获取匹配上下文 | `{"path":"...","pattern":"...","context":2}` |
| file_type | 获取文件类型 | 文件路径 |
| file_permissions | 获取文件权限 | 文件路径 |
| file_owner | 获取文件所有者 | 文件路径 |
| file_modified | 获取文件修改时间 | 文件路径 |
| file_size | 获取文件大小 | 文件路径 |
| list_dir_detailed | 详细列出目录 | 目录路径 |
| find_by_type | 按类型查找文件 | `{"path":"...","type":"f"}` |
| find_by_size | 按大小查找文件 | `{"path":"...","size":"+1M"}` |
| grep_recursive | 递归搜索 | `{"path":"...","pattern":"...","include":"*.mbt"}` |
| find_by_name | 按名称查找文件 | `{"path":"...","name":"*.mbt"}` |
| find_by_time | 按修改时间查找文件 | `{"path":"...","days":7}` |
| file_checksum | 获取文件校验和 | `{"path":"...","algorithm":"md5"}` |
| compress_file | 压缩文件 | 文件路径 |
| decompress_file | 解压文件 | 文件路径 |
| tar_create | 创建 tar 归档 | `{"source":"...","destination":"..."}` |
| tar_extract | 解压 tar 归档 | `{"source":"...","destination":"..."}` |
| zip_create | 创建 zip 归档 | `{"source":"...","destination":"..."}` |
| zip_extract | 解压 zip 归档 | `{"source":"...","destination":"..."}` |
| is_readable | 检查文件是否可读 | 文件路径 |
| is_writable | 检查文件是否可写 | 文件路径 |
| is_executable | 检查文件是否可执行 | 文件路径 |
| file_extension | 获取文件扩展名 | 文件路径 |
| file_lines | 获取文件行数 | 文件路径 |
| file_words | 获取文件字数 | 文件路径 |
| file_chars | 获取文件字符数 | 文件路径 |
| system_info | 获取系统信息 | 空字符串 |
| memory_info | 获取内存信息 | 空字符串 |
| cpu_info | 获取 CPU 信息 | 空字符串 |
| network_info | 获取网络信息 | 空字符串 |
| process_list | 获取进程列表 | 空字符串或进程名 |
| env_list | 获取环境变量列表 | 空字符串 |
| uptime | 获取系统运行时间 | 空字符串 |
| hostname | 获取系统主机名 | 空字符串 |
| whoami | 获取当前用户 | 空字符串 |
| who | 获取已登录用户 | 空字符串 |
| last | 获取最近登录记录 | 空字符串或用户名 |
| command_exists | 检查命令是否存在 | 命令名 |
| shell_info | 获取 shell 信息 | 空字符串 |
| path_list | 获取 PATH 目录列表 | 空字符串 |

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
| `/skill <name>` | 显示技能详情 |
| `/tools` | 显示详细工具描述 |
| `/config` | 显示当前配置 |
| `/status` | 显示会话状态 |
| `/stats` | 显示会话统计信息 |
| `/resume` | 恢复最近会话 |
| `/export` | 导出当前会话 |
| `/search <query>` | 搜索会话历史 |
| `/clear-history` | 清空会话历史 |
| `/version` | 显示版本信息 |
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
