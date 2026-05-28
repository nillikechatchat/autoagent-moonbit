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
    _ => Failure("Unknown tool: \{self.spec.name}. Registered tools: scaffold, checklist, coach")
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
pub fn scaffold_agent(goal : String) -> String {
  if is_website_chatbot_goal(goal) {
    "Here is a plan for '\{goal}':\n\n1. Frontend: floating chat button, message list, input box, mobile layout.\n2. Backend: POST /api/chat with session_id, message, page_url.\n3. Agent: system prompt, tool registry, session memory, stop condition.\n4. Knowledge: start with FAQ markdown, add retrieval later.\n5. Safety: rate limit, max input length, human handoff.\n6. First test: one FAQ question, grounded answer, transcript stored.\n\nStart with step 1 and iterate."
  } else {
    "Here is a plan for '\{goal}':\n\n1. Define the workflow and one acceptance test.\n2. Create agent core, tool registry, memory, and entrypoint.\n3. Add one low-risk tool first.\n4. Store session messages in memory.\n5. Run one dry run, then add the smallest production integration.\n\nStart with step 1."
  }
}

///|
pub fn coach_agent(goal : String) -> String {
  if is_website_chatbot_goal(goal) {
    "How to iterate on '\{goal}':\n\n1. Run init to set up workspace and memory.\n2. Test one visitor question at a time.\n3. Save good answers as experiences.\n4. Promote repeated preferences to user memory.\n5. Add one integration per release: content retrieval, then CRM, then analytics.\n\nTry the first question now."
  } else {
    "How to iterate on '\{goal}':\n\n1. Start with one specific goal.\n2. Run only low-risk tools.\n3. Store useful outcomes in memory.\n4. Turn failures into tests.\n5. Add integrations only after the dry run works.\n\nTry your first goal now."
  }
}

///|
pub fn agent_checklist(goal : String) -> String {
  if is_website_chatbot_goal(goal) {
    "Checklist for '\{goal}':\n\n- Role: answer visitor questions, route unresolved issues.\n- Inputs: message, session_id, page_url.\n- Tools: FAQ search, ticket creation, analytics.\n- Memory: current chat in session, preferences in user layer.\n- Stop: answer delivered, clarification needed, or handoff.\n- Launch: 10 FAQ tests pass, abuse prompts refused."
  } else {
    "Checklist for '\{goal}':\n\n- Define the role and success criteria.\n- Define allowed tools and risk levels.\n- Define memory policy.\n- Define stop conditions.\n- Run one dry run.\n- Add one integration after it passes."
  }
}

///|
fn is_website_chatbot_goal(goal : String) -> Bool {
  let lower = goal[:].to_lower().to_owned()
  lower.contains("chatbot") && (lower.contains("website") || lower.contains("site") || lower.contains("web"))
}

///|
pub fn registered_tools() -> Array[String] {
  ["scaffold", "checklist", "coach"]
}

///|
pub fn tool_help(name : String) -> String {
  match name {
    "scaffold" => "Generates a minimal agent skeleton with file structure and acceptance test guidance."
    "checklist" => "Generates a safe usage checklist for agent development."
    "coach" => "Provides coaching guidance for operating and improving the agent."
    _ => "Unknown tool: " + name
  }
}
