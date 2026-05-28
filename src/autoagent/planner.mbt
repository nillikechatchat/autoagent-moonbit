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

  // Ensure minimum coverage
  if planned.length() == 0 {
    for tool_name in self.available_tools {
      if id <= self.max_steps && !used.contains(tool_name) {
        planned.push(step(id, tool_name, goal, "Default step for coverage."))
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
  match tool_name {
    "scaffold" => "Create the smallest useful agent skeleton."
    "checklist" => "Make safe operation explicit before tool growth."
    "coach" => "Teach the user how to iterate on the agent."
    _ => "Execute " + tool_name + " for the goal."
  }
}

///|
pub fn Planner::available(self : Planner) -> Array[String] {
  self.available_tools
}
