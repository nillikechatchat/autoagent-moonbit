# AutoAgent Project Wiki

AutoAgent 是一个使用 MoonBit 编写的轻量级 Agent Runtime 原型。项目当前提供一个确定性的本地 Agent 循环，用于演示从用户目标到规划、工具执行、记忆记录和最终响应生成的完整流程。

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

- 将用户目标转换为固定顺序的三步计划：`scaffold`、`checklist`、`coach`。
- 通过工具注册表解析计划步骤，仅执行已注册低风险工具。
- 工具失败后立即停止后续步骤（fail-fast）。
- 用户目标长度受 `max_goal_length` 限制。
- 工具输出长度受 `max_tool_output_length` 限制。
- Memory 支持条数和单条长度容量限制。
- 将 system、user、tool、assistant 消息写入内存。
- 使用确定性 Provider 汇总目标、状态、停止原因和工具观察结果。
- 提供 `RunTrace` 结构化执行轨迹，包含状态、停止原因和观察结果。
- 提供 `moon check`、`moon build`、`moon test` 和 `moon run src/main` 验证路径。

## 当前边界

- Provider 当前为确定性文本拼接，尚未接入真实 LLM。
- Planner 当前为固定规则规划，尚未实现动态任务分解。
- Memory 当前为进程内数组，尚未实现持久化、检索或压缩。
- Tool 当前为内置文本工具，尚未支持参数 schema 或外部执行。

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

# Build project
PATH="$HOME/.moon/bin:$PATH" moon build

# Run tests
PATH="$HOME/.moon/bin:$PATH" moon test

# Run demo
PATH="$HOME/.moon/bin:$PATH" moon run src/main
```
