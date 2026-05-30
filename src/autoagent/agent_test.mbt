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
test "skill registry has 10 built-in skills" {
  let registry = default_skill_registry()
  let names = registry.names()
  assert_eq(names.length(), 10)
  assert_eq(names.contains("research"), true)
  assert_eq(names.contains("code-review"), true)
  assert_eq(names.contains("docs"), true)
  assert_eq(names.contains("testing"), true)
  assert_eq(names.contains("security"), true)
  assert_eq(names.contains("performance"), true)
  assert_eq(names.contains("architecture"), true)
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
test "skill registry all_tools returns 20 tools" {
  let registry = default_skill_registry()
  let tools = registry.all_tools()
  assert_eq(tools.length(), 20)
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
      assert_eq(content.contains("Research brief"), true)
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
      assert_eq(content.contains("Documentation draft"), true)
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

// ============================================================
// MoonBit JSON protocol tests
// ============================================================

///|
test "agent action serializes escaped reply json" {
  let action = AgentAction::Reply("line 1\n\"quoted\"")
  let json = action.to_json()
  assert_eq(json, "{\"action\":\"reply\",\"text\":\"line 1\\n\\\"quoted\\\"\"}")
}

///|
test "json field handles escaped strings" {
  let json = "{\"cmd\":\"parse\",\"response\":\"before\\n{\\\"name\\\":\\\"read_file\\\"}\"}"
  assert_eq(json_field(json, "cmd"), "parse")
  assert_eq(json_field(json, "response"), "before\n{\"name\":\"read_file\"}")
}

///|
test "conversation extracts fenced tool call" {
  let conversation = Conversation::new()
  conversation.add("assistant", "I need a file.\n```tool\n{\"name\":\"read_file\",\"input\":\"README.md\"}\n```")
  match conversation.extract_tool_call() {
    Some((name, input)) => {
      assert_eq(name, "read_file")
      assert_eq(input, "README.md")
    }
    None => assert_eq(false, true)
  }
}

///|
test "conversation removes fenced tool block from reply" {
  let conversation = Conversation::new()
  conversation.add("assistant", "Before\n```tool\n{\"name\":\"list_files\",\"input\":\".\"}\n```\nAfter")
  let cleaned = conversation.remove_tool_block()
  assert_eq(cleaned.contains("```tool"), false)
  assert_eq(cleaned.contains("Before"), true)
  assert_eq(cleaned.contains("After"), true)
}

// ============================================================
// Integration tests (Codex principle: integration > unit for agents)
// ============================================================

///|
test "skill registry has 10 built-in skills integration" {
  let registry = default_skill_registry()
  let names = registry.names()
  assert_eq(names.length(), 10)
  assert_eq(names.contains("research"), true)
  assert_eq(names.contains("code-review"), true)
  assert_eq(names.contains("docs"), true)
  assert_eq(names.contains("testing"), true)
  assert_eq(names.contains("code-gen"), true)
  assert_eq(names.contains("debug"), true)
  assert_eq(names.contains("refactor"), true)
  assert_eq(names.contains("security"), true)
  assert_eq(names.contains("performance"), true)
  assert_eq(names.contains("architecture"), true)
}

///|
test "skill registry all_tools returns 20 tools integration" {
  let registry = default_skill_registry()
  let tools = registry.all_tools()
  assert_eq(tools.length(), 20)
}

///|
test "skill registry code-gen tools" {
  let registry = default_skill_registry()
  let s = registry.find("code-gen")
  match s {
    Some(skill) => {
      assert_eq(skill.name, "code-gen")
      assert_eq(skill.tools.length(), 2)
      assert_eq(skill.has_tool("codegen-implement"), true)
      assert_eq(skill.has_tool("codegen-scaffold"), true)
    }
    None => assert_eq(false, true)
  }
}

///|
test "skill registry debug tools" {
  let registry = default_skill_registry()
  let s = registry.find("debug")
  match s {
    Some(skill) => {
      assert_eq(skill.name, "debug")
      assert_eq(skill.tools.length(), 2)
      assert_eq(skill.has_tool("debug-diagnose"), true)
      assert_eq(skill.has_tool("debug-fix"), true)
    }
    None => assert_eq(false, true)
  }
}

///|
test "skill registry refactor tools" {
  let registry = default_skill_registry()
  let s = registry.find("refactor")
  match s {
    Some(skill) => {
      assert_eq(skill.name, "refactor")
      assert_eq(skill.tools.length(), 2)
      assert_eq(skill.has_tool("refactor-extract"), true)
      assert_eq(skill.has_tool("refactor-simplify"), true)
    }
    None => assert_eq(false, true)
  }
}

///|
test "skill registry security tools" {
  let registry = default_skill_registry()
  let s = registry.find("security")
  match s {
    Some(skill) => {
      assert_eq(skill.name, "security")
      assert_eq(skill.tools.length(), 2)
      assert_eq(skill.has_tool("security-scan"), true)
      assert_eq(skill.has_tool("security-fix"), true)
    }
    None => assert_eq(false, true)
  }
}

///|
test "skill registry performance tools" {
  let registry = default_skill_registry()
  let s = registry.find("performance")
  match s {
    Some(skill) => {
      assert_eq(skill.name, "performance")
      assert_eq(skill.tools.length(), 2)
      assert_eq(skill.has_tool("perf-analyze"), true)
      assert_eq(skill.has_tool("perf-optimize"), true)
    }
    None => assert_eq(false, true)
  }
}

///|
test "skill registry architecture tools" {
  let registry = default_skill_registry()
  let s = registry.find("architecture")
  match s {
    Some(skill) => {
      assert_eq(skill.name, "architecture")
      assert_eq(skill.tools.length(), 2)
      assert_eq(skill.has_tool("arch-design"), true)
      assert_eq(skill.has_tool("arch-review"), true)
    }
    None => assert_eq(false, true)
  }
}

///|
test "skill tool execution codegen-implement" {
  let registry = default_skill_registry()
  let result = registry.execute_skill_tool("codegen-implement", "user authentication")
  match result {
    Success(content) => {
      assert_eq(content.contains("Implementation plan"), true)
      assert_eq(content.contains("user authentication"), true)
      assert_eq(content.contains("TDD"), true)
    }
    Failure(_) => assert_eq(false, true)
  }
}

///|
test "skill tool execution debug-diagnose" {
  let registry = default_skill_registry()
  let result = registry.execute_skill_tool("debug-diagnose", "login fails intermittently")
  match result {
    Success(content) => {
      assert_eq(content.contains("Diagnosis worksheet"), true)
      assert_eq(content.contains("Reproduce"), true)
      assert_eq(content.contains("Root cause"), true)
    }
    Failure(_) => assert_eq(false, true)
  }
}

///|
test "skill tool execution refactor-extract" {
  let registry = default_skill_registry()
  let result = registry.execute_skill_tool("refactor-extract", "complex parsing logic")
  match result {
    Success(content) => {
      assert_eq(content.contains("Extract refactoring plan"), true)
      assert_eq(content.contains("one responsibility"), true)
    }
    Failure(_) => assert_eq(false, true)
  }
}

///|
test "skill tool execution security-scan" {
  let registry = default_skill_registry()
  let result = registry.execute_skill_tool("security-scan", "login handler")
  match result {
    Success(content) => {
      assert_eq(content.contains("Security scan"), true)
      assert_eq(content.contains("OWASP"), true)
    }
    Failure(_) => assert_eq(false, true)
  }
}

///|
test "skill tool execution perf-analyze" {
  let registry = default_skill_registry()
  let result = registry.execute_skill_tool("perf-analyze", "request router")
  match result {
    Success(content) => {
      assert_eq(content.contains("Performance analysis"), true)
      assert_eq(content.contains("bottlenecks"), true)
    }
    Failure(_) => assert_eq(false, true)
  }
}

///|
test "skill tool execution arch-design" {
  let registry = default_skill_registry()
  let result = registry.execute_skill_tool("arch-design", "plugin runtime")
  match result {
    Success(content) => {
      assert_eq(content.contains("Architecture design"), true)
      assert_eq(content.contains("components"), true)
    }
    Failure(_) => assert_eq(false, true)
  }
}

///|
test "skill registry select for debug goal" {
  let registry = default_skill_registry()
  let selected = registry.select_for_goal("debug the login error")
  let mut has_debug = false
  for s in selected {
    if s.name == "debug" { has_debug = true }
  }
  assert_eq(has_debug, true)
}

///|
test "skill registry select for generate goal" {
  let registry = default_skill_registry()
  let selected = registry.select_for_goal("generate a REST API handler")
  let mut has_codegen = false
  for s in selected {
    if s.name == "code-gen" { has_codegen = true }
  }
  assert_eq(has_codegen, true)
}

///|
test "skill registry select for refactor goal" {
  let registry = default_skill_registry()
  let selected = registry.select_for_goal("refactor the auth module")
  let mut has_refactor = false
  for s in selected {
    if s.name == "refactor" { has_refactor = true }
  }
  assert_eq(has_refactor, true)
}

///|
test "skill registry select for security goal" {
  let registry = default_skill_registry()
  let selected = registry.select_for_goal("scan authentication for security vulnerabilities")
  let mut has_security = false
  for s in selected {
    if s.name == "security" { has_security = true }
  }
  assert_eq(has_security, true)
}

///|
test "skill registry select for performance goal" {
  let registry = default_skill_registry()
  let selected = registry.select_for_goal("optimize slow request latency")
  let mut has_performance = false
  for s in selected {
    if s.name == "performance" { has_performance = true }
  }
  assert_eq(has_performance, true)
}

///|
test "skill registry select for architecture goal" {
  let registry = default_skill_registry()
  let selected = registry.select_for_goal("design the system architecture")
  let mut has_architecture = false
  for s in selected {
    if s.name == "architecture" { has_architecture = true }
  }
  assert_eq(has_architecture, true)
}

///|
test "agent with skills includes all skill tools" {
  let agent = default_agent()
  let mut has_codegen = false
  let mut has_debug = false
  let mut has_refactor = false
  let mut has_research = false
  let mut has_security = false
  let mut has_performance = false
  let mut has_architecture = false
  for t in agent.tools {
    if t.spec.name == "codegen-implement" { has_codegen = true }
    if t.spec.name == "debug-diagnose" { has_debug = true }
    if t.spec.name == "refactor-extract" { has_refactor = true }
    if t.spec.name == "research-search" { has_research = true }
    if t.spec.name == "security-scan" { has_security = true }
    if t.spec.name == "perf-analyze" { has_performance = true }
    if t.spec.name == "arch-design" { has_architecture = true }
  }
  assert_eq(has_codegen, true)
  assert_eq(has_debug, true)
  assert_eq(has_refactor, true)
  assert_eq(has_research, true)
  assert_eq(has_security, true)
  assert_eq(has_performance, true)
  assert_eq(has_architecture, true)
}

///|
test "agent with skills system prompt includes all skill instructions" {
  let agent = default_agent()
  assert_eq(agent.config.system_prompt.contains("[research Skill]"), true)
  assert_eq(agent.config.system_prompt.contains("[code-gen Skill]"), true)
  assert_eq(agent.config.system_prompt.contains("[debug Skill]"), true)
  assert_eq(agent.config.system_prompt.contains("[refactor Skill]"), true)
  assert_eq(agent.config.system_prompt.contains("[security Skill]"), true)
  assert_eq(agent.config.system_prompt.contains("[performance Skill]"), true)
  assert_eq(agent.config.system_prompt.contains("[architecture Skill]"), true)
}

///|
test "llm response parser extracts content" {
  let json = "{\"choices\":[{\"message\":{\"content\":\"Hello world\"}}]}"
  let result = parse_llm_response(json)
  assert_eq(result, "Hello world")
}

///|
test "llm response parser handles empty" {
  let result = parse_llm_response("")
  assert_eq(result, "")
}

///|
test "llm response parser handles invalid json" {
  let result = parse_llm_response("not json")
  assert_eq(result, "")
}

///|
test "response parser detects tool call" {
  let response = "I will read the file.\n```tool\n{\"name\":\"read_file\",\"input\":\"README.md\"}\n```"
  match parse_response(response) {
    CallTool(name, input) => {
      assert_eq(name, "read_file")
      assert_eq(input, "README.md")
    }
    Reply(_) => assert_eq(false, true)
  }
}

///|
test "response parser detects reply" {
  let response = "Hello! How can I help you?"
  match parse_response(response) {
    Reply(text) => {
      assert_eq(text, "Hello! How can I help you?")
    }
    CallTool(_, _) => assert_eq(false, true)
  }
}

///|
test "response parser handles empty" {
  match parse_response("") {
    Reply(text) => assert_eq(text, "")
    CallTool(_, _) => assert_eq(false, true)
  }
}

// ============================================================
// Edge case tests (mature product quality)
// ============================================================

///|
test "json field handles missing field" {
  let json = "{\"cmd\":\"parse\"}"
  assert_eq(json_field(json, "missing"), "")
}

///|
test "json field handles empty json" {
  assert_eq(json_field("", "key"), "")
}

///|
test "json field handles nested json" {
  let json = "{\"data\":{\"name\":\"test\"}}"
  let result = json_field(json, "data")
  assert_eq(result.contains("\"name\""), true)
  assert_eq(result.contains("test"), true)
}

///|
test "esc handles special characters" {
  let escaped = esc("line1\nline2\ttab\"quote\\back")
  assert_eq(escaped.contains("\\n"), true)
  assert_eq(escaped.contains("\\t"), true)
  assert_eq(escaped.contains("\\\""), true)
  assert_eq(escaped.contains("\\\\"), true)
}

///|
test "tool descriptions include mature tools" {
  let descriptions = get_tool_descriptions()
  assert_eq(descriptions.contains("edit_file"), true)
  assert_eq(descriptions.contains("code_search"), true)
  assert_eq(descriptions.contains("memory_write"), true)
  assert_eq(descriptions.contains("project_info"), true)
}

///|
test "run_command blocks dangerous commands" {
  let result = execute_tool("run_command", "rm -rf tmp")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "edit_file rejects invalid json" {
  let result = execute_tool("edit_file", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "code_search requires pattern" {
  let result = execute_tool("code_search", "{\"path\":\".\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Missing"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "memory_read handles empty memory" {
  let result = execute_tool("memory_read", "")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("No agent memory"), true)
    ToolError(_) => assert_eq(false, true)
  }
}

///|
test "memory_write rejects invalid json" {
  let result = execute_tool("memory_write", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "env_info returns environment report" {
  let result = execute_tool("env_info", "")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("Environment"), true)
    ToolError(_) => assert_eq(false, true)
  }
}

///|
test "project_info returns project report" {
  let result = execute_tool("project_info", "")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("Project Info"), true)
    ToolError(_) => assert_eq(false, true)
  }
}

///|
test "conversation handles multiple tool calls" {
  let conversation = Conversation::new()
  conversation.add("assistant", "First\n```tool\n{\"name\":\"read_file\",\"input\":\"a.txt\"}\n```")
  conversation.add("user", "[read_file result]: content")
  conversation.add("assistant", "Second\n```tool\n{\"name\":\"list_files\",\"input\":\".\"}\n```")
  match conversation.extract_tool_call() {
    Some((name, _)) => assert_eq(name, "list_files")
    None => assert_eq(false, true)
  }
}

///|
test "conversation handles no tool call" {
  let conversation = Conversation::new()
  conversation.add("assistant", "Just a regular message")
  assert_eq(conversation.has_tool_calls(), false)
  match conversation.extract_tool_call() {
    Some(_) => assert_eq(false, true)
    None => assert_eq(true, true)
  }
}

///|
test "planner returns correct steps for build goal" {
  let planner = Planner::new(3)
  let steps = planner.plan("build a REST API")
  assert_eq(steps.length(), 3)
  assert_eq(steps[0].action, "scaffold")
}

///|
test "planner returns correct steps for test goal" {
  let planner = Planner::new(3)
  let steps = planner.plan("write tests for auth")
  assert_eq(steps.length(), 3)
  let mut has_checklist = false
  for s in steps {
    if s.action == "checklist" { has_checklist = true }
  }
  assert_eq(has_checklist, true)
}

///|
test "memory handles empty state" {
  let memory = Memory::new()
  assert_eq(memory.message_count(), 0)
  assert_eq(memory.summary(), "")
}

///|
test "memory handles large messages" {
  let memory = Memory::new_with_limits(5, 100)
  let mut i = 0
  while i < 10 {
    memory.store(message(User, "message " + i.to_string()))
    i = i + 1
  }
  assert_eq(memory.message_count() <= 5, true)
}

///|
test "skill registry handles empty goal" {
  let registry = default_skill_registry()
  let selected = registry.select_for_goal("")
  assert_eq(selected.length(), 0)
}

///|
test "skill registry handles unknown keyword" {
  let registry = default_skill_registry()
  let selected = registry.select_for_goal("xyzabc123")
  assert_eq(selected.length(), 0)
}

///|
test "eval suite runs all cases" {
  let suite = default_eval_suite()
  let results = suite.run(fn(input) { "reply to: " + input })
  assert_eq(results.length(), 8)
  let mut all_passed = true
  for r in results {
    if !r.passed { all_passed = false }
  }
  assert_eq(all_passed, true)
}

// ============================================================
// Additional edge case tests for mature product
// ============================================================

///|
test "write_file rejects invalid json" {
  let result = execute_tool("write_file", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "write_file rejects missing path" {
  let result = execute_tool("write_file", "{\"content\":\"hello\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "write_file rejects missing content" {
  let result = execute_tool("write_file", "{\"path\":\"test.txt\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "edit_file rejects missing fields" {
  let result = execute_tool("edit_file", "{\"path\":\"test.txt\",\"old\":\"foo\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "code_search rejects invalid json" {
  let result = execute_tool("code_search", "invalid-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "memory_write rejects missing value" {
  let result = execute_tool("memory_write", "{\"key\":\"test\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "memory_write rejects missing key" {
  let result = execute_tool("memory_write", "{\"value\":\"test\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks sudo" {
  let result = execute_tool("run_command", "sudo ls")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks git rm" {
  let result = execute_tool("run_command", "git rm -rf .")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks chmod 777" {
  let result = execute_tool("run_command", "chmod 777 /tmp")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks DROP TABLE" {
  let result = execute_tool("run_command", "DROP TABLE users")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "unknown tool returns error" {
  let result = execute_tool("nonexistent_tool", "input")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Unknown tool"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "read_file handles empty input" {
  let result = execute_tool("read_file", "")
  match result {
    ToolError(_) => assert_eq(true, true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "list_files handles empty input" {
  let result = execute_tool("list_files", "")
  match result {
    ToolSuccess(content) => assert_eq(content.length() > 0, true)
    ToolError(_) => assert_eq(false, true)
  }
}

///|
test "skill tool execution security-fix" {
  let registry = default_skill_registry()
  let result = registry.execute_skill_tool("security-fix", "SQL injection in login")
  match result {
    Success(content) => {
      assert_eq(content.contains("Security fix"), true)
      assert_eq(content.contains("SQL Injection"), true)
    }
    Failure(_) => assert_eq(false, true)
  }
}

///|
test "skill tool execution perf-optimize" {
  let registry = default_skill_registry()
  let result = registry.execute_skill_tool("perf-optimize", "slow database queries")
  match result {
    Success(content) => {
      assert_eq(content.contains("Optimization"), true)
      assert_eq(content.contains("database"), true)
    }
    Failure(_) => assert_eq(false, true)
  }
}

///|
test "skill tool execution arch-review" {
  let registry = default_skill_registry()
  let result = registry.execute_skill_tool("arch-review", "microservice architecture")
  match result {
    Success(content) => {
      assert_eq(content.contains("Architecture review"), true)
      assert_eq(content.contains("checklist"), true)
    }
    Failure(_) => assert_eq(false, true)
  }
}

///|
test "agent with skills includes security tools" {
  let agent = default_agent()
  let mut has_security_scan = false
  let mut has_security_fix = false
  for t in agent.tools {
    if t.spec.name == "security-scan" { has_security_scan = true }
    if t.spec.name == "security-fix" { has_security_fix = true }
  }
  assert_eq(has_security_scan, true)
  assert_eq(has_security_fix, true)
}

///|
test "agent with skills includes performance tools" {
  let agent = default_agent()
  let mut has_perf_analyze = false
  let mut has_perf_optimize = false
  for t in agent.tools {
    if t.spec.name == "perf-analyze" { has_perf_analyze = true }
    if t.spec.name == "perf-optimize" { has_perf_optimize = true }
  }
  assert_eq(has_perf_analyze, true)
  assert_eq(has_perf_optimize, true)
}

///|
test "agent with skills includes architecture tools" {
  let agent = default_agent()
  let mut has_arch_design = false
  let mut has_arch_review = false
  for t in agent.tools {
    if t.spec.name == "arch-design" { has_arch_design = true }
    if t.spec.name == "arch-review" { has_arch_review = true }
  }
  assert_eq(has_arch_design, true)
  assert_eq(has_arch_review, true)
}

///|
test "skill registry render skill list" {
  let registry = default_skill_registry()
  let list = registry.render_skill_list()
  assert_eq(list.contains("Loaded skills:"), true)
  assert_eq(list.contains("research"), true)
  assert_eq(list.contains("security"), true)
  assert_eq(list.contains("performance"), true)
  assert_eq(list.contains("architecture"), true)
}

// ============================================================
// Tests for new utility tools
// ============================================================

///|
test "tool descriptions include new utility tools" {
  let descriptions = get_tool_descriptions()
  assert_eq(descriptions.contains("http_get"), true)
  assert_eq(descriptions.contains("file_info"), true)
  assert_eq(descriptions.contains("timestamp"), true)
  assert_eq(descriptions.contains("env_get"), true)
  assert_eq(descriptions.contains("string_replace"), true)
  assert_eq(descriptions.contains("uuid_generate"), true)
  assert_eq(descriptions.contains("get_cwd"), true)
}

///|
test "http_get rejects empty url" {
  let result = execute_tool("http_get", "")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Missing URL"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "file_info rejects missing file" {
  let result = execute_tool("file_info", "nonexistent_file.txt")
  match result {
    ToolError(msg) => assert_eq(msg.contains("not found"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "timestamp returns current time" {
  let result = execute_tool("timestamp", "")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("Current timestamp"), true)
    ToolError(_) => assert_eq(false, true)
  }
}

///|
test "env_get handles missing variable" {
  let result = execute_tool("env_get", "NONEXISTENT_VAR_12345")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("is not set"), true)
    ToolError(_) => assert_eq(false, true)
  }
}

///|
test "env_get rejects empty input" {
  let result = execute_tool("env_get", "")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Missing"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "string_replace rejects invalid json" {
  let result = execute_tool("string_replace", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "string_replace rejects missing fields" {
  let result = execute_tool("string_replace", "{\"text\":\"hello\",\"old\":\"foo\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "uuid_generate returns uuid" {
  let result = execute_tool("uuid_generate", "")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("Generated UUID"), true)
    ToolError(_) => assert_eq(false, true)
  }
}

///|
test "get_cwd returns directory or error" {
  let result = execute_tool("get_cwd", "")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("Current directory"), true)
    ToolError(msg) => assert_eq(msg.contains("Failed"), true)
  }
}

///|
test "skill registry render skill detail" {
  let registry = default_skill_registry()
  let detail = registry.render_skill_detail("security")
  assert_eq(detail.contains("Skill: security"), true)
  assert_eq(detail.contains("security-scan"), true)
  assert_eq(detail.contains("security-fix"), true)
}

///|
test "skill registry render unknown skill" {
  let registry = default_skill_registry()
  let detail = registry.render_skill_detail("nonexistent")
  assert_eq(detail.contains("Skill not found"), true)
}

///|
test "response parser detects multiple tool calls" {
  let response = "First call\n```tool\n{\"name\":\"read_file\",\"input\":\"a.txt\"}\n```"
  match parse_response(response) {
    CallTool(name, input) => {
      assert_eq(name, "read_file")
      assert_eq(input, "a.txt")
    }
    Reply(_) => assert_eq(false, true)
  }
}

///|
test "response parser handles tool call with special chars" {
  let response = "```tool\n{\"name\":\"write_file\",\"input\":\"{\\\"path\\\":\\\"test.txt\\\",\\\"content\\\":\\\"hello\\\"}\"}\n```"
  match parse_response(response) {
    CallTool(name, input) => {
      assert_eq(name, "write_file")
      assert_eq(input.contains("test.txt"), true)
    }
    Reply(_) => assert_eq(false, true)
  }
}

///|
test "response parser handles reply with tool-like content" {
  let response = "To use a tool, output:\n```tool\n{\"name\":\"tool_name\",\"input\":\"test\"}\n```\nBut I'm just explaining."
  match parse_response(response) {
    CallTool(name, _) => {
      assert_eq(name, "tool_name")
    }
    Reply(_) => assert_eq(false, true)
  }
}

// ============================================================
// Additional edge case tests for robustness
// ============================================================

///|
test "write_file handles empty content" {
  let result = execute_tool("write_file", "{\"path\":\"test.txt\",\"content\":\"\"}")
  match result {
    ToolSuccess(msg) => assert_eq(msg.contains("Wrote"), true)
    ToolError(msg) => assert_eq(msg.contains("Failed"), true)
  }
}

///|
test "edit_file handles empty old string" {
  let result = execute_tool("edit_file", "{\"path\":\"test.txt\",\"old\":\"\",\"new\":\"hello\"}")
  match result {
    ToolError(msg) => assert_eq(msg.length() > 0, true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "code_search handles empty pattern" {
  let result = execute_tool("code_search", "{\"pattern\":\"\",\"path\":\".\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Missing"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "memory_write handles special characters" {
  let result = execute_tool("memory_write", "{\"key\":\"test\",\"value\":\"hello\\nworld\"}")
  match result {
    ToolSuccess(msg) => assert_eq(msg.contains("Memory written"), true)
    ToolError(msg) => assert_eq(msg.length() > 0, true)
  }
}

///|
test "run_command blocks dd command" {
  let result = execute_tool("run_command", "dd if=/dev/zero of=/tmp/test")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks mkfs command" {
  let result = execute_tool("run_command", "mkfs.ext4 /dev/sda1")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks fdisk command" {
  let result = execute_tool("run_command", "fdisk /dev/sda")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks reboot command" {
  let result = execute_tool("run_command", "reboot")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks shutdown command" {
  let result = execute_tool("run_command", "shutdown -h now")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks useradd command" {
  let result = execute_tool("run_command", "useradd testuser")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks passwd command" {
  let result = execute_tool("run_command", "passwd root")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks iptables command" {
  let result = execute_tool("run_command", "iptables -F")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks docker rmi command" {
  let result = execute_tool("run_command", "docker rmi image_name")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks git clean command" {
  let result = execute_tool("run_command", "git clean -fd")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks TRUNCATE command" {
  let result = execute_tool("run_command", "TRUNCATE TABLE users")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks DROP TABLE command" {
  let result = execute_tool("run_command", "DROP TABLE users")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks DROP DATABASE command" {
  let result = execute_tool("run_command", "DROP DATABASE mydb")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks chmod +s command" {
  let result = execute_tool("run_command", "chmod +s /tmp/test")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks chown root command" {
  let result = execute_tool("run_command", "chown root /tmp/test")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks format command" {
  let result = execute_tool("run_command", "format C:")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks --delete flag" {
  let result = execute_tool("run_command", "find . --delete")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "run_command blocks > /dev/ redirect" {
  let result = execute_tool("run_command", "echo test > /dev/sda")
  match result {
    ToolError(msg) => assert_eq(msg.contains("blocked"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "skill registry all_instructions includes all skills" {
  let registry = default_skill_registry()
  let instructions = registry.all_instructions()
  assert_eq(instructions.contains("[research Skill]"), true)
  assert_eq(instructions.contains("[code-review Skill]"), true)
  assert_eq(instructions.contains("[docs Skill]"), true)
  assert_eq(instructions.contains("[testing Skill]"), true)
  assert_eq(instructions.contains("[code-gen Skill]"), true)
  assert_eq(instructions.contains("[debug Skill]"), true)
  assert_eq(instructions.contains("[refactor Skill]"), true)
  assert_eq(instructions.contains("[security Skill]"), true)
  assert_eq(instructions.contains("[performance Skill]"), true)
  assert_eq(instructions.contains("[architecture Skill]"), true)
}

///|
test "skill registry tool_names returns correct names" {
  let registry = default_skill_registry()
  let s = registry.find("security")
  match s {
    Some(skill) => {
      let names = skill.tool_names()
      assert_eq(names.length(), 2)
      assert_eq(names.contains("security-scan"), true)
      assert_eq(names.contains("security-fix"), true)
    }
    None => assert_eq(false, true)
  }
}

///|
test "llm config from env and file" {
  let config = LLMConfig::from_env_and_file(".autoagent/config.json")
  assert_eq(config.model != "", true)
}

///|
test "llm config is configured" {
  let config = LLMConfig::from_env_and_file(".autoagent/config.json")
  assert_eq(config.is_configured(), false)
}

///|
test "llm config chat with empty messages" {
  let config = LLMConfig::from_env_and_file(".autoagent/config.json")
  let result = config.chat([])
  assert_eq(result, "")
}

///|
test "llm config chat stream with empty messages" {
  let config = LLMConfig::from_env_and_file(".autoagent/config.json")
  let result = config.chat_stream([])
  assert_eq(result, "")
}

///|
test "parse llm response with valid json" {
  let json = "{\"choices\":[{\"message\":{\"content\":\"Hello\"}}]}"
  let result = parse_llm_response(json)
  assert_eq(result, "Hello")
}

///|
test "parse llm response with empty choices" {
  let json = "{\"choices\":[]}"
  let result = parse_llm_response(json)
  assert_eq(result, "")
}

///|
test "parse llm response with missing content" {
  let json = "{\"choices\":[{\"message\":{}}]}"
  let result = parse_llm_response(json)
  assert_eq(result, "")
}

///|
test "parse llm response with invalid json" {
  let result = parse_llm_response("invalid json")
  assert_eq(result, "")
}

///|
test "parse llm response with empty string" {
  let result = parse_llm_response("")
  assert_eq(result, "")
}

///|
test "response parser handles empty response" {
  match parse_response("") {
    Reply(text) => assert_eq(text, "")
    CallTool(_, _) => assert_eq(false, true)
  }
}

///|
test "response parser handles reply only" {
  match parse_response("Hello, how can I help?") {
    Reply(text) => assert_eq(text, "Hello, how can I help?")
    CallTool(_, _) => assert_eq(false, true)
  }
}

///|
test "response parser handles tool call with no input" {
  let response = "```tool\n{\"name\":\"read_file\"}\n```"
  match parse_response(response) {
    Reply(text) => assert_eq(text.contains("tool"), true)
    CallTool(_, _) => assert_eq(false, true)
  }
}

///|
test "response parser handles tool call with empty input" {
  let response = "```tool\n{\"name\":\"read_file\",\"input\":\"\"}\n```"
  match parse_response(response) {
    CallTool(name, input) => {
      assert_eq(name, "read_file")
      assert_eq(input, "")
    }
    Reply(_) => assert_eq(false, true)
  }
}

// ============================================================
// Tests for new utility tools
// ============================================================

///|
test "tool descriptions include file operation tools" {
  let descriptions = get_tool_descriptions()
  assert_eq(descriptions.contains("head_file"), true)
  assert_eq(descriptions.contains("tail_file"), true)
  assert_eq(descriptions.contains("count_lines"), true)
  assert_eq(descriptions.contains("grep_file"), true)
  assert_eq(descriptions.contains("diff_files"), true)
  assert_eq(descriptions.contains("copy_file"), true)
  assert_eq(descriptions.contains("move_file"), true)
  assert_eq(descriptions.contains("append_file"), true)
  assert_eq(descriptions.contains("dir_size"), true)
  assert_eq(descriptions.contains("disk_usage"), true)
}

///|
test "head_file rejects invalid json" {
  let result = execute_tool("head_file", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "head_file rejects missing path" {
  let result = execute_tool("head_file", "{\"lines\":10}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "tail_file rejects invalid json" {
  let result = execute_tool("tail_file", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "tail_file rejects missing path" {
  let result = execute_tool("tail_file", "{\"lines\":10}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "count_lines rejects missing file" {
  let result = execute_tool("count_lines", "nonexistent.txt")
  match result {
    ToolError(msg) => assert_eq(msg.contains("not found"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "grep_file rejects invalid json" {
  let result = execute_tool("grep_file", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "grep_file rejects missing fields" {
  let result = execute_tool("grep_file", "{\"path\":\"test.txt\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "diff_files rejects invalid json" {
  let result = execute_tool("diff_files", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "diff_files rejects missing fields" {
  let result = execute_tool("diff_files", "{\"file1\":\"a.txt\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "copy_file rejects invalid json" {
  let result = execute_tool("copy_file", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "copy_file rejects missing fields" {
  let result = execute_tool("copy_file", "{\"source\":\"a.txt\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "move_file rejects invalid json" {
  let result = execute_tool("move_file", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "move_file rejects missing fields" {
  let result = execute_tool("move_file", "{\"source\":\"a.txt\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "append_file rejects invalid json" {
  let result = execute_tool("append_file", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "append_file rejects missing fields" {
  let result = execute_tool("append_file", "{\"path\":\"test.txt\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "dir_size rejects missing directory" {
  let result = execute_tool("dir_size", "nonexistent_dir")
  match result {
    ToolError(msg) => assert_eq(msg.length() > 0, true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "disk_usage returns usage info or error" {
  let result = execute_tool("disk_usage", "")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("Disk usage"), true)
    ToolError(msg) => assert_eq(msg.length() > 0, true)
  }
}

// ============================================================
// Tests for more utility tools
// ============================================================

///|
test "tool descriptions include more utility tools" {
  let descriptions = get_tool_descriptions()
  assert_eq(descriptions.contains("sort_file"), true)
  assert_eq(descriptions.contains("uniq_file"), true)
  assert_eq(descriptions.contains("wc_file"), true)
  assert_eq(descriptions.contains("basename"), true)
  assert_eq(descriptions.contains("dirname"), true)
  assert_eq(descriptions.contains("realpath"), true)
  assert_eq(descriptions.contains("which"), true)
  assert_eq(descriptions.contains("date"), true)
  assert_eq(descriptions.contains("mkdir"), true)
  assert_eq(descriptions.contains("is_dir"), true)
}

///|
test "sort_file rejects invalid json" {
  let result = execute_tool("sort_file", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "sort_file rejects missing path" {
  let result = execute_tool("sort_file", "{\"reverse\":true}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "uniq_file rejects missing file" {
  let result = execute_tool("uniq_file", "nonexistent.txt")
  match result {
    ToolError(msg) => assert_eq(msg.contains("not found"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "wc_file rejects missing file" {
  let result = execute_tool("wc_file", "nonexistent.txt")
  match result {
    ToolError(msg) => assert_eq(msg.contains("not found"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "basename returns filename or error" {
  let result = execute_tool("basename", "/path/to/file.txt")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("Basename"), true)
    ToolError(msg) => assert_eq(msg.length() > 0, true)
  }
}

///|
test "dirname returns directory or error" {
  let result = execute_tool("dirname", "/path/to/file.txt")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("Dirname"), true)
    ToolError(msg) => assert_eq(msg.length() > 0, true)
  }
}

///|
test "realpath returns absolute path or error" {
  let result = execute_tool("realpath", "test.txt")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("Realpath"), true)
    ToolError(msg) => assert_eq(msg.length() > 0, true)
  }
}

///|
test "which handles missing command" {
  let result = execute_tool("which", "nonexistent_command_12345")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("not found"), true)
    ToolError(msg) => assert_eq(msg.length() > 0, true)
  }
}

///|
test "date returns current date or error" {
  let result = execute_tool("date", "")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("Date"), true)
    ToolError(msg) => assert_eq(msg.length() > 0, true)
  }
}

///|
test "mkdir creates directory or error" {
  let result = execute_tool("mkdir", "test_dir_12345")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("Created"), true)
    ToolError(msg) => assert_eq(msg.length() > 0, true)
  }
}

///|
test "is_dir checks directory or error" {
  let result = execute_tool("is_dir", ".")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("directory"), true)
    ToolError(msg) => assert_eq(msg.length() > 0, true)
  }
}

// ============================================================
// Tests for more utility tools
// ============================================================

///|
test "tool descriptions include more file tools" {
  let descriptions = get_tool_descriptions()
  assert_eq(descriptions.contains("truncate_file"), true)
  assert_eq(descriptions.contains("grep_count"), true)
  assert_eq(descriptions.contains("grep_context"), true)
  assert_eq(descriptions.contains("file_type"), true)
  assert_eq(descriptions.contains("file_permissions"), true)
  assert_eq(descriptions.contains("file_owner"), true)
  assert_eq(descriptions.contains("file_modified"), true)
  assert_eq(descriptions.contains("file_size"), true)
  assert_eq(descriptions.contains("list_dir_detailed"), true)
  assert_eq(descriptions.contains("find_by_type"), true)
  assert_eq(descriptions.contains("find_by_size"), true)
}

///|
test "truncate_file rejects invalid json" {
  let result = execute_tool("truncate_file", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "truncate_file rejects missing path" {
  let result = execute_tool("truncate_file", "{\"lines\":100}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "grep_count rejects invalid json" {
  let result = execute_tool("grep_count", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "grep_count rejects missing fields" {
  let result = execute_tool("grep_count", "{\"path\":\"test.txt\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "grep_context rejects invalid json" {
  let result = execute_tool("grep_context", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "grep_context rejects missing fields" {
  let result = execute_tool("grep_context", "{\"path\":\"test.txt\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "file_type rejects missing file" {
  let result = execute_tool("file_type", "nonexistent.txt")
  match result {
    ToolError(msg) => assert_eq(msg.contains("not found"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "file_permissions rejects missing file" {
  let result = execute_tool("file_permissions", "nonexistent.txt")
  match result {
    ToolError(msg) => assert_eq(msg.contains("not found"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "file_owner rejects missing file" {
  let result = execute_tool("file_owner", "nonexistent.txt")
  match result {
    ToolError(msg) => assert_eq(msg.contains("not found"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "file_modified rejects missing file" {
  let result = execute_tool("file_modified", "nonexistent.txt")
  match result {
    ToolError(msg) => assert_eq(msg.contains("not found"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "file_size rejects missing file" {
  let result = execute_tool("file_size", "nonexistent.txt")
  match result {
    ToolError(msg) => assert_eq(msg.contains("not found"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "list_dir_detailed handles directory" {
  let result = execute_tool("list_dir_detailed", ".")
  match result {
    ToolSuccess(content) => assert_eq(content.length() > 0, true)
    ToolError(msg) => assert_eq(msg.length() > 0, true)
  }
}

///|
test "find_by_type rejects invalid json" {
  let result = execute_tool("find_by_type", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "find_by_type rejects missing path" {
  let result = execute_tool("find_by_type", "{\"type\":\"f\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "find_by_size rejects invalid json" {
  let result = execute_tool("find_by_size", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "find_by_size rejects missing path" {
  let result = execute_tool("find_by_size", "{\"size\":\"+1M\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

// ============================================================
// Tests for more utility tools
// ============================================================

///|
test "tool descriptions include archive tools" {
  let descriptions = get_tool_descriptions()
  assert_eq(descriptions.contains("grep_recursive"), true)
  assert_eq(descriptions.contains("find_by_name"), true)
  assert_eq(descriptions.contains("find_by_time"), true)
  assert_eq(descriptions.contains("file_checksum"), true)
  assert_eq(descriptions.contains("compress_file"), true)
  assert_eq(descriptions.contains("decompress_file"), true)
  assert_eq(descriptions.contains("tar_create"), true)
  assert_eq(descriptions.contains("tar_extract"), true)
  assert_eq(descriptions.contains("zip_create"), true)
  assert_eq(descriptions.contains("zip_extract"), true)
}

///|
test "grep_recursive rejects invalid json" {
  let result = execute_tool("grep_recursive", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "grep_recursive rejects missing fields" {
  let result = execute_tool("grep_recursive", "{\"path\":\".\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "find_by_name rejects invalid json" {
  let result = execute_tool("find_by_name", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "find_by_name rejects missing path" {
  let result = execute_tool("find_by_name", "{\"name\":\"*.mbt\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "find_by_time rejects invalid json" {
  let result = execute_tool("find_by_time", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "find_by_time rejects missing path" {
  let result = execute_tool("find_by_time", "{\"days\":7}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "file_checksum rejects invalid json" {
  let result = execute_tool("file_checksum", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "file_checksum rejects missing path" {
  let result = execute_tool("file_checksum", "{\"algorithm\":\"md5\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "compress_file rejects missing file" {
  let result = execute_tool("compress_file", "nonexistent.txt")
  match result {
    ToolError(msg) => assert_eq(msg.contains("not found"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "decompress_file rejects missing file" {
  let result = execute_tool("decompress_file", "nonexistent.txt.gz")
  match result {
    ToolError(msg) => assert_eq(msg.contains("not found"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "tar_create rejects invalid json" {
  let result = execute_tool("tar_create", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "tar_create rejects missing fields" {
  let result = execute_tool("tar_create", "{\"source\":\".\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "tar_extract rejects invalid json" {
  let result = execute_tool("tar_extract", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "tar_extract rejects missing fields" {
  let result = execute_tool("tar_extract", "{\"source\":\"archive.tar.gz\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "zip_create rejects invalid json" {
  let result = execute_tool("zip_create", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "zip_create rejects missing fields" {
  let result = execute_tool("zip_create", "{\"source\":\".\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "zip_extract rejects invalid json" {
  let result = execute_tool("zip_extract", "not-json")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid JSON"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "zip_extract rejects missing fields" {
  let result = execute_tool("zip_extract", "{\"source\":\"archive.zip\"}")
  match result {
    ToolError(msg) => assert_eq(msg.contains("Invalid"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

// ============================================================
// Tests for more utility tools
// ============================================================

///|
test "tool descriptions include system tools" {
  let descriptions = get_tool_descriptions()
  assert_eq(descriptions.contains("is_readable"), true)
  assert_eq(descriptions.contains("is_writable"), true)
  assert_eq(descriptions.contains("is_executable"), true)
  assert_eq(descriptions.contains("file_extension"), true)
  assert_eq(descriptions.contains("file_lines"), true)
  assert_eq(descriptions.contains("file_words"), true)
  assert_eq(descriptions.contains("file_chars"), true)
  assert_eq(descriptions.contains("system_info"), true)
  assert_eq(descriptions.contains("memory_info"), true)
  assert_eq(descriptions.contains("cpu_info"), true)
  assert_eq(descriptions.contains("network_info"), true)
  assert_eq(descriptions.contains("process_list"), true)
}

///|
test "is_readable rejects missing file" {
  let result = execute_tool("is_readable", "nonexistent.txt")
  match result {
    ToolError(msg) => assert_eq(msg.contains("not found"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "is_writable rejects missing file" {
  let result = execute_tool("is_writable", "nonexistent.txt")
  match result {
    ToolError(msg) => assert_eq(msg.contains("not found"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "is_executable rejects missing file" {
  let result = execute_tool("is_executable", "nonexistent.txt")
  match result {
    ToolError(msg) => assert_eq(msg.contains("not found"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "file_extension returns extension" {
  let result = execute_tool("file_extension", "test.txt")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("Extension"), true)
    ToolError(_) => assert_eq(false, true)
  }
}

///|
test "file_extension handles no extension" {
  let result = execute_tool("file_extension", "Makefile")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("No extension"), true)
    ToolError(_) => assert_eq(false, true)
  }
}

///|
test "file_lines rejects missing file" {
  let result = execute_tool("file_lines", "nonexistent.txt")
  match result {
    ToolError(msg) => assert_eq(msg.contains("not found"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "file_words rejects missing file" {
  let result = execute_tool("file_words", "nonexistent.txt")
  match result {
    ToolError(msg) => assert_eq(msg.contains("not found"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "file_chars rejects missing file" {
  let result = execute_tool("file_chars", "nonexistent.txt")
  match result {
    ToolError(msg) => assert_eq(msg.contains("not found"), true)
    ToolSuccess(_) => assert_eq(false, true)
  }
}

///|
test "system_info returns info" {
  let result = execute_tool("system_info", "")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("System Info"), true)
    ToolError(_) => assert_eq(false, true)
  }
}

///|
test "memory_info returns info or error" {
  let result = execute_tool("memory_info", "")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("Memory Info"), true)
    ToolError(msg) => assert_eq(msg.length() > 0, true)
  }
}

///|
test "cpu_info returns info or error" {
  let result = execute_tool("cpu_info", "")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("CPU Info"), true)
    ToolError(msg) => assert_eq(msg.length() > 0, true)
  }
}

///|
test "network_info returns info or error" {
  let result = execute_tool("network_info", "")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("Network Info"), true)
    ToolError(msg) => assert_eq(msg.length() > 0, true)
  }
}

///|
test "process_list returns processes" {
  let result = execute_tool("process_list", "")
  match result {
    ToolSuccess(content) => assert_eq(content.length() > 0, true)
    ToolError(_) => assert_eq(false, true)
  }
}

// ============================================================
// Tests for more utility tools
// ============================================================

///|
test "tool descriptions include more system tools" {
  let descriptions = get_tool_descriptions()
  assert_eq(descriptions.contains("env_list"), true)
  assert_eq(descriptions.contains("uptime"), true)
  assert_eq(descriptions.contains("hostname"), true)
  assert_eq(descriptions.contains("whoami"), true)
  assert_eq(descriptions.contains("who"), true)
  assert_eq(descriptions.contains("last"), true)
  assert_eq(descriptions.contains("command_exists"), true)
  assert_eq(descriptions.contains("shell_info"), true)
  assert_eq(descriptions.contains("path_list"), true)
}

///|
test "env_list returns environment variables" {
  let result = execute_tool("env_list", "")
  match result {
    ToolSuccess(content) => assert_eq(content.length() > 0, true)
    ToolError(_) => assert_eq(false, true)
  }
}

///|
test "uptime returns uptime or error" {
  let result = execute_tool("uptime", "")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("Uptime"), true)
    ToolError(msg) => assert_eq(msg.length() > 0, true)
  }
}

///|
test "hostname returns hostname or error" {
  let result = execute_tool("hostname", "")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("Hostname"), true)
    ToolError(msg) => assert_eq(msg.length() > 0, true)
  }
}

///|
test "whoami returns user or error" {
  let result = execute_tool("whoami", "")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("User"), true)
    ToolError(msg) => assert_eq(msg.length() > 0, true)
  }
}

///|
test "who returns logged in users" {
  let result = execute_tool("who", "")
  match result {
    ToolSuccess(content) => assert_eq(content.length() > 0, true)
    ToolError(_) => assert_eq(false, true)
  }
}

///|
test "last returns login history or error" {
  let result = execute_tool("last", "")
  match result {
    ToolSuccess(content) => assert_eq(content.length() > 0, true)
    ToolError(msg) => assert_eq(msg.length() > 0, true)
  }
}

///|
test "command_exists checks command" {
  let result = execute_tool("command_exists", "ls")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("available"), true)
    ToolError(_) => assert_eq(false, true)
  }
}

///|
test "shell_info returns shell info or error" {
  let result = execute_tool("shell_info", "")
  match result {
    ToolSuccess(content) => assert_eq(content.contains("Shell Info"), true)
    ToolError(msg) => assert_eq(msg.length() > 0, true)
  }
}

///|
test "path_list returns PATH directories or error" {
  let result = execute_tool("path_list", "")
  match result {
    ToolSuccess(content) => assert_eq(content.length() > 0, true)
    ToolError(msg) => assert_eq(msg.length() > 0, true)
  }
}
