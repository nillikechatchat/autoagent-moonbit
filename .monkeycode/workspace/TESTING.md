# Testing Materials

## Verification Commands

```bash
# Check source code
PATH="$HOME/.moon/bin:$PATH" moon check

# Build project
PATH="$HOME/.moon/bin:$PATH" moon build

# Run tests
PATH="$HOME/.moon/bin:$PATH" moon test

# Run demo CLI
PATH="$HOME/.moon/bin:$PATH" moon run src/main
```

## Current Test Coverage

测试文件：`src/autoagent/agent_test.mbt`。

当前覆盖（14 个测试）：

- 默认 Agent 输出包含核心识别信息和默认工具结果。
- `RunTrace` 暴露状态、停止原因和 observations。
- 空目标在工具执行前停止。
- 工具元数据包含 category 和 risk（`RiskLevel` 枚举）。
- Planner 遵守 `max_steps`。
- Planner 对空目标返回空步骤。
- Memory 按顺序保存消息。
- 未注册工具路径返回失败 trace。
- 超过 `max_goal_length` 的目标会被拒绝。
- 非低风险工具会被拒绝执行。
- 工具失败后停止后续步骤。
- `max_goal_length` 边界值测试（恰好等于限制时通过）。
- `Memory::summary` 输出格式测试。
- `Provider::complete_trace` 输出格式测试。

## Current Verification Result

最近一次验证结果：

- `moon check`：通过。
- `moon build`：通过。
- `moon test`：14 passed, 0 failed。
- `moon run src/main`：输出 completed trace 和三步工具结果。

## Planned Test Additions

- 后续 LLM Provider adapter 的 mock contract test。
- 后续动态 Planner 的工具选择测试。
- 后续 Memory 持久化的导入导出测试。
