# Module: AutoAgent Core

路径：`src/autoagent/`

AutoAgent Core 是项目核心库，包含 Agent Runtime 的所有当前能力。

## Files

- `agent.mbt`：Agent 配置、主循环和默认 Agent 构造。
- `types.mbt`：共享数据类型和渲染函数。
- `planner.mbt`：固定步骤规划器。
- `tool.mbt`：工具结构、工具查找和默认工具实现。
- `memory.mbt`：进程内消息记忆。
- `provider.mbt`：确定性响应生成器。
- `agent_test.mbt`：默认 Agent 行为测试。
- `moon.pkg`：MoonBit 包配置。

## Responsibilities

- 提供可复用的 Agent 构造函数。
- 提供默认 Agent。
- 管理工具执行路径。
- 管理 Memory 写入和摘要。
- 提供确定性 demo 输出。

## Public API Surface

主要公开入口：

- `default_agent()`
- `Agent::new(...)`
- `Agent::run(...)`
- `Planner::new(...)`
- `Planner::plan(...)`
- `Tool::new(...)`
- `Tool::execute(...)`
- `Memory::new(...)`
- `Memory::store(...)`
- `Memory::summary(...)`
- `Provider::new(...)`
- `Provider::complete(...)`

## Internal Behavior

`Agent::run` 当前会在同一个 `Agent` 实例中追加 Memory。复用同一个 Agent 多次运行时，Memory 会累积历史消息。

## Testing

当前测试：`src/autoagent/agent_test.mbt`。

测试覆盖默认 Agent 输出包含关键文本。后续需要增加 Planner、Tool、Memory 的独立测试。
