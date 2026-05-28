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
  memory : Memory
  tools : Array[Tool]
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
    memory: Memory::new(),
    tools,
  }
}

///|
pub fn Agent::run(self : Agent, goal : String) -> String {
  let trace = self.run_trace(goal)
  trace.answer
}

///|
pub fn Agent::run_trace(self : Agent, goal : String) -> RunTrace {
  self.memory.reset()
  self.memory.store(message(System, self.config.system_prompt))
  self.memory.store(message(User, goal))
  if goal.length() > self.config.max_goal_length {
    let trace = {
      goal,
      state: Failed,
      stop_reason: InputTooLong,
      steps: [],
      observations: [],
      answer: "AutoAgent could not run because the goal is too long.",
    }
    self.memory.store(message(Assistant, trace.answer))
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
    self.memory.store(message(Assistant, trace.answer))
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
        self.memory.store(message(Tool, rendered))
      }
      Failure(reason) => {
        let rendered = "\{render_step(s)} => \{reason}"
        observations.push(rendered)
        self.memory.store(message(Tool, rendered))
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
  self.memory.store(message(Assistant, answer))
  completed_trace
}

///|
fn Agent::invoke_step(self : Agent, s : Step) -> StepResult {
  match find_tool(self.tools, s.action) {
    Some(tool) => {
      if tool.spec.risk == Low {
        let result = tool.execute(s.input)
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
pub fn default_agent() -> Agent {
  Agent::new(
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
  )
}
