# AutoAgent Developer Guide

## Prerequisites

当前环境使用的 MoonBit 工具链：

- `moonc v0.9.3+b53c2807d`
- `moon 0.1.20260522`
- `moonrun 0.1.20260522`

安装命令：

```bash
# Install MoonBit toolchain on Linux or macOS
curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash
```

当前 shell 中使用 MoonBit 命令：

```bash
# Add MoonBit binaries to PATH for this shell
PATH="$HOME/.moon/bin:$PATH" moon version
```

## Common Commands

```bash
# Check source code
PATH="$HOME/.moon/bin:$PATH" moon check

# Format source code and MoonBit config files
PATH="$HOME/.moon/bin:$PATH" moon fmt

# Build project
PATH="$HOME/.moon/bin:$PATH" moon build

# Run tests
PATH="$HOME/.moon/bin:$PATH" moon test

# Run demo CLI
PATH="$HOME/.moon/bin:$PATH" moon run src/main
```

## Development Workflow

1. 修改 `src/autoagent/` 中的核心库代码。
2. 运行 `moon fmt` 格式化代码。
3. 运行 `moon check` 获取快速类型检查反馈。
4. 运行 `moon test` 验证行为。
5. 运行 `moon run src/main` 检查 demo 输出。
6. 同步更新 `.monkeycode/docs/` 和 README 中受影响的说明。
7. 当规约、流程、测试、示例、参考或阶段状态变化时，同步更新 `.monkeycode/workspace/`。

## Add A Tool

当前工具注册在 `src/autoagent/agent.mbt` 的 `default_agent` 中，执行分发在 `src/autoagent/tool.mbt` 的 `Tool::execute` 中。

添加工具步骤：

1. 在 `Tool::execute` 中新增工具名分支。
2. 为工具实现一个私有函数。
3. 在 `default_agent` 的工具数组中注册 `Tool::new(name, description, category, risk)`。
4. 在 `Planner::plan` 中加入对应 `Step`。
5. 更新测试，确认输出包含新工具结果。
6. 更新 `INTERFACES.md` 和 `ROADMAP.md` 中的工具说明。

## Replace The Provider

当前 `Provider::complete_trace` 是确定性拼接。接入真实 LLM adapter 时建议保持相同输入：

- `goal`
- `memory`
- `results`

建议扩展顺序：

1. 增加 Provider 配置字段。
2. 增加 prompt 渲染函数。
3. 保留确定性 Provider 作为测试替身。
4. 为 LLM Provider 增加失败返回策略。
5. 避免在测试中依赖真实网络调用。

## Replace The Planner

当前 `Planner::plan` 返回固定步骤数组。替换 Planner 时保持输出类型为 `Array[Step]`。

建议新增能力：

- 根据目标选择工具。
- 生成步骤原因。
- 引入 step dependencies。
- 限制最大步骤数。
- 为未知目标返回安全的指导步骤。

## Memory Evolution

当前 `Memory` 支持容量限制和消息截断。后续扩展建议按以下顺序推进：

1. 保持 `Memory::store` 和 `Memory::summary` 接口稳定。
2. 增加最大消息数或最大字符数限制。已完成 `max_messages` 和 `max_message_length`。
3. 增加会话导出格式。
4. 增加持久化文件存储。
5. 增加检索和压缩策略。

## Testing Guidelines

当前测试位于 `src/autoagent/agent_test.mbt`。

测试建议：

- 优先测试 Agent 输出中的关键行为信号。
- 对工具执行结果做确定性断言。
- 对 Planner 的步骤数量和顺序做单元测试。
- 对未知工具路径做失败断言。
- 对 Memory 的消息顺序做断言。
- 对 `max_goal_length` 边界值做断言。
- 对风险等级枚举做断言。
- 对工具失败 fail-fast 做断言。

## Documentation Guidelines

- 架构变化更新 `ARCHITECTURE.md`。
- 公开类型或函数变化更新 `INTERFACES.md`。
- 开发流程变化更新 `DEVELOPER_GUIDE.md`。
- 路线变化更新 `ROADMAP.md`。
- README 只保留项目入口、快速开始和文档链接。
- 过程资料变化更新 `.monkeycode/workspace/` 下的对应文件。
- 阶段状态变化追加到 `.monkeycode/workspace/STATE_LOG.md`。
