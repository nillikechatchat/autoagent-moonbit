# AutoAgent 使用手册

## 目录

- [快速开始](#快速开始)
- [CLI 用法](#cli-用法)
- [配置文件](#配置文件)
- [理解输出](#理解输出)
- [Agent 配置](#agent-配置)
- [添加自定义工具](#添加自定义工具)
- [替换 Planner](#替换-planner)
- [替换 Provider](#替换-provider)
- [Memory 管理](#memory-管理)
- [安全模型](#安全模型)
- [测试指南](#测试指南)
- [API 速查](#api-速查)
- [故障排查](#故障排查)

---

## 快速开始

### 环境要求

- MoonBit 工具链：`moonc v0.9.3+`、`moon 0.1.20260522+`

### 安装

```bash
# Install MoonBit toolchain on Linux or macOS
curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash

# Verify installation
PATH="$HOME/.moon/bin:$PATH" moon version
```

### 运行

```bash
# Check source code
PATH="$HOME/.moon/bin:$PATH" moon check

# Build project
PATH="$HOME/.moon/bin:$PATH" moon build

# Run tests
PATH="$HOME/.moon/bin:$PATH" moon test

# Initialize workspace
make init

# Start interactive session
make repl
```

### 第一个 Agent

启动交互式 shell：

```bash
make repl
```

输入目标：

```txt
build a chatbot for my website
```

运行后会得到面向目标的实施脚手架、安全检查清单和操作工作流。会话会保存到 `.autoagent/workspace/sessions/`。

---

## CLI 用法

### 命令格式

```bash
moon run src/main -- [OPTIONS] [GOAL]
./scripts/autoagent.sh [init|chat|run]
```

### 参数

| 参数 | 说明 |
|------|------|
| `[GOAL]` | Agent 要完成的目标，支持空格分隔的多个单词 |
| `-h, --help` | 显示帮助信息 |
| `-v, --version` | 显示版本信息 |
| `-c, --config` | 显示当前配置 |
| `--skills` | 列出可用 skills |
| `--skill <NAME>` | 查看 skill 详情 |
| `--max-steps <N>` | 覆盖最大步骤数 |
| `--verbose` | 显示详细 trace 输出 |

### 示例

```bash
# 初始化工作区
./scripts/autoagent.sh init

# 启动交互式会话
./scripts/autoagent.sh chat

# 显示帮助
moon run src/main -- --help

# 显示版本
moon run src/main -- --version

# 显示当前配置
moon run src/main -- --config

# 运行自定义目标
moon run src/main -- "build a chatbot for my website"

# 覆盖最大步骤数
moon run src/main -- --max-steps 5 "plan a database migration"

# 详细输出模式
moon run src/main -- --verbose "create a research assistant"

# 组合使用
moon run src/main -- --verbose --max-steps 2 "design a REST API"
```

### 交互式命令

| 命令 | 说明 |
|------|------|
| `/help` | 显示交互式命令 |
| `/status` | 显示当前工作区、会话和步数 |
| `/config` | 显示运行时配置 |
| `/history` | 输出当前会话日志 |
| `/memory` | 输出记忆文件位置 |
| `/skills` | 列出可用 skills |
| `/skill NAME` | 查看 skill 详情 |
| `/run N` | 调整后续轮次的最大步骤数 |
| `/save TEXT` | 将经验写入 `experiences.md` |
| `/quit` | 退出并保留会话日志 |

### 详细输出模式

使用 `--verbose` 会输出结构化 trace：

```txt
=== AutoAgent Trace ===
Goal: create a research assistant
State: completed
Stop: completed all planned steps
Steps: 3
Observations: 3

=== Answer ===
AutoAgent provider=deterministic
Goal: create a research assistant
...
```

---

## 配置文件

### 配置目录

配置文件位于项目根目录的 `.autoagent/config.json`。

### 配置结构

```json
{
  "provider": {
    "name": "deterministic",
    "api_key": "",
    "base_url": "",
    "model": "",
    "timeout_seconds": 30
  },
  "agent": {
    "name": "AutoAgent",
    "system_prompt": "Help users build lightweight agents from scratch and use agents well.",
    "max_steps": 3,
    "max_goal_length": 1000,
    "max_tool_output_length": 500
  }
}
```

### 配置字段说明

#### provider 配置

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `name` | String | `"deterministic"` | Provider 名称，`"deterministic"` 为本地确定性模式 |
| `api_key` | String | `""` | LLM API 密钥，确定性模式下留空 |
| `base_url` | String | `""` | LLM API 基础 URL |
| `model` | String | `""` | 模型名称，如 `"gpt-4o"`、`"claude-3-sonnet"` |
| `timeout_seconds` | Int | `30` | API 调用超时时间（秒） |

#### agent 配置

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `name` | String | `"AutoAgent"` | Agent 名称 |
| `system_prompt` | String | `"Help users build..."` | 系统提示词 |
| `max_steps` | Int | `3` | 最大步骤数 |
| `max_goal_length` | Int | `1000` | 目标最大长度（字符） |
| `max_tool_output_length` | Int | `500` | 工具输出最大长度（字符） |

### 配置优先级

1. CLI 参数（`--max-steps`）优先级最高。
2. 配置文件 `.autoagent/config.json`。
3. 代码内默认值。

### 查看当前配置

```bash
moon run src/main -- --config
```

输出：

```txt
Config:
  provider.name: deterministic
  provider.model: (none)
  provider.base_url: (none)
  provider.timeout: 30s
  agent.name: AutoAgent
  agent.max_steps: 3
  agent.max_goal_length: 1000
  agent.max_tool_output_length: 500
```

---

## 理解输出

### 输出格式

```txt
AutoAgent provider=deterministic
Goal: build a chatbot that answers FAQ about my product
State: completed
Stop: completed all planned steps
- 1. scaffold: build a chatbot... => Create an agent named for 'build a chatbot...' with four files...
- 2. checklist: build a chatbot... => Checklist for 'build a chatbot...' define role, define allowed tools...
- 3. coach: build a chatbot... => Use the agent for 'build a chatbot...' by giving one goal...
```

### 字段说明

| 字段 | 含义 |
|------|------|
| `provider` | Provider 名称，当前固定为 `deterministic` |
| `Goal` | 用户输入的目标 |
| `State` | 运行状态：`completed`、`failed` |
| `Stop` | 停止原因：`completed all planned steps`、`empty goal`、`input too long`、`tool failure: <name>` |
| `- N. <tool>: <input> => <output>` | 每一步的工具名、输入和输出 |

### 停止原因

| StopReason | 含义 |
|------------|------|
| `completed all planned steps` | 所有计划步骤执行成功 |
| `empty goal` | 用户目标为空 |
| `input too long` | 用户目标超过 `max_goal_length` |
| `tool failure: <name>` | 工具 `<name>` 执行失败，后续步骤已跳过 |

---

## Agent 配置

### AgentConfig 字段

```moonbit
pub(all) struct AgentConfig {
  name : String           // Agent 名称
  system_prompt : String  // 系统提示词
  max_steps : Int         // 最大步骤数
  max_goal_length : Int   // 目标最大长度（字符数）
  max_tool_output_length : Int  // 工具输出最大长度（字符数）
}
```

### 默认配置

```moonbit
{
  name: "AutoAgent",
  system_prompt: "Help users build lightweight agents from scratch and use agents well.",
  max_steps: 3,
  max_goal_length: 1000,
  max_tool_output_length: 500,
}
```

### 自定义配置

```moonbit
let agent = Agent::new(
  {
    name: "MyAgent",
    system_prompt: "You are a customer support agent. Be helpful and concise.",
    max_steps: 5,
    max_goal_length: 2000,
    max_tool_output_length: 1000,
  },
  Provider::new("deterministic"),
  [
    Tool::new("search", "Search knowledge base.", "support", Low),
    Tool::new("reply", "Generate a reply.", "support", Low),
    Tool::new("escalate", "Escalate to human.", "support", Medium),
  ],
)
```

### 配置建议

| 场景 | max_steps | max_goal_length | max_tool_output_length |
|------|-----------|-----------------|------------------------|
| 教学演示 | 3 | 1000 | 500 |
| 客服场景 | 5 | 2000 | 1000 |
| 复杂任务 | 10 | 5000 | 2000 |

---

## 添加自定义工具

### 步骤

1. 在 `src/autoagent/tool.mbt` 的 `Tool::execute` 中新增分支。
2. 实现工具的私有函数。
3. 在 Agent 的工具数组中注册。
4. 在 Planner 中添加对应步骤。
5. 编写测试。

### 示例：添加 `search` 工具

**第一步：实现工具函数**

在 `src/autoagent/tool.mbt` 中添加：

```moonbit
fn search_knowledge(query : String) -> String {
  "Search results for '\{query}': found 3 relevant articles about common questions and setup guides."
}
```

**第二步：注册到 Tool::execute**

```moonbit
pub fn Tool::execute(self : Tool, input : String) -> StepResult {
  match self.spec.name {
    "scaffold" => Success(scaffold_agent(input))
    "coach" => Success(coach_agent(input))
    "checklist" => Success(agent_checklist(input))
    "search" => Success(search_knowledge(input))
    _ => Failure("Unknown tool: \{self.spec.name}")
  }
}
```

**第三步：注册到 Agent**

```moonbit
let agent = Agent::new(
  { name: "SupportAgent", system_prompt: "Help users.", max_steps: 4, max_goal_length: 1000, max_tool_output_length: 500 },
  Provider::new("deterministic"),
  [
    Tool::new("search", "Search knowledge base.", "support", Low),
    Tool::new("scaffold", "Generate a minimal agent skeleton.", "builder", Low),
    Tool::new("checklist", "Generate a safe usage checklist.", "safety", Low),
    Tool::new("coach", "Coach the user through agent operation.", "education", Low),
  ],
)
```

**第四步：添加计划步骤**

在 `src/autoagent/planner.mbt` 中修改 `Planner::plan`：

```moonbit
let base = [
  step(1, "search", goal, "Search for relevant information."),
  step(2, "scaffold", goal, "Create the smallest useful agent skeleton."),
  step(3, "checklist", goal, "Make safe operation explicit before tool growth."),
  step(4, "coach", goal, "Teach the user how to iterate on the agent."),
]
```

**第五步：编写测试**

```moonbit
test "search tool returns results" {
  let tool = Tool::new("search", "Search knowledge base.", "support", Low)
  let result = tool.execute("How to reset password")
  match result {
    Success(content) => assert_eq(content.contains("Search results"), true)
    Failure(_) => assert_eq(false, true)
  }
}
```

### 工具风险等级

| RiskLevel | 行为 | 适用场景 |
|-----------|------|----------|
| `Low` | 自动执行 | 文本生成、查询、建议 |
| `Medium` | 返回需要批准的失败 | 文件写入、API 调用 |
| `High` | 返回需要批准的失败 | 系统命令、数据库操作 |

---

## 替换 Planner

### 当前 Planner

当前 Planner 返回固定三步计划。替换时保持输出类型为 `Array[Step]`。

### 动态 Planner 示例

```moonbit
pub fn Planner::plan(self : Planner, goal : String) -> Array[Step] {
  if goal == "" {
    return []
  }
  let planned : Array[Step] = []
  let mut id = 1

  // 根据目标关键词选择工具
  if goal.contains("search") || goal.contains("find") {
    planned.push(step(id, "search", goal, "Search for relevant information."))
    id = id + 1
  }

  if goal.contains("build") || goal.contains("create") {
    planned.push(step(id, "scaffold", goal, "Create the smallest useful agent skeleton."))
    id = id + 1
  }

  // 默认添加 checklist 和 coach
  if id <= self.max_steps {
    planned.push(step(id, "checklist", goal, "Make safe operation explicit."))
    id = id + 1
  }
  if id <= self.max_steps {
    planned.push(step(id, "coach", goal, "Teach the user how to iterate."))
  }

  planned
}
```

### 约束

- 返回类型必须是 `Array[Step]`。
- 步骤数不应超过 `max_steps`。
- 每个 `Step` 必须包含 `id`、`action`、`input`、`reason`。

---

## 替换 Provider

### 当前 Provider

当前 Provider 是确定性文本拼接，用于测试和教学。

### LLM Provider 设计

接入真实 LLM 时，保持相同输入接口：

```moonbit
pub fn Provider::complete_trace(self : Provider, trace : RunTrace) -> String {
  // 1. 构建 prompt
  let prompt = build_prompt(trace)

  // 2. 调用 LLM API
  let response = call_llm_api(self.api_key, prompt)

  // 3. 处理响应
  match response {
    Ok(answer) => answer
    Err(error) => "Provider error: \{error}"
  }
}

fn build_prompt(trace : RunTrace) -> String {
  let mut prompt = "Goal: \{trace.goal}\n"
  prompt = prompt + "State: \{render_run_state(trace.state)}\n"
  prompt = prompt + "Observations:\n"
  for obs in trace.observations {
    prompt = prompt + "- \{obs}\n"
  }
  prompt = prompt + "Please provide a final answer."
  prompt
}
```

### 建议

- 保留 `Provider::new("deterministic")` 作为测试替身。
- 为 LLM Provider 增加超时和重试策略。
- 避免在测试中依赖真实网络调用。
- 使用 mock provider 测试 Agent 逻辑。

---

## Memory 管理

### 当前能力

```moonbit
// 创建默认 Memory（100 条，2000 字符/条）
let memory = Memory::new()

// 创建自定义 Memory
let memory = Memory::new_with_limits(50, 1000)

// 存储消息
memory.store(message(System, "You are a helpful assistant."))
memory.store(message(User, "How do I reset my password?"))

// 读取消息
let messages = memory.load()

// 生成摘要
let summary = memory.summary()

// 重置
memory.reset()
```

### 容量限制

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `max_messages` | 100 | 最大消息条数，超过时淘汰最早消息 |
| `max_message_length` | 2000 | 单条最大字符数，超过时截断并标记 `...[truncated]` |

### 消息角色

| Role | 用途 |
|------|------|
| `System` | 系统提示词 |
| `User` | 用户目标 |
| `Tool` | 工具执行结果 |
| `Assistant` | Provider 生成的最终回答 |

---

## 安全模型

### 安全基线

1. **工具 Allowlist**：Agent 只能执行注册到 `tools` 数组中的工具。
2. **风险等级检查**：默认只执行 `RiskLevel.Low` 工具。
3. **输入长度限制**：目标超过 `max_goal_length` 时拒绝执行。
4. **输出长度限制**：工具输出超过 `max_tool_output_length` 时截断。
5. **Fail-fast**：工具失败后立即停止后续步骤。
6. **Memory 容量限制**：自动淘汰和截断，防止资源耗尽。

### 扩展安全规则

添加外部执行工具时：

1. 使用 `RiskLevel.Medium` 或 `RiskLevel.High`。
2. 实现 dry-run 模式。
3. 增加人工批准机制。
4. 工具结果写入 Memory 便于审计。
5. 编写安全测试。

---

## 测试指南

### 运行测试

```bash
# Run all tests
PATH="$HOME/.moon/bin:$PATH" moon test

# Run with timing
time PATH="$HOME/.moon/bin:$PATH" moon test
```

### 测试文件

所有测试位于 `src/autoagent/agent_test.mbt`。

### 当前测试覆盖（14 个）

| 测试名称 | 覆盖内容 |
|----------|----------|
| default agent creates a guided result | 默认 Agent 输出包含核心信息 |
| trace exposes state stop reason and observations | RunTrace 结构化数据 |
| empty goal stops before tool execution | 空目标处理 |
| tool specs include category and risk metadata | 工具元数据 |
| planner respects max steps | 步骤数限制 |
| planner returns no steps for empty goal | 空目标规划 |
| memory stores messages in order | 消息顺序 |
| unknown planned tool fails trace | 未知工具失败 |
| agent rejects goals over configured length | 输入长度限制 |
| agent rejects tools above low risk | 风险等级检查 |
| agent stops after first tool failure | Fail-fast |
| agent accepts goal exactly at max length | 边界值 |
| memory summary renders messages in order | 摘要格式 |
| provider complete trace includes state and stop reason | Provider 输出格式 |

### 编写新测试

```moonbit
test "my custom tool works" {
  let tool = Tool::new("mytool", "My custom tool.", "custom", Low)
  let result = tool.execute("test input")
  match result {
    Success(content) => assert_eq(content.contains("expected"), true)
    Failure(reason) => assert_eq(false, true)
  }
}
```

---

## API 速查

### Agent

```moonbit
// 创建 Agent
Agent::new(config : AgentConfig, provider : Provider, tools : Array[Tool]) -> Agent

// 运行 Agent，返回最终文本
Agent::run(self : Agent, goal : String) -> String

// 运行 Agent，返回结构化 trace
Agent::run_trace(self : Agent, goal : String) -> RunTrace

// 获取默认 Agent
default_agent() -> Agent
```

### Tool

```moonbit
// 创建工具
Tool::new(name : String, description : String, category : String, risk : RiskLevel) -> Tool

// 执行工具
Tool::execute(self : Tool, input : String) -> StepResult

// 查找工具
find_tool(tools : Array[Tool], name : String) -> Tool?
```

### Memory

```moonbit
// 创建 Memory
Memory::new() -> Memory
Memory::new_with_limits(max_messages : Int, max_message_length : Int) -> Memory

// 重置
Memory::reset(self : Memory) -> Unit

// 存储
Memory::store(self : Memory, msg : Message) -> Unit

// 读取
Memory::load(self : Memory) -> Array[Message]

// 摘要
Memory::summary(self : Memory) -> String
```

### Provider

```moonbit
// 创建 Provider
Provider::new(name : String) -> Provider

// 生成最终回答
Provider::complete_trace(self : Provider, trace : RunTrace) -> String
```

### Planner

```moonbit
// 创建 Planner
Planner::new(max_steps : Int) -> Planner

// 生成计划
Planner::plan(self : Planner, goal : String) -> Array[Step]
```

### 类型构造

```moonbit
// 创建消息
message(role : Role, content : String) -> Message

// 创建步骤
step(id : Int, action : String, input : String, reason : String) -> Step

// 渲染函数
render_role(role : Role) -> String
render_message(msg : Message) -> String
render_step(s : Step) -> String
render_run_state(state : RunState) -> String
render_stop_reason(reason : StopReason) -> String
render_risk_level(risk : RiskLevel) -> String
```

---

## 故障排查

### moon check 失败

```bash
PATH="$HOME/.moon/bin:$PATH" moon check
```

常见原因：
- 新增 `Agent::new` 时缺少 `max_tool_output_length` 字段。
- `Tool::new` 使用字符串而非 `RiskLevel` 枚举。
- `Provider::complete` 已删除，应使用 `Provider::complete_trace`。

### moon test 失败

```bash
PATH="$HOME/.moon/bin:$PATH" moon test
```

常见原因：
- 工具未注册到 `Tool::execute`。
- Planner 步骤与工具名不匹配。
- 测试断言与实际输出不一致。

### 目标被拒绝

如果看到 `AutoAgent could not run because the goal is too long.`：

- 检查 `max_goal_length` 配置。
- 缩短目标字符串。

### 工具被拒绝

如果看到 `Tool requires approval due to risk level: medium`：

- 将工具风险等级改为 `Low`，或
- 实现人工批准机制。

### 工具失败

如果看到 `tool failure: <name>`：

- 检查工具是否在 `Tool::execute` 中注册。
- 检查工具函数是否返回 `Success`。
- 检查工具名是否与 Planner 中的 `action` 一致。
