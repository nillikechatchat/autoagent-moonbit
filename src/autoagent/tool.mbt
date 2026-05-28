///|
pub(all) struct Tool {
  spec : ToolSpec
}

///|
pub fn Tool::new(
  name : String,
  description : String,
  category : String,
  risk : RiskLevel,
) -> Tool {
  { spec: { name, description, category, risk } }
}

///|
pub fn Tool::execute(self : Tool, input : String) -> StepResult {
  match self.spec.name {
    "scaffold" => Success(scaffold_agent(input))
    "coach" => Success(coach_agent(input))
    "checklist" => Success(agent_checklist(input))
    _ => Failure("Unknown tool: \{self.spec.name}")
  }
}

///|
pub fn find_tool(tools : Array[Tool], name : String) -> Tool? {
  for tool in tools {
    if tool.spec.name == name {
      return Some(tool)
    }
  }
  None
}

///|
fn scaffold_agent(goal : String) -> String {
  "Create an agent named for '\{goal}' with four files: agent core, provider adapter, tool registry, and memory store. Start with one narrow task, one safe tool, and one acceptance test."
}

///|
fn coach_agent(goal : String) -> String {
  "Use the agent for '\{goal}' by giving one goal, checking the generated plan, approving tool calls, and saving useful outcomes into memory."
}

///|
fn agent_checklist(goal : String) -> String {
  "Checklist for '\{goal}': define role, define allowed tools, define memory policy, define stop condition, run one dry run, then add one production integration."
}
