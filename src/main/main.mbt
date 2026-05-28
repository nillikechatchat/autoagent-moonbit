///|
fn main {
  let args = @env.args()
  let user_args = if args.length() > 1 {
    args[1:].map(fn(x) { x })
  } else {
    []
  }
  let cli = @autoagent.parse_args(user_args)

  if cli.show_help {
    @autoagent.show_help()
    return
  }

  if cli.show_version {
    @autoagent.show_version()
    return
  }

  let config = @autoagent.default_config()

  if cli.show_config {
    @autoagent.show_config(config)
    return
  }

  let skills = @autoagent.default_skill_registry()

  if cli.show_skills {
    println(skills.render_skill_list())
    return
  }

  if cli.show_skill != "" {
    println(skills.render_skill_detail(cli.show_skill))
    return
  }

  if cli.goal == "" {
    println(@autoagent.banner())
    println(@autoagent.info("Ready. Type a message or goal:"))
    println("")
    println("  Examples:")
    println("  > build a chatbot for my website")
    println("  > research the best database for my project")
    println("  > write tests for my auth module")
    println("")
    println("  Or use the interactive shell:")
    println("  make repl")
    println("  ./scripts/autoagent.sh")
    return
  }

  let goal = cli.goal

  let agent_config = match cli.max_steps {
    Some(steps) => {
      let c = config.to_agent_config()
      { ..c, max_steps: steps }
    }
    None => config.to_agent_config()
  }

  let agent = @autoagent.Agent::with_skills(
    agent_config,
    @autoagent.Provider::new(config.provider.name),
    [
      @autoagent.Tool::new("scaffold", "Generate a minimal agent skeleton.", "builder", Low),
      @autoagent.Tool::new("checklist", "Generate a safe usage checklist.", "safety", Low),
      @autoagent.Tool::new("coach", "Coach the user through agent operation.", "education", Low),
    ],
    @autoagent.default_skill_registry(),
  )

  if cli.verbose {
    println(@autoagent.banner())
    println(@autoagent.info("Running in verbose mode..."))
    println(@autoagent.divider())
    let trace = agent.run_trace(goal)
    println(@autoagent.format_trace(trace))
    println(@autoagent.format_answer(trace.answer))
    println(@autoagent.divider())
    println(@autoagent.format_run_summary(trace))
  } else {
    let trace = match cli.step {
      Some(step_num) => agent.run_single_step(goal, step_num)
      None => agent.run_trace(goal)
    }
    println(trace.answer)
  }
}
