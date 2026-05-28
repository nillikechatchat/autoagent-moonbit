///|
test "default agent creates a guided result" {
  let agent = default_agent()
  let result = agent.run("create a coding assistant")
  assert_eq(result.contains("AutoAgent"), true)
  assert_eq(result.contains("scaffold"), true)
  assert_eq(result.contains("Checklist"), true)
}

///|
test "trace exposes state stop reason and observations" {
  let agent = default_agent()
  let trace = agent.run_trace("create a coding assistant")
  assert_eq(render_run_state(trace.state), "completed")
  assert_eq(render_stop_reason(trace.stop_reason), "completed all planned steps")
  assert_eq(trace.observations.length(), 3)
}

///|
test "empty goal stops before tool execution" {
  let agent = default_agent()
  let trace = agent.run_trace("")
  assert_eq(render_run_state(trace.state), "failed")
  assert_eq(render_stop_reason(trace.stop_reason), "empty goal")
  assert_eq(trace.observations.length(), 0)
}

///|
test "tool specs include category and risk metadata" {
  let tool = Tool::new("demo", "Demo tool", "example", Low)
  assert_eq(tool.spec.category, "example")
  assert_eq(render_risk_level(tool.spec.risk), "low")
}

///|
test "planner respects max steps" {
  let planner = Planner::new(2)
  let steps = planner.plan("create a support agent")
  assert_eq(steps.length(), 2)
  assert_eq(steps[0].action, "scaffold")
  assert_eq(steps[1].action, "checklist")
}

///|
test "planner returns no steps for empty goal" {
  let planner = Planner::new(3)
  let steps = planner.plan("")
  assert_eq(steps.length(), 0)
}

///|
test "memory stores messages in order" {
  let memory = Memory::new()
  memory.store(message(System, "system prompt"))
  memory.store(message(User, "user goal"))
  let messages = memory.load()
  assert_eq(messages.length(), 2)
  assert_eq(render_message(messages[0]), "[system] system prompt")
  assert_eq(render_message(messages[1]), "[user] user goal")
}

///|
test "unknown planned tool fails trace" {
  let agent = Agent::new(
    {
      name: "TestAgent",
      system_prompt: "Test unknown tool handling.",
      max_steps: 1,
      max_goal_length: 1000,
      max_tool_output_length: 500,
    },
    Provider::new("deterministic"),
    [],
  )
  let trace = agent.run_trace("create a support agent")
  assert_eq(render_run_state(trace.state), "failed")
  assert_eq(render_stop_reason(trace.stop_reason), "tool failure: scaffold")
  assert_eq(trace.observations.length(), 1)
  assert_eq(trace.observations[0].contains("No tool registered for action: scaffold"), true)
}

///|
test "agent rejects goals over configured length" {
  let agent = Agent::new(
    {
      name: "TestAgent",
      system_prompt: "Test input length handling.",
      max_steps: 3,
      max_goal_length: 5,
      max_tool_output_length: 500,
    },
    Provider::new("deterministic"),
    [Tool::new("scaffold", "Generate a minimal agent skeleton.", "builder", Low)],
  )
  let trace = agent.run_trace("too long")
  assert_eq(render_run_state(trace.state), "failed")
  assert_eq(render_stop_reason(trace.stop_reason), "input too long")
  assert_eq(trace.observations.length(), 0)
}

///|
test "agent rejects tools above low risk" {
  let agent = Agent::new(
    {
      name: "TestAgent",
      system_prompt: "Test risk handling.",
      max_steps: 1,
      max_goal_length: 1000,
      max_tool_output_length: 500,
    },
    Provider::new("deterministic"),
    [Tool::new("scaffold", "Generate a minimal agent skeleton.", "builder", High)],
  )
  let trace = agent.run_trace("create a support agent")
  assert_eq(render_run_state(trace.state), "failed")
  assert_eq(render_stop_reason(trace.stop_reason), "tool failure: scaffold")
  assert_eq(trace.observations[0].contains("requires approval"), true)
}

///|
test "agent stops after first tool failure" {
  let agent = Agent::new(
    {
      name: "TestAgent",
      system_prompt: "Test fail fast handling.",
      max_steps: 3,
      max_goal_length: 1000,
      max_tool_output_length: 500,
    },
    Provider::new("deterministic"),
    [],
  )
  let trace = agent.run_trace("create a support agent")
  assert_eq(render_run_state(trace.state), "failed")
  assert_eq(trace.observations.length(), 1)
}

///|
test "agent accepts goal exactly at max length" {
  let agent = Agent::new(
    {
      name: "TestAgent",
      system_prompt: "Test boundary handling.",
      max_steps: 1,
      max_goal_length: 5,
      max_tool_output_length: 500,
    },
    Provider::new("deterministic"),
    [Tool::new("scaffold", "Generate a minimal agent skeleton.", "builder", Low)],
  )
  let trace = agent.run_trace("hello")
  assert_eq(render_run_state(trace.state), "completed")
}

///|
test "memory summary renders messages in order" {
  let memory = Memory::new()
  memory.store(message(System, "sys"))
  memory.store(message(User, "goal"))
  let summary = memory.summary()
  assert_eq(summary.contains("[system] sys"), true)
  assert_eq(summary.contains("[user] goal"), true)
  assert_eq(summary.contains("\n"), true)
}

///|
test "provider complete trace includes state and stop reason" {
  let agent = default_agent()
  let trace = agent.run_trace("demo")
  let provider = Provider::new("test")
  let result = provider.complete_trace(trace)
  assert_eq(result.contains("provider=test"), true)
  assert_eq(result.contains("State: completed"), true)
  assert_eq(result.contains("Stop: completed all planned steps"), true)
}
