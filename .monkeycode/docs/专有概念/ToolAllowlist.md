# Tool Allowlist

Tool Allowlist 是 AutoAgent 的安全边界。Agent 只能执行注册到 `tools` 数组中的工具。

## Current Implementation

相关文件：`src/autoagent/tool.mbt` 和 `src/autoagent/agent.mbt`。

默认工具在 `default_agent` 中注册：

- `scaffold`
- `checklist`
- `coach`

每个默认工具都包含 `category` 和 `risk` 元数据。当前默认工具风险等级均为 `low`。

执行步骤：

1. Planner 输出 `Step.action`。
2. Agent 调用 `find_tool(self.tools, s.action)`。
3. 找到工具后检查 `ToolSpec.risk`。
4. `risk = Low` 时调用 `tool.execute(s.input)`。
5. 中高风险工具返回需要批准的 `Failure`。
6. 未找到工具时返回 `Failure`。

## Security Boundary

当前默认工具只生成文本建议。这个设计让项目可以安全演示 Agent loop，同时保留未来扩展外部工具的接口位置。

当前执行路径默认只允许低风险工具运行。工具失败后 Agent 停止后续步骤，并在 `RunTrace` 中记录失败状态和停止原因。

## Extension Rules

- 新工具必须通过 `default_agent` 或自定义 Agent 显式注册。
- 新工具必须在 `Tool::execute` 中有明确分支。
- 外部执行工具需要 dry-run、权限说明和非低风险等级。
- 高风险工具需要人工批准机制。
- 工具结果需要进入 Memory 便于审计。

## Planned Improvements

- 为 `ToolSpec` 增加输入 schema。
- 为 `ToolCall` 增加结构化执行路径。
- 为工具调用增加 trace id。
- 为工具失败增加错误码。
