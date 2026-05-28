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
    "Implementation scaffold for '\{goal}':\n1. Frontend widget: floating chat button, chat panel, message list, input box, loading state, error state, and mobile layout.\n2. Backend API: POST /api/chat with session_id, message, page_url, and optional user_id. Return assistant message, citations, and next_action.\n3. Agent runtime: system prompt, provider adapter, tool allowlist, short-term session memory, user preference memory, and stop condition.\n4. Knowledge source: start with FAQ/content markdown, then add retrieval over indexed website docs.\n5. Safety: rate limit, max input length, low-risk tools by default, no secret echoing, and human handoff for account or payment issues.\n6. First acceptance test: user asks one FAQ, backend returns a grounded answer, frontend renders it, and the transcript is stored."
  } else {
    "Implementation scaffold for '\{goal}':\n1. Define the user-facing workflow and one acceptance test.\n2. Create agent core, provider adapter, tool registry, memory store, and CLI or API entrypoint.\n3. Add one low-risk tool first and block medium/high-risk tools until approval exists.\n4. Store session messages in short-term memory and stable preferences in user memory.\n5. Run one dry run, inspect the trace, then add the smallest production integration."
  }
}

///|
pub fn coach_agent(goal : String) -> String {
  if is_website_chatbot_goal(goal) {
    "Operator workflow for '\{goal}':\n1. Run init to create config, workspace, memory, and session folders.\n2. Start chat mode and test one visitor question at a time.\n3. Save good answers into experience memory and bad answers as regression cases.\n4. Promote repeated visitor preferences into user memory.\n5. Add one integration per release: website content retrieval, CRM handoff, analytics, then admin dashboard."
  } else {
    "Operator workflow for '\{goal}':\n1. Start with one goal and inspect the plan.\n2. Run only low-risk tools automatically.\n3. Store useful outcomes into memory.\n4. Turn repeated failures into tests or checklist items.\n5. Add production integrations only after the dry run is stable."
  }
}

///|
pub fn agent_checklist(goal : String) -> String {
  if is_website_chatbot_goal(goal) {
    "Checklist for '\{goal}':\n- Role: answer website visitor questions and route unresolved issues.\n- Inputs: message, session_id, page_url, locale, and optional user_id.\n- Allowed tools: FAQ retrieval, website search, ticket creation, and analytics logging.\n- Memory policy: sidecar for current chat, user layer for preferences, experiences for validated answers, archive for long transcripts.\n- Stop condition: answer delivered, clarification requested, or handoff created.\n- Launch gate: 10 FAQ tests pass, abuse prompts are refused, and fallback path is visible."
  } else {
    "Checklist for '\{goal}':\n- Define the agent role and success criteria.\n- Define allowed tools and risk levels.\n- Define memory policy and retention.\n- Define stop conditions and failure handling.\n- Run one dry run with trace output.\n- Add one production integration after the dry run passes."
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
