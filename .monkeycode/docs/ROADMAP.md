# AutoAgent Evolution Plan

## Vision

AutoAgent 的长期目标是成为 MoonBit 生态中的轻量 Agent Starter Kit：既能帮助开发者理解 Agent 的基本机制，也能作为小型 Agent Runtime 的可扩展基础。

## Strategy

演进策略采用四个原则：

- Keep the core small：核心运行时保持可读和可测试。
- Make extension explicit：Provider、Planner、Memory、Tool 的扩展点保持清晰。
- Prefer deterministic tests：默认测试保持确定性，外部 LLM 和网络能力通过 adapter 测试隔离。
- Preserve safe defaults：默认工具保持 allowlist 和文本输出，外部执行能力逐步引入权限策略。

## Current Runtime Snapshot

- Runtime tools: 83, covering file I/O, command execution, web fetch, code search, git inspection, memory, environment, metadata, archive, and system information workflows.
- Built-in skills: 10 (`research`, `code-review`, `docs`, `testing`, `code-gen`, `debug`, `refactor`, `security`, `performance`, `architecture`)
- Skill tools: 20
- Verification: `moon check`, `moon test` with 282 tests, `make build-native`, and `make all`

## Milestone 0: Teaching Prototype

Status: Done

目标：提供一个完整可运行的 Agent loop 教学原型。

已完成能力：

- MoonBit 项目结构。
- `Agent::run` 主循环。
- 固定规则 Planner。
- 三个默认工具：`scaffold`、`checklist`、`coach`。
- 进程内 Memory。
- 确定性 Provider。
- CLI demo。
- 基础测试。

验收标准：

- `moon check` 通过。
- `moon build` 通过。
- `moon test` 通过。
- `moon run src/main` 输出完整 run 结果。

## Milestone 1: Runtime Hardening

Status: Done

目标：补齐核心运行时的边界处理和测试覆盖。

计划任务：

- 为 `Planner::plan` 增加独立测试。已完成空目标和 `max_steps` 覆盖。
- 为 `Memory::store`、`Memory::summary` 增加顺序测试。已完成消息顺序和 summary 覆盖。
- 为未知工具路径增加失败测试。已完成。
- 为 `max_steps` 增加边界测试。已完成。
- 为空目标增加默认处理策略。已完成 `EmptyGoal` stop reason。
- 在 README 中说明错误处理模型。

验收标准：

- 测试覆盖 Agent、Planner、Tool、Memory 四个模块的核心路径。
- 空目标和未知工具都有可解释输出。
- 文档与实际行为一致。

已完成补强：

- `RunTrace` 结构化执行轨迹。
- `RunState` 生命周期状态。
- `StopReason` 停止原因（含 `InputTooLong`）。
- `Step.reason` 计划解释。
- `ToolSpec.category` 和 `ToolSpec.risk`（`RiskLevel` 枚举）工具元数据。
- Planner、Memory、未知工具和 `max_steps` 测试覆盖。
- `Memory::summary` 和 `Provider::complete_trace` 格式测试。
- `max_goal_length` 边界值测试。
- Memory 容量限制（`max_messages`、`max_message_length`）。
- 工具输出长度限制（`max_tool_output_length`）。
- 工具风险等级枚举（`RiskLevel`）和执行权限检查。
- 工具失败后 fail-fast 停止后续步骤。
- 每次 run 重置 Memory。
- 两轮安全审计（AUDIT_REPORT_001、AUDIT_REPORT_002）。
- 文档与代码全面同步。

## Milestone 2: Tool Protocol

Status: Planned

目标：将当前字符串工具扩展为可描述、可校验、可审计的工具协议。

计划任务：

- 扩展 `ToolSpec`，增加参数说明和风险等级字段。风险等级字段已完成（`RiskLevel` 枚举），参数说明待完成。
- 引入 `ToolCall` 的执行路径。
- 将工具执行结果统一为结构化结果。
- 增加工具 allowlist 文档。
- 增加 dry-run 策略。

验收标准：

- 每个工具都有名称、描述和输入约束说明。
- Agent 执行工具前能记录工具调用意图。
- 默认工具仍保持确定性文本输出。

## Milestone 3: Provider Adapter

Status: Planned

目标：允许接入真实 LLM，同时保持 deterministic provider 用于测试。

计划任务：

- 抽象 Provider 配置。
- 增加 prompt builder。
- 增加 LLM adapter 接口设计。
- 增加网络失败的错误模型。
- 增加 mock provider 测试。

验收标准：

- 本地测试无需真实 API key。
- LLM Provider 可以从 goal、memory、results 生成回答。
- Provider 失败时 Agent 返回可解释错误。

## Milestone 4: Dynamic Planning

Status: Planned

目标：让 Planner 根据目标和工具能力生成更贴合任务的步骤。

计划任务：

- 为工具增加 capability tags。
- Planner 根据 tags 选择工具。
- Planner 输出步骤原因。
- 支持最多步骤数和停止条件。
- 增加计划解释输出。

验收标准：

- 不同目标可以生成不同工具组合。
- 所有计划仍受 `max_steps` 限制。
- 计划输出可被测试稳定验证。

## Milestone 5: Memory Persistence

Status: Planned

目标：将 Memory 从单次运行数组扩展为可保存、可恢复、可检索的会话记忆。

计划任务：

- 增加 Memory 导出格式。
- 增加 Memory 导入接口。
- 增加消息裁剪策略。
- 增加摘要压缩策略。
- 评估文件持久化方案。

验收标准：

- Agent run 可以导出消息历史。
- Memory summary 可以在消息变多时保持有界。
- 持久化格式有文档说明和测试覆盖。

## Milestone 6: Usable Agent Builder

Status: Planned

目标：从原型升级为帮助用户搭建 Agent 的实际工具。

计划任务：

- CLI 支持用户输入目标。
- 生成 Agent 项目脚手架建议。
- 生成工具清单模板。
- 生成提示词模板。
- 生成验证清单。

验收标准：

- 用户可以通过 CLI 输入目标。
- AutoAgent 输出包含可执行的搭建步骤。
- 输出明确区分设计、实现、验证和运营建议。

## Risk Register

- MoonBit 工具链持续演进，配置格式和语法可能变化。
- LLM Provider 接入会引入网络失败、成本和凭证管理问题。
- 外部工具执行会引入安全风险，需要权限策略和审计记录。
- 记忆持久化会引入隐私和数据生命周期问题。

## Release Policy

建议版本节奏：

- `0.1.x`：教学原型和文档完善。
- `0.2.x`：工具协议和测试覆盖增强。
- `0.3.x`：Provider adapter 和动态规划。
- `0.4.x`：持久化记忆和 CLI 输入。
- `1.0.0`：稳定 API、完整文档和可复用 Agent Builder。

## Process Documentation

过程资料统一放在 `.monkeycode/workspace/`，覆盖规约、流程、测试、示例、参考和阶段状态记录。`STATE_LOG.md` 记录项目从时间维度推进的状态变迁，`ROADMAP.md` 保持阶段目标和计划视角。
