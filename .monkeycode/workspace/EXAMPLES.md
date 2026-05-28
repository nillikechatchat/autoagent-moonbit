# Project Examples

## Demo Command

```bash
# Run the default AutoAgent demo
PATH="$HOME/.moon/bin:$PATH" moon run src/main
```

## Demo Output Shape

```txt
AutoAgent provider=deterministic
Goal: build a research assistant that can plan, call safe tools, and teach the user how to improve prompts
State: completed
Stop: completed all planned steps
- 1. scaffold: ... => ...
- 2. checklist: ... => ...
- 3. coach: ... => ...
```

## Add Tool Example

1. 在 `src/autoagent/tool.mbt` 的 `Tool::execute` 中新增分支。
2. 为新工具添加私有函数。
3. 在 `src/autoagent/agent.mbt` 的 `default_agent` 中注册 `Tool::new(name, description, category, risk)`。
4. 在 `src/autoagent/planner.mbt` 中新增或替换 `Step`。
5. 在 `src/autoagent/agent_test.mbt` 中添加行为测试。
6. 更新 `.monkeycode/docs/INTERFACES.md` 和 `.monkeycode/workspace/TESTING.md`。

## Trace Example

`Agent::run_trace` 返回结构化运行轨迹，包含：

- `goal`：用户目标。
- `state`：`ready`、`running`、`completed` 或 `failed`。
- `stop_reason`：完成、空目标、输入过长或工具失败。
- `steps`：Planner 生成的步骤。
- `observations`：工具执行观察结果。
- `answer`：Provider 生成的最终文本。
