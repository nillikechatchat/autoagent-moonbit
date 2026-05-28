# Agent Framework Research

## Sources Reviewed

本次调研覆盖了公开 GitHub 项目及其相关文档、社区解析和官方说明，重点关注轻量 Agent Runtime 的架构设计。

代表性项目：

- Nanobot：轻量 Agent loop、上下文组装、分层记忆、工具集、消息总线、渠道适配、子 Agent、定时任务。
- smolagents：CodeAgent、ToolCallingAgent、AgentMemory、执行日志、final answer 工具、安全执行器。
- LangGraph：StateGraph、节点、边、共享状态、checkpoint、human-in-the-loop、长期/短期记忆。
- AutoGen：多 Agent 会话、角色拆分、UserProxy、人类在环、群聊/团队协作。
- CrewAI：角色驱动、Task 编排、Agent 团队协作。
- OpenAI Agents 风格：model、tools、handoffs、guardrails、trace。

## Common Architecture Patterns

### Agent Loop

成熟 Agent 框架通常拥有明确的循环：读取目标或消息、组装上下文、规划下一步、调用工具、记录观察、判断停止条件、输出最终结果。

AutoAgent 已具备基础顺序循环。本次补强加入 `run_trace`，让循环状态和停止原因可观察。

### Tool Registry And Metadata

工具通常需要名称、描述、输入约束、安全边界和执行结果。smolagents 和函数调用框架强调工具描述对模型选择工具的影响，Nanobot 强调工具 allowlist 和内置工具边界。

AutoAgent 已具备工具注册表。本次补强给 `ToolSpec` 增加 `category` 和 `risk`，为后续权限策略和文档化工具能力打基础。

### Memory And Trace

成熟框架会记录每一步操作和 observation。smolagents 使用日志生成 inner memory，LangGraph 将短期记忆作为状态，Nanobot 使用持久记忆和上下文组装。

AutoAgent 已具备进程内 Memory。本次补强加入 `RunTrace`，将步骤、观察、状态和停止原因结构化返回。

### State And Stop Reason

生产 Agent 需要明确状态、失败原因、最大轮次和停止条件。LangGraph 通过状态图处理流程状态，ReAct 实现通常使用 `max_steps` 防止无界循环。

AutoAgent 已具备 `max_steps`。本次补强加入 `RunState` 和 `StopReason`，为空目标和工具失败提供可解释结果。

### Planning Explainability

Agent 计划需要可解释。LangGraph 和 ReAct 调试依赖步骤原因，smolagents 将 step 写入 memory。

AutoAgent 当前 Planner 是固定规则。本次补强给 `Step` 增加 `reason` 字段，让计划原因进入输出和 trace。

## Feature Gap Checklist

### Addressed In Current Code

- Structured run trace: `RunTrace`。
- Run lifecycle state: `RunState`。
- Stop reason: `StopReason`。
- Step rationale: `Step.reason`。
- Tool metadata: `ToolSpec.category` and `ToolSpec.risk`。
- Empty goal handling: `EmptyGoal` stop reason。
- Trace tests: completed run, empty goal, tool metadata。

### Remaining Gaps

- Dynamic Planner：根据目标和工具能力选择步骤。
- Tool schema：工具输入输出 schema 和参数校验。
- ToolCall execution path：让 `ToolCall` 成为实际执行对象。
- Memory persistence：跨 run 保存和恢复。
- Context builder：将 system、memory、tools、trace 组装为 Provider prompt。
- LLM Provider adapter：真实模型接入和 mock provider 分离。
- Human approval hook：高风险工具执行前暂停。
- Retry and timeout：工具失败后的重试和超时策略。
- CLI arguments：从命令行读取 goal。
- Multi-agent handoff：后续版本再考虑角色协作。

## Applied Design Decisions

- 保持当前项目的轻量定位，优先增加类型和可观测性，暂缓外部工具执行。
- 保持默认工具低风险文本输出，避免引入安全边界复杂度。
- 保留 `Agent::run` 作为简单入口，同时新增 `Agent::run_trace` 给调试和上层应用使用。
- 使用确定性 Provider 输出 trace，保持测试稳定。

## References

- Nanobot GitHub: https://github.com/HKUDS/nanobot
- smolagents GitHub: https://github.com/huggingface/smolagents
- LangGraph GitHub: https://github.com/langchain-ai/langgraph
- AutoGen GitHub: https://github.com/microsoft/autogen
- CrewAI GitHub: https://github.com/crewAIInc/crewAI
