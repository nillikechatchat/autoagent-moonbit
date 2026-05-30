# AutoAgent

AutoAgent 是一个纯 MoonBit 实现的轻量 Agent CLI/runtime。MoonBit 负责所有逻辑（规划、对话、工具选择、JSON 解析、记忆管理、REPL）；C FFI 仅负责 I/O 原语（HTTP、文件、进程、环境变量）。

## 特性

- **本地智能体引擎**：无需 LLM API 即可自主理解意图、执行工具
- **自然语言交互**：用自然语言描述任务，自动选择合适的工具
- **83 个 Runtime Tools**：文件、搜索、Git、系统、压缩等
- **10 个专家技能**：研究、代码审查、文档、测试、调试等
- **会话持久化**：记忆恢复、会话导出
- **Hermes 风格 REPL**：默认进入交互式对话

## 架构

```
用户输入 → 意图分类 → 工具选择 → 工具执行 → 结果返回
         ↓ (可选)
      LLM API → 响应解析 → 工具调用 → 循环
```

**单一二进制，无外部依赖：** `_build/native/release/build/src/main/main.exe`

## 快速开始

```bash
# 类型检查
make check

# 运行测试 (282 tests)
make test

# 构建原生二进制 (含 C I/O 层)
make build-native

# 启动交互式 REPL (默认，像 Hermes 一样)
./_build/native/release/build/src/main/main.exe

# 单次运行
./_build/native/release/build/src/main/main.exe run "hello"
./_build/native/release/build/src/main/main.exe run "git status"
./_build/native/release/build/src/main/main.exe run "list files"
```

## LLM 配置 (可选)

```bash
export MCAI_LLM_API_KEY="your-key"
export MCAI_LLM_BASE_URL="https://proxy.monkeycode-ai.com/v1"
export MCAI_LLM_MODEL="monkeycode-basic/qwen3.5-plus"
```

或编辑 `.autoagent/config.json`。无 API key 时使用本地智能体引擎。

## 技能系统 (10 Skills, 20 Skill Tools)

| 技能 | 工具 | 用途 |
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

这些 skills 是内置“员工/专家角色”：每个角色包含说明、关键词和两个专用 skill tools。Agent 可根据 goal 关键词选择合适角色，并把角色说明注入系统上下文。

## 功能完整性

当前实现覆盖可用 CLI/runtime 的核心链路：配置加载、LLM 调用、流式输出、工具调用解析、runtime tool 执行、会话保存、记忆恢复、skill 注册、Eval 和测试。项目中保留的 `io_stub.mbt` 是 wasm-gc/js target 的测试替身，native 构建使用 `native/io.c` 执行真实 I/O。

当前已知边界：runtime tools 使用字符串/JSON 字符串作为输入协议；结构化 schema、人工批准、dry-run 审计和跨平台发布矩阵属于后续增强。真实 LLM 行为取决于可用 API key、base URL 和网络环境。

## 工具 (83 Runtime Tools)

| 工具 | 说明 |
|------|------|
| read_file | 读取项目内文件 |
| write_file | 写入项目内文件 (JSON input) |
| edit_file | 局部 find/replace 编辑 |
| list_files | 列出项目内目录 |
| run_command | 执行本地命令 (带安全拒绝列表) |
| search_web | DuckDuckGo 搜索 |
| find_files | 按名称模式查找文件 |
| code_search | 按内容搜索代码 |
| git_status | 查看工作区状态 |
| git_diff | 查看 diff 统计 |
| memory_write | 写入 agent 记忆 |
| memory_read | 读取 agent 记忆 |
| env_info | 查看环境信息 |
| project_info | 查看项目摘要 |
| http_get | HTTP GET 请求 |
| file_info | 获取文件元数据 |
| timestamp | 获取当前时间戳 |
| env_get | 获取环境变量 |
| string_replace | 字符串替换 |
| uuid_generate | 生成 UUID |
| get_cwd | 获取当前工作目录 |
| head_file | 读取文件前 N 行 |
| tail_file | 读取文件后 N 行 |
| count_lines | 统计文件行数 |
| grep_file | 在文件中搜索模式 |
| diff_files | 比较两个文件 |
| copy_file | 复制文件 |
| move_file | 移动/重命名文件 |
| append_file | 追加到文件 |
| dir_size | 获取目录大小 |
| disk_usage | 获取磁盘使用情况 |
| sort_file | 排序文件行 |
| uniq_file | 去除重复行 |
| wc_file | 统计字数 |
| basename | 获取文件名 |
| dirname | 获取目录名 |
| realpath | 获取绝对路径 |
| which | 查找命令位置 |
| date | 获取当前日期/时间 |
| mkdir | 创建目录 |
| is_dir | 检查是否为目录 |
| truncate_file | 截断文件到 N 行 |
| grep_count | 统计模式匹配次数 |
| grep_context | 获取匹配上下文 |
| file_type | 获取文件类型 |
| file_permissions | 获取文件权限 |
| file_owner | 获取文件所有者 |
| file_modified | 获取文件修改时间 |
| file_size | 获取文件大小 |
| list_dir_detailed | 详细列出目录 |
| find_by_type | 按类型查找文件 |
| find_by_size | 按大小查找文件 |
| grep_recursive | 递归搜索 |
| find_by_name | 按名称查找文件 |
| find_by_time | 按修改时间查找文件 |
| file_checksum | 获取文件校验和 |
| compress_file | 压缩文件 |
| decompress_file | 解压文件 |
| tar_create | 创建 tar 归档 |
| tar_extract | 解压 tar 归档 |
| zip_create | 创建 zip 归档 |
| zip_extract | 解压 zip 归档 |
| is_readable | 检查文件是否可读 |
| is_writable | 检查文件是否可写 |
| is_executable | 检查文件是否可执行 |
| file_extension | 获取文件扩展名 |
| file_lines | 获取文件行数 |
| file_words | 获取文件字数 |
| file_chars | 获取文件字符数 |
| system_info | 获取系统信息 |
| memory_info | 获取内存信息 |
| cpu_info | 获取 CPU 信息 |
| network_info | 获取网络信息 |
| process_list | 获取进程列表 |
| env_list | 获取环境变量列表 |
| uptime | 获取系统运行时间 |
| hostname | 获取系统主机名 |
| whoami | 获取当前用户 |
| who | 获取已登录用户 |
| last | 获取最近登录记录 |
| command_exists | 检查命令是否存在 |
| shell_info | 获取 shell 信息 |
| path_list | 获取 PATH 目录列表 |

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
│   │   ├── skill.mbt           # 10 技能 / 20 skill tools
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
- `moon test`：282 passed, 0 failed
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
- Google agents-cli：技能包模式
- Codex：集成测试优先、Snapshot 测试
- Superpowers：TDD 强制流程
