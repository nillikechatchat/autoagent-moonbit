# Project Conventions

## Scope

本规约适用于 AutoAgent 的源码、规格文档、项目 Wiki 和过程资料。

## Code Conventions

- 核心代码放在 `src/autoagent/`。
- 示例入口放在 `src/main/`。
- Agent Core、Planner、Tool、Memory、Provider 和共享类型保持模块分离。
- 默认能力保持确定性，便于测试和教学。
- 工具执行必须通过 `tools` 注册表解析。
- 新工具需要显式声明 `ToolSpec` 的 `name`、`description`、`category` 和 `risk`。

## Documentation Conventions

- 项目 Wiki 放在 `.monkeycode/docs/`。
- 需求和设计规格放在 `.monkeycode/specs/autoagent/`。
- 项目过程资料放在 `.monkeycode/workspace/`。
- 架构变化更新 `.monkeycode/docs/ARCHITECTURE.md`。
- 公开接口变化更新 `.monkeycode/docs/INTERFACES.md`。
- 开发流程变化更新 `.monkeycode/docs/DEVELOPER_GUIDE.md` 和 `.monkeycode/workspace/PROCESS.md`。
- 阶段状态变化追加到 `.monkeycode/workspace/STATE_LOG.md`。

## Safety Conventions

- 默认工具只生成文本建议。
- 默认只执行 `risk = "low"` 的工具。
- 外部执行工具需要新增风险说明、dry-run 策略、人工批准路径和测试覆盖。
- 用户目标需要受 `max_goal_length` 限制。
- 工具失败后停止后续步骤。
- 测试默认使用确定性 Provider。
- 文档示例中的凭证统一使用 `<API_KEY>` 这类占位符。

## Change Record Conventions

- `ROADMAP.md` 记录阶段目标和计划状态。
- `STATE_LOG.md` 记录按时间推进的状态变迁。
- 每次完成验证后记录实际运行的命令和结果。
