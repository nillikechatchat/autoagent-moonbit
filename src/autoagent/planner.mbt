///|
pub(all) struct Planner {
  max_steps : Int
}

///|
pub fn Planner::new(max_steps : Int) -> Planner {
  { max_steps, }
}

///|
pub fn Planner::plan(self : Planner, goal : String) -> Array[Step] {
  if goal == "" {
    return []
  }
  let base = [
    step(1, "scaffold", goal, "Create the smallest useful agent skeleton."),
    step(2, "checklist", goal, "Make safe operation explicit before tool growth."),
    step(3, "coach", goal, "Teach the user how to iterate on the agent."),
  ]
  let planned : Array[Step] = []
  for i, s in base {
    if i < self.max_steps {
      planned.push(s)
    }
  }
  planned
}
