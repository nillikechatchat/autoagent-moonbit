///|
fn main {
  let args = @env.args()

  if args.length() < 2 {
    show_usage()
    return
  }

  let cmd = args[1]

  if cmd == "--help" || cmd == "-h" {
    show_usage()
    return
  }

  if cmd == "--version" || cmd == "-v" {
    println("AutoAgent v0.2.0")
    return
  }

  if cmd == "--skills" {
    let skills = @autoagent.default_skill_registry()
    println(skills.render_skill_list())
    return
  }

  if cmd == "--skill" && args.length() > 2 {
    let skills = @autoagent.default_skill_registry()
    println(skills.render_skill_detail(args[2]))
    return
  }

  if cmd == "--config" {
    let config = @autoagent.default_config()
    println(@autoagent.render_config(config))
    return
  }

  if cmd == "--json" && args.length() > 2 {
    let input = args[2]
    let action = process_json(input)
    println(action.to_json())
    return
  }

  // Default: treat as goal, output one-shot trace
  let goal = cmd
  let config = @autoagent.default_config()
  let skills = @autoagent.default_skill_registry()
  let agent = @autoagent.Agent::with_skills(
    config.to_agent_config(),
    @autoagent.Provider::new(config.provider.name),
    [
      @autoagent.Tool::new("scaffold", "Generate a minimal agent skeleton.", "builder", Low),
      @autoagent.Tool::new("checklist", "Generate a safe usage checklist.", "safety", Low),
      @autoagent.Tool::new("coach", "Coach the user through agent operation.", "education", Low),
    ],
    skills,
  )
  let trace = agent.run_trace(goal)
  println(trace.answer)
}

///|
fn show_usage() -> Unit {
  println("AutoAgent - MoonBit agent runtime")
  println("")
  println("Usage:")
  println("  autoagent <goal>              Run one-shot with goal")
  println("  autoagent --json <request>    Process JSON request, output JSON action")
  println("  autoagent --skills            List skills")
  println("  autoagent --skill <name>      Show skill detail")
  println("  autoagent --config            Show config")
  println("  autoagent --version           Show version")
  println("")
  println("JSON protocol (--json):")
  println("  Input:  {\"cmd\":\"plan\", \"goal\":\"...\"}")
  println("  Input:  {\"cmd\":\"parse\", \"response\":\"...\", \"conversation\":[...]}")
  println("  Input:  {\"cmd\":\"tool_result\", \"tool\":\"...\", \"result\":\"...\", \"conversation\":[...]}")
  println("  Output: {\"action\":\"think\", \"reason\":\"...\"}")
  println("  Output: {\"action\":\"tool\", \"name\":\"...\", \"input\":\"...\"}")
  println("  Output: {\"action\":\"reply\", \"text\":\"...\"}")
}

///|
fn process_json(input : String) -> @autoagent.AgentAction {
  let cmd = @autoagent.json_field(input, "cmd")

  if cmd == "plan" {
    let goal = @autoagent.json_field(input, "goal")
    if goal == "" {
      return @autoagent.Error("Missing 'goal' field")
    }
    // Plan: return first step as a think action
    let config = @autoagent.default_config()
    let planner = @autoagent.Planner::new(config.agent.max_steps)
    let steps = planner.plan(goal)
    if steps.length() == 0 {
      return @autoagent.Error("Empty plan for goal: " + goal)
    }
    let first = steps[0]
    @autoagent.Think("Step 1/" + steps.length().to_string() + ": " + first.action + " - " + first.reason)
  } else if cmd == "parse" {
    let response = @autoagent.json_field(input, "response")
    if response == "" {
      return @autoagent.Reply("(empty response)")
    }
    // Check for tool call
    if response.contains("```tool") {
      let conv = @autoagent.Conversation::new()
      conv.add("assistant", response)
      match conv.extract_tool_call() {
        Some((name, tool_input)) => @autoagent.CallTool(name, tool_input)
        None => @autoagent.Reply(conv.remove_tool_block())
      }
    } else {
      @autoagent.Reply(response)
    }
  } else if cmd == "tool_result" {
    let tool = @autoagent.json_field(input, "tool")
    let result = @autoagent.json_field(input, "result")
    // Return tool result as a reply to continue the conversation
    @autoagent.Reply("[" + tool + " result]:\n" + result)
  } else {
    @autoagent.Error("Unknown cmd: " + cmd)
  }
}
