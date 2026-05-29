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
    println(@autoagent.get_tool_descriptions())
    return
  }

  if cmd == "--config" {
    let config = @autoagent.LLMConfig::from_env_and_file(".autoagent/config.json")
    println("Provider: llm")
    println("Model: " + config.model)
    println("Base URL: " + config.base_url)
    let key_status = if config.api_key != "" { "(configured)" } else { "(not set)" }
    println("API Key: " + key_status)
    return
  }

  if cmd == "chat" || cmd == "repl" {
    let config = @autoagent.LLMConfig::from_env_and_file(".autoagent/config.json")
    @autoagent.run_repl(config, ".autoagent/workspace/sessions", ".autoagent/workspace/memory.json")
    return
  }

  if cmd == "run" {
    let config = @autoagent.LLMConfig::from_env_and_file(".autoagent/config.json")
    let goal = if args.length() > 2 { args[2] } else { "Hello" }
    ignore(@autoagent.run_single(config, goal, ".autoagent/workspace/sessions", ".autoagent/workspace/memory.json"))
    return
  }

  // Default: treat as goal, run single-shot
  let config = @autoagent.LLMConfig::from_env_and_file(".autoagent/config.json")
  ignore(@autoagent.run_single(config, cmd, ".autoagent/workspace/sessions", ".autoagent/workspace/memory.json"))
}

///|
fn show_usage() -> Unit {
  println("AutoAgent v0.2.0 - MoonBit-native agent runtime")
  println("")
  println("Usage:")
  println("  autoagent chat          Start interactive REPL")
  println("  autoagent run <goal>    Run single-shot agent")
  println("  autoagent <goal>        Run single-shot (shorthand)")
  println("")
  println("Options:")
  println("  --help, -h      Show this help")
  println("  --version, -v   Show version")
  println("  --config        Show provider config")
  println("  --skills        List available tools")
  println("")
  println("Environment:")
  println("  MCAI_LLM_API_KEY     LLM API key")
  println("  MCAI_LLM_BASE_URL    LLM API base URL")
  println("  MCAI_LLM_MODEL       LLM model name")
  println("")
  println("Or edit .autoagent/config.json with provider settings.")
}
