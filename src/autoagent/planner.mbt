///|
pub(all) struct Planner {
  max_steps : Int
  available_tools : Array[String]
}

///|
pub fn Planner::new(max_steps : Int) -> Planner {
  { max_steps, available_tools: ["scaffold", "checklist", "coach"] }
}

///|
pub fn Planner::new_with_tools(max_steps : Int, tools : Array[String]) -> Planner {
  { max_steps, available_tools: tools }
}

///|
pub fn Planner::plan(self : Planner, goal : String) -> Array[Step] {
  if goal == "" {
    return []
  }
  let planned : Array[Step] = []
  let mut id = 1
  let used : Array[String] = []

  // Analyze goal keywords to select tools
  let selected = select_tools_for_goal(goal, self.available_tools)
  for tool_name in selected {
    if id <= self.max_steps {
      let reason = get_tool_reason(tool_name, goal)
      planned.push(step(id, tool_name, goal, reason))
      used.push(tool_name)
      id = id + 1
    }
  }

  // Ensure minimum coverage: if no skill tools matched, add default tools
  if planned.length() == 0 {
    for tool_name in self.available_tools {
      if id <= self.max_steps && !used.contains(tool_name) {
        planned.push(step(id, tool_name, goal, "Default step for coverage."))
        id = id + 1
      }
    }
  }

  // If skill tools were selected but defaults are missing, add them if room
  if planned.length() > 0 {
    let defaults = ["scaffold", "checklist", "coach"]
    for d in defaults {
      if id <= self.max_steps && !used.contains(d) && self.available_tools.contains(d) {
        planned.push(step(id, d, goal, get_tool_reason(d, goal)))
        used.push(d)
        id = id + 1
      }
    }
  }

  planned
}

///|
fn select_tools_for_goal(goal : String, available : Array[String]) -> Array[String] {
  let selected : Array[String] = []
  let lower = goal[:].to_lower().to_owned()

  // Always include scaffold for new projects
  if lower.contains("build") || lower.contains("create") || lower.contains("design") || lower.contains("new") {
    if available.contains("scaffold") {
      selected.push("scaffold")
    }
  }

  // Include checklist for safety-critical tasks
  if lower.contains("security") || lower.contains("safe") || lower.contains("check") || lower.contains("test") || lower.contains("review") {
    if available.contains("checklist") && !selected.contains("checklist") {
      selected.push("checklist")
    }
  }

  // Include coach for learning tasks
  if lower.contains("learn") || lower.contains("teach") || lower.contains("how") || lower.contains("guide") || lower.contains("improve") {
    if available.contains("coach") && !selected.contains("coach") {
      selected.push("coach")
    }
  }

  // Research skill tools
  if lower.contains("research") || lower.contains("investigate") || lower.contains("study") || lower.contains("find information") {
    if available.contains("research-search") && !selected.contains("research-search") {
      selected.push("research-search")
    }
    if available.contains("research-summarize") && !selected.contains("research-summarize") {
      selected.push("research-summarize")
    }
  }

  // Code review skill tools
  if lower.contains("review") || lower.contains("refactor") || lower.contains("code quality") || lower.contains("clean code") {
    if available.contains("review-analyze") && !selected.contains("review-analyze") {
      selected.push("review-analyze")
    }
    if available.contains("review-suggest") && !selected.contains("review-suggest") {
      selected.push("review-suggest")
    }
  }

  // Docs skill tools
  if lower.contains("document") || lower.contains("docs") || lower.contains("explain") || lower.contains("readme") || lower.contains("guide") {
    if available.contains("docs-generate") && !selected.contains("docs-generate") {
      selected.push("docs-generate")
    }
    if available.contains("docs-explain") && !selected.contains("docs-explain") {
      selected.push("docs-explain")
    }
  }

  // Testing skill tools
  if lower.contains("test") || lower.contains("coverage") || lower.contains("qa") || lower.contains("tdd") {
    if available.contains("test-create") && !selected.contains("test-create") {
      selected.push("test-create")
    }
    if available.contains("test-coverage") && !selected.contains("test-coverage") {
      selected.push("test-coverage")
    }
  }

  // Ensure scaffold is always included if available
  if !selected.contains("scaffold") && available.contains("scaffold") {
    selected.push("scaffold")
  }

  // Ensure checklist is always included if available and not already added
  if !selected.contains("checklist") && available.contains("checklist") {
    selected.push("checklist")
  }

  // Ensure coach is always included if available and not already added
  if !selected.contains("coach") && available.contains("coach") {
    selected.push("coach")
  }

  selected
}

///|
fn get_tool_reason(tool_name : String, goal : String) -> String {
  let lower = goal[:].to_lower().to_owned()
  if lower.contains("chatbot") && lower.contains("website") {
    match tool_name {
      "scaffold" => return "Setting up the website chatbot architecture."
      "checklist" => return "Defining safety and launch requirements."
      "coach" => return "Planning the iteration workflow."
      _ => ()
    }
  }
  match tool_name {
    "scaffold" => "Setting up the foundation."
    "checklist" => "Defining safety requirements."
    "coach" => "Planning how to iterate."
    "research-search" => "Searching for relevant sources."
    "research-summarize" => "Summarizing findings."
    "review-analyze" => "Analyzing code quality."
    "review-suggest" => "Suggesting improvements."
    "docs-generate" => "Generating documentation outline."
    "docs-explain" => "Explaining the concept."
    "test-create" => "Creating test plan."
    "test-coverage" => "Checking coverage gaps."
    _ => "Running " + tool_name + "."
  }
}

///|
pub fn Planner::available(self : Planner) -> Array[String] {
  self.available_tools
}
