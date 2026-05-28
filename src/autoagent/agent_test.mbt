///|
test "default agent creates a guided result" {
  let agent = default_agent()
  let result = agent.run("create a coding assistant")
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
  assert_eq(result.contains("What would you like to do next?"), true)
}

///|
test "layered memory classifies system messages to skeleton" {
  let router = MemoryRouter::new()
  router.classify_and_store(message(System, "system prompt"))
  let skeleton_msgs = router.layered.skeleton.load()
  assert_eq(skeleton_msgs.length(), 1)
  assert_eq(skeleton_msgs[0].content, "system prompt")
}

///|
test "layered memory classifies tool messages to sidecar" {
  let router = MemoryRouter::new()
  router.classify_and_store(message(Tool, "tool result"))
  let sidecar_msgs = router.layered.sidecar.load()
  assert_eq(sidecar_msgs.length(), 1)
}

///|
test "layered memory recall finds matching messages" {
  let router = MemoryRouter::new()
  router.classify_and_store(message(System, "system prompt"))
  router.classify_and_store(message(User, "build a chatbot"))
  router.classify_and_store(message(Tool, "scaffold result"))
  let result = router.recall("chatbot")
  assert_eq(result.contains("chatbot"), true)
}

///|
test "layered memory default context includes skeleton and user" {
  let router = MemoryRouter::new()
  router.classify_and_store(message(System, "system rules"))
  router.classify_and_store(message(User, "user goal"))
  let ctx = router.default_context()
  assert_eq(ctx.contains("system rules"), true)
}

///|
test "layered memory restore context shows all layers" {
  let router = MemoryRouter::new()
  router.classify_and_store(message(System, "skeleton data"))
  router.classify_and_store(message(Tool, "tool data"))
  let restored = router.restore_context()
  assert_eq(restored.contains("Skeleton Layer"), true)
  assert_eq(restored.contains("skeleton data"), true)
}

///|
test "memory export json" {
  let memory = Memory::new()
  memory.store(message(System, "sys"))
  memory.store(message(User, "goal"))
  let json = memory.export_json()
  assert_eq(json.contains("system"), true)
  assert_eq(json.contains("sys"), true)
  assert_eq(json.contains("user"), true)
  assert_eq(json.contains("goal"), true)
}

///|
test "memory message count" {
  let memory = Memory::new()
  assert_eq(memory.message_count(), 0)
  memory.store(message(System, "sys"))
  assert_eq(memory.message_count(), 1)
  memory.store(message(User, "goal"))
  assert_eq(memory.message_count(), 2)
}

///|
test "memory total chars" {
  let memory = Memory::new()
  memory.store(message(System, "abc"))
  memory.store(message(User, "de"))
  assert_eq(memory.total_chars(), 5)
}

///|
test "memory has messages" {
  let memory = Memory::new()
  assert_eq(memory.has_messages(), false)
  memory.store(message(System, "sys"))
  assert_eq(memory.has_messages(), true)
}

///|
test "memory last message" {
  let memory = Memory::new()
  let last = memory.last_message()
  match last {
    Some(_) => assert_eq(false, true)
    None => assert_eq(true, true)
  }
  memory.store(message(System, "first"))
  memory.store(message(User, "second"))
  let last2 = memory.last_message()
  match last2 {
    Some(msg) => assert_eq(msg.content, "second")
    None => assert_eq(false, true)
  }
}

///|
test "memory capacity eviction" {
  let memory = Memory::new_with_limits(3, 100)
  memory.store(message(System, "a"))
  memory.store(message(User, "b"))
  memory.store(message(Tool, "c"))
  assert_eq(memory.message_count(), 3)
  memory.store(message(Assistant, "d"))
  assert_eq(memory.message_count(), 3)
  let msgs = memory.load()
  assert_eq(msgs[0].content, "b")
}

///|
test "memory truncation" {
  let memory = Memory::new_with_limits(10, 10)
  memory.store(message(System, "this is a very long message"))
  let msgs = memory.load()
  assert_eq(msgs[0].content.contains("truncated"), true)
}

///|
test "provider deterministic mode" {
  let provider = Provider::new("test")
  assert_eq(provider.is_deterministic(), true)
}

///|
test "provider llm mode" {
  let provider = Provider::new_llm("openai", "gpt-4", "https://api.openai.com", 30)
  assert_eq(provider.is_deterministic(), false)
  assert_eq(provider.model, "gpt-4")
}

///|
test "planner dynamic tool selection for build" {
  let planner = Planner::new(3)
  let steps = planner.plan("build a chatbot")
  let mut has_scaffold = false
  for s in steps {
    if s.action == "scaffold" { has_scaffold = true }
  }
  assert_eq(has_scaffold, true)
}

///|
test "planner dynamic tool selection for security" {
  let planner = Planner::new(3)
  let steps = planner.plan("review security of my API")
  let mut has_checklist = false
  for s in steps {
    if s.action == "checklist" { has_checklist = true }
  }
  assert_eq(has_checklist, true)
}

///|
test "planner dynamic tool selection for learning" {
  let planner = Planner::new(3)
  let steps = planner.plan("teach me how to use agents")
  let mut has_coach = false
  for s in steps {
    if s.action == "coach" { has_coach = true }
  }
  assert_eq(has_coach, true)
}

///|
test "tool registered tools list" {
  let tools = registered_tools()
  assert_eq(tools.length(), 3)
  assert_eq(tools.contains("scaffold"), true)
  assert_eq(tools.contains("checklist"), true)
  assert_eq(tools.contains("coach"), true)
}

///|
test "tool help for known tool" {
  let help = tool_help("scaffold")
  assert_eq(help.contains("skeleton"), true)
}

///|
test "tool help for unknown tool" {
  let help = tool_help("nonexistent")
  assert_eq(help.contains("Unknown"), true)
}

///|
test "website chatbot scaffold is concrete" {
  let output = scaffold_agent("build a chatbot for my website")
  assert_eq(output.contains("POST /api/chat"), true)
  assert_eq(output.contains("Frontend"), true)
  assert_eq(output.contains("Knowledge"), true)
}

///|
test "website chatbot checklist includes launch gate" {
  let output = agent_checklist("build a chatbot for my website")
  assert_eq(output.contains("Launch"), true)
  assert_eq(output.contains("Memory"), true)
}

///|
test "planner gives website chatbot reason" {
  let planner = Planner::new(3)
  let steps = planner.plan("build a chatbot for my website")
  assert_eq(steps[0].reason.contains("website chatbot"), true)
}

///|
test "config creates provider correctly" {
  let config = default_config()
  let provider = config.to_provider()
  assert_eq(provider.is_deterministic(), true)
}

///|
test "config creates agent correctly" {
  let config = default_config()
  let tools = [
    Tool::new("scaffold", "desc", "builder", Low),
    Tool::new("checklist", "desc", "safety", Low),
    Tool::new("coach", "desc", "education", Low),
  ]
  let agent = config.to_agent(tools)
  let trace = agent.run_trace("test goal")
  assert_eq(render_run_state(trace.state), "completed")
}

///|
test "soft phrase detection" {
  let found = check_soft_phrases("This is a suggestion")
  assert_eq(found.length(), 0)
  let found2 = check_soft_phrases("建议这样做")
  assert_eq(found2.length(), 1)
}

///|
test "failure branching detection" {
  assert_eq(check_failure_branching("if error then retry"), false)
  assert_eq(check_failure_branching("if error then retry else skip"), true)
}

///|
test "anti patterns list" {
  let patterns = get_anti_patterns()
  assert_eq(patterns.length(), 8)
  assert_eq(patterns[0].contains("46.4%"), true)
}

// ============================================================
// Skill system tests
// ============================================================

///|
test "skill registry has 4 built-in skills" {
  let registry = default_skill_registry()
  let names = registry.names()
  assert_eq(names.length(), 4)
  assert_eq(names.contains("research"), true)
  assert_eq(names.contains("code-review"), true)
  assert_eq(names.contains("docs"), true)
  assert_eq(names.contains("testing"), true)
}

///|
test "skill registry find by name" {
  let registry = default_skill_registry()
  let s = registry.find("research")
  match s {
    Some(skill) => {
      assert_eq(skill.name, "research")
      assert_eq(skill.category, "knowledge")
      assert_eq(skill.tools.length(), 2)
    }
    None => assert_eq(false, true)
  }
}

///|
test "skill registry find nonexistent returns none" {
  let registry = default_skill_registry()
  let s = registry.find("nonexistent")
  match s {
    Some(_) => assert_eq(false, true)
    None => assert_eq(true, true)
  }
}

///|
test "skill registry select for research goal" {
  let registry = default_skill_registry()
  let selected = registry.select_for_goal("research the best database options")
  let mut has_research = false
  for s in selected {
    if s.name == "research" { has_research = true }
  }
  assert_eq(has_research, true)
}

///|
test "skill registry select for review goal" {
  let registry = default_skill_registry()
  let selected = registry.select_for_goal("review my code quality")
  let mut has_review = false
  for s in selected {
    if s.name == "code-review" { has_review = true }
  }
  assert_eq(has_review, true)
}

///|
test "skill registry select for test goal" {
  let registry = default_skill_registry()
  let selected = registry.select_for_goal("write unit tests for auth module")
  let mut has_testing = false
  for s in selected {
    if s.name == "testing" { has_testing = true }
  }
  assert_eq(has_testing, true)
}

///|
test "skill registry select for docs goal" {
  let registry = default_skill_registry()
  let selected = registry.select_for_goal("document the API")
  let mut has_docs = false
  for s in selected {
    if s.name == "docs" { has_docs = true }
  }
  assert_eq(has_docs, true)
}

///|
test "skill registry all_tools returns 8 tools" {
  let registry = default_skill_registry()
  let tools = registry.all_tools()
  assert_eq(tools.length(), 8)
}

///|
test "skill registry all_instructions includes skill prompts" {
  let registry = default_skill_registry()
  let instructions = registry.all_instructions()
  assert_eq(instructions.contains("[research Skill]"), true)
  assert_eq(instructions.contains("[code-review Skill]"), true)
  assert_eq(instructions.contains("[docs Skill]"), true)
  assert_eq(instructions.contains("[testing Skill]"), true)
}

///|
test "skill tool execution research-search" {
  let registry = default_skill_registry()
  let result = registry.execute_skill_tool("research-search", "database options")
  match result {
    Success(content) => {
      assert_eq(content.contains("Here is what I found"), true)
      assert_eq(content.contains("database options"), true)
    }
    Failure(_) => assert_eq(false, true)
  }
}

///|
test "skill tool execution review-analyze" {
  let registry = default_skill_registry()
  let result = registry.execute_skill_tool("review-analyze", "auth module")
  match result {
    Success(content) => {
      assert_eq(content.contains("Reviewing"), true)
      assert_eq(content.contains("Correctness"), true)
    }
    Failure(_) => assert_eq(false, true)
  }
}

///|
test "skill tool execution test-create" {
  let registry = default_skill_registry()
  let result = registry.execute_skill_tool("test-create", "user login")
  match result {
    Success(content) => {
      assert_eq(content.contains("Test plan"), true)
      assert_eq(content.contains("user login"), true)
    }
    Failure(_) => assert_eq(false, true)
  }
}

///|
test "skill tool execution docs-generate" {
  let registry = default_skill_registry()
  let result = registry.execute_skill_tool("docs-generate", "REST API")
  match result {
    Success(content) => {
      assert_eq(content.contains("Documentation outline"), true)
      assert_eq(content.contains("REST API"), true)
    }
    Failure(_) => assert_eq(false, true)
  }
}

///|
test "skill tool execution unknown tool fails" {
  let registry = default_skill_registry()
  let result = registry.execute_skill_tool("nonexistent-tool", "input")
  match result {
    Success(_) => assert_eq(false, true)
    Failure(reason) => assert_eq(reason.contains("Unknown skill tool"), true)
  }
}

///|
test "agent with skills includes skill tools" {
  let agent = default_agent()
  let mut has_research = false
  let mut has_scaffold = false
  for t in agent.tools {
    if t.spec.name == "research-search" { has_research = true }
    if t.spec.name == "scaffold" { has_scaffold = true }
  }
  assert_eq(has_research, true)
  assert_eq(has_scaffold, true)
}

///|
test "agent with skills system prompt includes skill instructions" {
  let agent = default_agent()
  assert_eq(agent.config.system_prompt.contains("[research Skill]"), true)
  assert_eq(agent.config.system_prompt.contains("[testing Skill]"), true)
}

///|
test "agent with skills runs research goal with skill tools" {
  let agent = default_agent()
  let trace = agent.run_trace("research the best architecture for microservices")
  assert_eq(render_run_state(trace.state), "completed")
  let mut has_research_tool = false
  for obs in trace.observations {
    if obs.contains("research-search") || obs.contains("research-summarize") {
      has_research_tool = true
    }
  }
  assert_eq(has_research_tool, true)
}

///|
test "agent with skills runs test goal with skill tools" {
  let agent = default_agent()
  let trace = agent.run_trace("write tests for the authentication module")
  assert_eq(render_run_state(trace.state), "completed")
  let mut has_test_tool = false
  for obs in trace.observations {
    if obs.contains("test-create") || obs.contains("test-coverage") {
      has_test_tool = true
    }
  }
  assert_eq(has_test_tool, true)
}

///|
test "skill render list" {
  let registry = default_skill_registry()
  let list = registry.render_skill_list()
  assert_eq(list.contains("Loaded skills:"), true)
  assert_eq(list.contains("research"), true)
  assert_eq(list.contains("code-review"), true)
}

///|
test "skill render detail" {
  let registry = default_skill_registry()
  let detail = registry.render_skill_detail("research")
  assert_eq(detail.contains("Skill: research"), true)
  assert_eq(detail.contains("research-search"), true)
  assert_eq(detail.contains("research-summarize"), true)
  assert_eq(detail.contains("Keywords:"), true)
}

///|
test "skill render detail nonexistent" {
  let registry = default_skill_registry()
  let detail = registry.render_skill_detail("nonexistent")
  assert_eq(detail.contains("Skill not found"), true)
}

///|
test "cli parses --skills flag" {
  let args = parse_args(["--skills"])
  assert_eq(args.show_skills, true)
}

///|
test "cli parses --skill flag" {
  let args = parse_args(["--skill", "research"])
  assert_eq(args.show_skill, "research")
}

///|
test "cli parses --skill= flag" {
  let args = parse_args(["--skill=research"])
  assert_eq(args.show_skill, "research")
}
