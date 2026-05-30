# AutoAgent Project Wiki

AutoAgent 是一个使用 MoonBit 编写的轻量级 Agent CLI/runtime。项目当前提供 MoonBit 原生 REPL、OpenAI-compatible LLM 接入、83 个 runtime tools、10 个内置员工技能和确定性测试路径。

## 文档导航

- [使用手册](USAGE.md)：快速开始、配置、工具开发、Provider/Planner 替换、安全模型、API 速查。
- [系统架构](ARCHITECTURE.md)：组件职责、运行流程和关键设计约束。
- [接口说明](INTERFACES.md)：公开类型、函数、包路径和命令入口。
- [开发者指南](DEVELOPER_GUIDE.md)：环境准备、验证命令、扩展步骤和代码约定。
- [演进计划](ROADMAP.md)：从教学原型到可扩展 Agent Runtime 的阶段计划。
- [Agent 框架调研](AGENT_FRAMEWORK_RESEARCH.md)：GitHub Agent 项目架构模式和当前缺口清单。
- [安全审计报告 001](AUDIT_REPORT_001.md)：第一轮全量安全审计，6 个 Finding 全部已修复。
- [安全审计报告 002](AUDIT_REPORT_002.md)：第二轮审计验证，3 个 Finding 已修复或接受。
- [过程资料工作目录](../workspace/README.md)：规约、流程、测试、示例、参考和阶段状态记录入口。
- [核心概念：Agent Loop](专有概念/AgentLoop.md)：当前 Agent 循环的执行语义。
- [核心概念：Tool Allowlist](专有概念/ToolAllowlist.md)：工具注册和安全边界。
- [模块：autoagent](模块/AutoAgentCore.md)：核心库模块说明。
- [模块：main](模块/MainCli.md)：示例 CLI 模块说明。

## 当前能力

- MoonBit REPL 支持多轮对话、工具调用解析、会话持久化、导出和历史搜索。
- LLM Provider 支持环境变量和 `.autoagent/config.json` 配置，采用 OpenAI-compatible Chat Completions API。
- Runtime tool system 提供 83 个工具，覆盖文件、命令、搜索、Git、记忆、环境、归档和系统信息。
- Skill system 提供 10 个员工技能和 20 个专用 skill tools，按 goal 关键词选择专家能力。
- Legacy deterministic Agent loop 仍提供 `RunTrace`、风险等级、fail-fast 和容量限制测试覆盖。
- 默认测试保持确定性，不依赖真实 LLM 或网络。
- 提供 `moon check`、`moon test`、`make build-native` 和 `make all` 验证路径。

## 当前边界

- 真实 LLM 可用性取决于 `MCAI_LLM_API_KEY`、`MCAI_LLM_BASE_URL` 和网络环境；无 key 时走 deterministic fallback。
- Tool protocol 仍以字符串输入输出为主，结构化参数 schema 和 dry-run 审计属于后续增强。
- Planner 与 REPL tool-call loop 并存；动态任务分解仍以 LLM 生成工具调用为主。
- 跨平台发布主要验证 Linux native；wasm-gc/js 目标保留 no-op I/O stub 用于 typecheck/test。

## 代码入口

- 核心库包：`src/autoagent/`
- 示例入口包：`src/main/`
- 需求规格：`.monkeycode/specs/autoagent/requirements.md`
- 设计规格：`.monkeycode/specs/autoagent/design.md`
- 过程资料：`.monkeycode/workspace/README.md`
- 阶段状态记录：`.monkeycode/workspace/STATE_LOG.md`

## 验证状态

项目已在以下工具链上验证：

- `moonc v0.9.3+b53c2807d`
- `moon 0.1.20260522`
- `moonrun 0.1.20260522`

验证命令：

```bash
# Check source code
PATH="$HOME/.moon/bin:$PATH" moon check

# Run tests
PATH="$HOME/.moon/bin:$PATH" moon test

# Build native binary
make build-native

# Run full quality gate
make all
```
