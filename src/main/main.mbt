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

  let goal = if cli.goal == "" {
    "build a research assistant that can plan, call safe tools, and teach the user how to improve prompts"
  } else {
    cli.goal
  }

  let agent_config = match cli.max_steps {
    Some(steps) => {
      let c = config.to_agent_config()
      { ..c, max_steps: steps }
    }
    None => config.to_agent_config()
  }

  let agent = @autoagent.Agent::new(
    agent_config,
    @autoagent.Provider::new(config.provider.name),
    [
      @autoagent.Tool::new("scaffold", "Generate a minimal agent skeleton.", "builder", Low),
      @autoagent.Tool::new("checklist", "Generate a safe usage checklist.", "safety", Low),
      @autoagent.Tool::new("coach", "Coach the user through agent operation.", "education", Low),
    ],
  )

  println(@autoagent.banner())

  if cli.verbose {
    println(@autoagent.info("Running in verbose mode..."))
    println(@autoagent.divider())
    let trace = agent.run_trace(goal)
    println(@autoagent.format_trace(trace))
    println(@autoagent.format_answer(trace.answer))
    println(@autoagent.divider())
    println(@autoagent.format_run_summary(trace))
  } else {
    println(@autoagent.info("Goal: " + goal))
    println(@autoagent.divider())
    let trace = agent.run_trace(goal)
    println(@autoagent.format_trace(trace))
    println(@autoagent.format_answer(trace.answer))
  }
}
