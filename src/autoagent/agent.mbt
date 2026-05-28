///|
pub(all) struct AgentConfig {
  name : String
  system_prompt : String
  max_steps : Int
  max_goal_length : Int
  max_tool_output_length : Int
}

///|
pub(all) struct Agent {
  config : AgentConfig
  planner : Planner
  provider : Provider
  memory : MemoryRouter
  tools : Array[Tool]
  skills : SkillRegistry
}

///|
pub fn Agent::new(
  config : AgentConfig,
  provider : Provider,
  tools : Array[Tool],
) -> Agent {
  {
    config,
    planner: Planner::new(config.max_steps),
    provider,
    memory: MemoryRouter::new(),
    tools,
    skills: SkillRegistry::new(),
  }
}

///|
pub fn Agent::with_skills(
  config : AgentConfig,
  provider : Provider,
  tools : Array[Tool],
  skills : SkillRegistry,
) -> Agent {
  let all_tools : Array[Tool] = []
  for t in tools {
    all_tools.push(t)
  }
  let skill_tools = skills.all_tools()
  for t in skill_tools {
    all_tools.push(t)
  }
  let tool_names : Array[String] = []
  for t in all_tools {
    tool_names.push(t.spec.name)
  }
  let system_prompt = config.system_prompt + "\n\n" + skills.all_instructions()
  {
    config: { ..config, system_prompt },
    planner: Planner::new_with_tools(config.max_steps, tool_names),
    provider,
    memory: MemoryRouter::new(),
    tools: all_tools,
    skills,
  }
}

///|
pub fn Agent::run(self : Agent, goal : String) -> String {
  let trace = self.run_trace(goal)
  trace.answer
}

///|
pub fn Agent::run_single_step(self : Agent, goal : String, step_index : Int) -> RunTrace {
  self.memory.reset_session()
  self.memory.classify_and_store(message(System, self.config.system_prompt))
  self.memory.classify_and_store(message(User, goal))
  if goal.length() > self.config.max_goal_length {
    return { goal, state: Failed, stop_reason: InputTooLong, steps: [], observations: [], answer: "Goal is too long." }
  }
  let steps = self.planner.plan(goal)
  if steps.length() == 0 {
    return { goal, state: Failed, stop_reason: EmptyGoal, steps, observations: [], answer: "No plan generated." }
  }
  if step_index >= steps.length() {
    return { goal, state: Completed, stop_reason: CompletedAllSteps, steps, observations: [], answer: "All steps completed." }
  }
  let s = steps[step_index]
  let observations : Array[String] = []
  let tool_result = self.invoke_step(s)
  match tool_result {
    Success(content) => {
      let rendered = content
      observations.push(rendered)
      self.memory.classify_and_store(message(Tool, rendered))
    }
    Failure(reason) => {
      observations.push("Error: " + reason)
      self.memory.classify_and_store(message(Tool, "Error: " + reason))
      let err_trace = { goal, state: Failed, stop_reason: ToolFailure(s.action), steps, observations, answer: "" }
      let err_answer = self.provider.complete_trace(err_trace)
      return { ..err_trace, answer: err_answer }
    }
  }
  let has_more = step_index + 1 < steps.length()
  let answer = if has_more {
    observations[0] + "\n\nStep " + (step_index + 1).to_string() + "/" + steps.length().to_string() + " done. Continue? (yes/no)"
  } else {
    observations[0] + "\n\nAll steps completed."
  }
  let trace = { goal, state: Running, stop_reason: CompletedAllSteps, steps, observations, answer }
  self.memory.classify_and_store(message(Assistant, answer))
  trace
}

///|
pub fn Agent::run_trace(self : Agent, goal : String) -> RunTrace {
  self.memory.reset_session()
  self.memory.classify_and_store(message(System, self.config.system_prompt))
  self.memory.classify_and_store(message(User, goal))
  if goal.length() > self.config.max_goal_length {
    let trace = {
      goal,
      state: Failed,
      stop_reason: InputTooLong,
      steps: [],
      observations: [],
      answer: "AutoAgent could not run because the goal is too long.",
    }
    self.memory.classify_and_store(message(Assistant, trace.answer))
    return trace
  }
  let steps = self.planner.plan(goal)
  if steps.length() == 0 {
    let trace = {
      goal,
      state: Failed,
      stop_reason: EmptyGoal,
      steps,
      observations: [],
      answer: "AutoAgent could not run because the goal is empty.",
    }
    self.memory.classify_and_store(message(Assistant, trace.answer))
    return trace
  }
  let observations : Array[String] = []
  let mut state = Running
  let mut stop_reason = CompletedAllSteps
  for s in steps {
    let tool_result = self.invoke_step(s)
    match tool_result {
      Success(content) => {
        let rendered = "\{render_step(s)} => \{content}"
        observations.push(rendered)
        self.memory.classify_and_store(message(Tool, rendered))
      }
      Failure(reason) => {
        let rendered = "\{render_step(s)} => \{reason}"
        observations.push(rendered)
        self.memory.classify_and_store(message(Tool, rendered))
        state = Failed
        stop_reason = ToolFailure(s.action)
        break
      }
    }
  }
  if state == Running {
    state = Completed
  }
  let trace = {
    goal,
    state,
    stop_reason,
    steps,
    observations,
    answer: "",
  }
  let answer = self.provider.complete_trace(trace)
  let completed_trace = { ..trace, answer }
  self.memory.classify_and_store(message(Assistant, answer))
  completed_trace
}

///|
fn Agent::invoke_step(self : Agent, s : Step) -> StepResult {
  match find_tool(self.tools, s.action) {
    Some(tool) => {
      if tool.spec.risk == Low {
        let result = self.execute_with_skills(tool, s.input)
        match result {
          Success(content) => {
            if content.length() > self.config.max_tool_output_length {
              Success(content[:][0:self.config.max_tool_output_length].to_owned() + "...[truncated]")
            } else {
              Success(content)
            }
          }
          Failure(reason) => Failure(reason)
        }
      } else {
        Failure("Tool requires approval due to risk level: \{render_risk_level(tool.spec.risk)}")
      }
    }
    None => Failure("No tool registered for action: \{s.action}")
  }
}

///|
fn Agent::execute_with_skills(self : Agent, tool : Tool, input : String) -> StepResult {
  let builtin_result = tool.execute(input)
  match builtin_result {
    Success(_) => builtin_result
    Failure(reason) => {
      if reason.contains("Unknown tool") {
        self.skills.execute_skill_tool(tool.spec.name, input)
      } else {
        builtin_result
      }
    }
  }
}

///|
pub fn default_agent() -> Agent {
  Agent::with_skills(
    {
      name: "AutoAgent",
      system_prompt: "Help users build lightweight agents from scratch and use agents well.",
      max_steps: 3,
      max_goal_length: 1000,
      max_tool_output_length: 500,
    },
    Provider::new("deterministic"),
    [
      Tool::new("scaffold", "Generate a minimal agent skeleton.", "builder", Low),
      Tool::new("checklist", "Generate a safe usage checklist.", "safety", Low),
      Tool::new("coach", "Coach the user through agent operation.", "education", Low),
    ],
    default_skill_registry(),
  )
}
