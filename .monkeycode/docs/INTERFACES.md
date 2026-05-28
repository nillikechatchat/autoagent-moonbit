# AutoAgent Interfaces

## Module Paths

### Core Package

- Package path: `autoagent/autoagent/src/autoagent`
- Source directory: `src/autoagent/`
- Package config: `src/autoagent/moon.pkg`

### Demo CLI Package

- Source directory: `src/main/`
- Package config: `src/main/moon.pkg`
- Imports: `autoagent/autoagent/src/autoagent`

## Public Types

### Role

Defined in `src/autoagent/types.mbt`.

```moonbit
pub(all) enum Role {
  User
  Assistant
  System
  Tool
}
```

`Role` 标识消息来源。

### Message

Defined in `src/autoagent/types.mbt`.

```moonbit
pub(all) struct Message {
  role : Role
  content : String
}
```

`Message` 是 Memory 中保存的基本单元。

### Step

Defined in `src/autoagent/types.mbt`.

```moonbit
pub(all) struct Step {
  id : Int
  action : String
  input : String
  reason : String
}
```

`Step` 是 Planner 输出的可执行步骤。

### StepResult

Defined in `src/autoagent/types.mbt`.

```moonbit
pub(all) enum StepResult {
  Success(String)
  Failure(String)
}
```

`StepResult` 表示工具执行结果。

### ToolSpec

Defined in `src/autoagent/types.mbt`.

```moonbit
pub(all) struct ToolSpec {
  name : String
  description : String
  category : String
  risk : RiskLevel
}
```

`ToolSpec` 描述工具名和用途。

### RiskLevel

Defined in `src/autoagent/types.mbt`.

```moonbit
pub(all) enum RiskLevel {
  Low
  Medium
  High
}
```

`RiskLevel` 标识工具风险等级，执行时用于权限检查。

### RunState

Defined in `src/autoagent/types.mbt`.

```moonbit
pub(all) enum RunState {
  Ready
  Running
  Completed
  Failed
}
```

`RunState` 描述一次 Agent run 的生命周期状态。

### StopReason

Defined in `src/autoagent/types.mbt`.

```moonbit
pub(all) enum StopReason {
  CompletedAllSteps
  EmptyGoal
  InputTooLong
  ToolFailure(String)
}
```

`StopReason` 描述 Agent run 停止原因。

### RunTrace

Defined in `src/autoagent/types.mbt`.

```moonbit
pub(all) struct RunTrace {
  goal : String
  state : RunState
  stop_reason : StopReason
  steps : Array[Step]
  observations : Array[String]
  answer : String
}
```

`RunTrace` 提供结构化执行轨迹。

### AgentConfig

Defined in `src/autoagent/agent.mbt`.

```moonbit
pub(all) struct AgentConfig {
  name : String
  system_prompt : String
  max_steps : Int
  max_goal_length : Int
  max_tool_output_length : Int
}
```

`AgentConfig` 控制 Agent 名称、系统提示词、最大步骤数、目标长度上限和工具输出长度上限。

## Public Functions

### default_agent

Defined in `src/autoagent/agent.mbt`.

```moonbit
pub fn default_agent() -> Agent
```

返回内置 AutoAgent，包含确定性 Provider 和三个默认工具。

### Agent::new

Defined in `src/autoagent/agent.mbt`.

```moonbit
pub fn Agent::new(config : AgentConfig, provider : Provider, tools : Array[Tool]) -> Agent
```

创建自定义 Agent。

### Agent::run

Defined in `src/autoagent/agent.mbt`.

```moonbit
pub fn Agent::run(self : Agent, goal : String) -> String
```

执行一次 Agent run，并返回最终文本响应。

### Agent::run_trace

Defined in `src/autoagent/agent.mbt`.

```moonbit
pub fn Agent::run_trace(self : Agent, goal : String) -> RunTrace
```

执行一次 Agent run，并返回结构化 trace。

### Planner::plan

Defined in `src/autoagent/planner.mbt`.

```moonbit
pub fn Planner::plan(self : Planner, goal : String) -> Array[Step]
```

将目标转换为步骤数组。

### Tool::execute

Defined in `src/autoagent/tool.mbt`.

```moonbit
pub fn Tool::execute(self : Tool, input : String) -> StepResult
```

执行工具逻辑并返回 `StepResult`。

### Memory::summary

Defined in `src/autoagent/memory.mbt`.

```moonbit
pub fn Memory::summary(self : Memory) -> String
```

将消息数组渲染为文本上下文。

### Memory::new_with_limits

Defined in `src/autoagent/memory.mbt`.

```moonbit
pub fn Memory::new_with_limits(max_messages : Int, max_message_length : Int) -> Memory
```

创建自定义容量限制的 Memory。

### Memory::reset

Defined in `src/autoagent/memory.mbt`.

```moonbit
pub fn Memory::reset(self : Memory) -> Unit
```

重置 Memory，清空所有消息。

### Provider::complete_trace

Defined in `src/autoagent/provider.mbt`.

```moonbit
pub fn Provider::complete_trace(self : Provider, trace : RunTrace) -> String
```

基于结构化 trace 生成最终回答。

## CLI Entry

Defined in `src/main/main.mbt`.

```moonbit
fn main
```

CLI 入口，支持以下参数：

| 参数 | 说明 |
|------|------|
| `[GOAL]` | Agent 目标 |
| `-h, --help` | 显示帮助 |
| `-v, --version` | 显示版本 |
| `-c, --config` | 显示配置 |
| `--max-steps <N>` | 覆盖最大步骤数 |
| `--verbose` | 详细输出 |

运行方式：

```bash
# Run with default goal
moon run src/main

# Run with custom goal
moon run src/main -- "build a chatbot"

# Show help
moon run src/main -- --help
```

## CLI Module

Defined in `src/autoagent/cli.mbt`.

### CliArgs

```moonbit
pub(all) struct CliArgs {
  mut goal : String
  mut show_help : Bool
  mut show_version : Bool
  mut show_config : Bool
  mut max_steps : Int?
  mut verbose : Bool
}
```

### parse_args

```moonbit
pub fn parse_args(args : Array[String]) -> CliArgs
```

解析命令行参数数组，返回 `CliArgs` 结构体。

### show_help / show_version / show_config

```moonbit
pub fn show_help() -> Unit
pub fn show_version() -> Unit
pub fn show_config(config : Config) -> Unit
```

输出帮助、版本或配置信息。

## Config Module

Defined in `src/autoagent/config.mbt`.

### Config

```moonbit
pub(all) struct Config {
  provider : ProviderConfig
  agent : AgentAppConfig
}
```

### ProviderConfig

```moonbit
pub(all) struct ProviderConfig {
  name : String
  api_key : String
  base_url : String
  model : String
  timeout_seconds : Int
}
```

### AgentAppConfig

```moonbit
pub(all) struct AgentAppConfig {
  name : String
  system_prompt : String
  max_steps : Int
  max_goal_length : Int
  max_tool_output_length : Int
}
```

### default_config

```moonbit
pub fn default_config() -> Config
```

返回默认配置。

### Config::to_agent_config

```moonbit
pub fn Config::to_agent_config(self : Config) -> AgentConfig
```

将应用配置转换为 Agent 运行时配置。

### Config::is_deterministic

```moonbit
pub fn Config::is_deterministic(self : Config) -> Bool
```

判断是否为确定性 Provider 模式。

## Test Interface

Defined in `src/autoagent/agent_test.mbt`.

当前测试验证默认 Agent 的输出包含：

- `AutoAgent`
- `scaffold`
- `Checklist`

运行方式：

```bash
# Run tests
PATH="$HOME/.moon/bin:$PATH" moon test
```
