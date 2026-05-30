///|
fn main {
  let args = @env.args()

  // No arguments: start interactive REPL (Hermes-style)
  if args.length() < 2 {
    let config = @autoagent.LLMConfig::from_env_and_file(".autoagent/config.json")
    @autoagent.run_repl(config, ".autoagent/workspace/sessions", ".autoagent/workspace/memory.json")
    return
  }

  let cmd = args[1]

  if cmd == "--help" || cmd == "-h" {
    show_usage()
    return
  }

  if cmd == "--version" || cmd == "-v" {
    println("AutoAgent v1.0.0")
    return
  }

  if cmd == "--skills" {
    println(@autoagent.get_tool_descriptions())
    return
  }

  if cmd == "--evolve" || cmd == "evolve" {
    println(@autoagent.render_optimization_guide())
    println(@autoagent.render_anti_patterns())
    return
  }

  if cmd == "--deploy" || cmd == "deploy" {
    println(@autoagent.check_deploy_readiness(@autoagent.get_cwd()))
    return
  }

  if cmd == "--docs" || cmd == "docs" {
    println(@autoagent.generate_project_doc(@autoagent.get_cwd()))
    return
  }

  if cmd == "--benchmark" || cmd == "benchmark" {
    println(@autoagent.run_benchmark())
    return
  }

  if cmd == "--chains" {
    println(@autoagent.render_tool_chains())
    return
  }

  if cmd == "--release" {
    println(@autoagent.release_checklist("1.0.0"))
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
  println("AutoAgent v1.0.0 - MoonBit-native agent runtime")
  println("")
  println("Usage:")
  println("  autoagent              Start interactive REPL (default)")
  println("  autoagent chat         Start interactive REPL")
  println("  autoagent run <goal>   Run single-shot agent")
  println("  autoagent evolve       Show self-evolution workflow")
  println("  autoagent deploy       Deployment readiness check")
  println("  autoagent docs         Generate project documentation")
  println("  autoagent benchmark    Run performance benchmark")
  println("  autoagent <goal>       Run single-shot (shorthand)")
  println("")
  println("Options:")
  println("  --help, -h      Show this help")
  println("  --version, -v   Show version")
  println("  --config        Show provider config")
  println("  --skills        List available tools")
  println("  --evolve        Show self-evolution workflow")
  println("  --deploy        Deployment readiness check")
  println("  --docs          Generate project documentation")
  println("  --benchmark     Run performance benchmark")
  println("  --chains        Show predefined tool chains")
  println("")
  println("REPL Commands:")
  println("  /help           Show help")
  println("  /skills         List tools and skills")
  println("  /skill <name>   Show skill details")
  println("  /tools          Show tool descriptions")
  println("  /config         Show configuration")
  println("  /status         Show session status")
  println("  /history        Show session history")
  println("  /clear          Clear memory")
  println("  /resume         Resume previous session")
  println("  /export         Export session")
  println("  /search <q>     Search history")
  println("  /quit           Exit")
  println("")
  println("Environment:")
  println("  MCAI_LLM_API_KEY     LLM API key")
  println("  MCAI_LLM_BASE_URL    LLM API base URL")
  println("  MCAI_LLM_MODEL       LLM model name")
  println("")
  println("Or edit .autoagent/config.json with provider settings.")
}
