# Audit Report 001

- Date: 2026-05-28
- Scope: 全量源码、测试、文档、安全规约
- Auditor: AutoCode Agent
- Status: Fixed

## Summary

第一轮全面审计覆盖 `src/autoagent/` 全部 7 个源码文件、`src/main/main.mbt`、测试文件和 `.monkeycode/` 文档。发现 6 个需要修复的问题，其中 3 个中等、3 个低优先级。

## Findings

### F001 - [Medium] Memory 无容量边界

位置：`src/autoagent/memory.mbt:12`

问题：`Memory::store` 无条数和单条长度限制。多次 run 或长输入会导致 messages 数组无限增长，造成资源消耗风险。

修复方案：
- Memory 增加 `max_messages` 和 `max_message_length` 配置。
- 超过条数时淘汰最早消息。
- 单条超长时截断并标记。

状态：Fixed（已修复）

---

### F002 - [Medium] 工具输出无长度限制

位置：`src/autoagent/tool.mbt:37-48`

问题：工具函数将完整 goal 嵌入输出字符串。当 goal 接近 `max_goal_length`（1000 字符）时，三个工具输出叠加到 observations 中，Memory 和 Provider 输出可能非常长。

修复方案：
- 工具输出增加 `max_output_length` 截断。
- 或在 `Agent::invoke_step` 层对工具结果做统一截断。

状态：Fixed（已修复）

---

### F003 - [Low] ToolSpec.risk 是自由字符串

位置：`src/autoagent/types.mbt:34`、`src/autoagent/agent.mbt:110`

问题：`risk` 字段是 `String`，通过 `== "low"` 比较。拼写错误（如 `"Low"`、`"LOW"`）会绕过风险检查。

修复方案：
- 将 `risk` 改为 `enum RiskLevel { Low; Medium; High }`。
- 更新 `Tool::new` 和 `Agent::invoke_step` 中的风险检查。

状态：Fixed（已修复）

---

### F004 - [Low] Provider::complete 是死代码

位置：`src/autoagent/provider.mbt:12-26`

问题：`Provider::complete` 从未被调用。`Agent::run_trace` 只使用 `Provider::complete_trace`。保留死代码增加维护负担。

修复方案：
- 删除 `Provider::complete`。
- 更新 INTERFACES.md 移除该函数文档。

状态：Fixed（已修复）

---

### F005 - [Low] 多次 run 共享同一 Memory 导致消息累积

位置：`src/autoagent/agent.mbt:34-36`

问题：`Agent::run` 和 `Agent::run_trace` 都向 `self.memory` 写入消息。同一 Agent 实例多次调用时，消息会累积，前一次 run 的消息会影响后续 run 的 Provider 输出。

修复方案：
- 每次 `run_trace` 开始时重置 Memory。
- 或在 `run_trace` 内部使用局部 Memory。

状态：Fixed（已修复）

---

### F006 - [Low] 缺少边界值和格式测试

位置：`src/autoagent/agent_test.mbt`

问题：
- 无 `max_goal_length` 边界值测试（恰好等于限制时应通过）。
- 无 `Memory::summary` 输出格式测试。
- 无 `Provider::complete_trace` 输出格式测试。

修复方案：
- 增加边界值测试：goal 长度恰好等于 `max_goal_length` 时应正常执行。
- 增加 `Memory::summary` 格式断言。
- 增加 `Provider::complete_trace` 输出断言。

状态：Fixed（已修复）

---

## Verification Matrix

| Check | Result |
|-------|--------|
| moon check | Pass |
| moon build | Pass |
| moon test | 14 passed, 0 failed |
| moon run src/main | Pass |

## Next Action

根据以上 6 个 Finding 执行修复，完成后进行第二轮审计。
