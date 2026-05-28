///|
pub(all) struct CliArgs {
  mut goal : String
  mut show_help : Bool
  mut show_version : Bool
  mut show_config : Bool
  mut max_steps : Int?
  mut verbose : Bool
}

///|
pub fn default_cli_args() -> CliArgs {
  {
    goal: "",
    show_help: false,
    show_version: false,
    show_config: false,
    max_steps: None,
    verbose: false,
  }
}

///|
pub fn parse_args(args : Array[String]) -> CliArgs {
  let result = default_cli_args()
  let mut i = 0
  let mut goal = ""
  while i < args.length() {
    let arg = args[i]
    if arg == "--help" || arg == "-h" {
      result.show_help = true
    } else if arg == "--version" || arg == "-v" {
      result.show_version = true
    } else if arg == "--config" || arg == "-c" {
      result.show_config = true
    } else if arg == "--verbose" {
      result.verbose = true
    } else if arg == "--max-steps" && i + 1 < args.length() {
      i = i + 1
      result.max_steps = try {
        Some(@string.from_str(args[i]))
      } catch {
        _ => None
      }
    } else if arg.has_prefix("--max-steps=") {
      let value = arg[:][12:].to_owned()
      result.max_steps = try {
        Some(@string.from_str(value))
      } catch {
        _ => None
      }
    } else if arg.has_prefix("-") {
      // Unknown flag, skip
    } else {
      if goal == "" {
        goal = arg
      } else {
        goal = goal + " " + arg
      }
    }
    i = i + 1
  }
  result.goal = goal
  result
}

///|
pub fn show_help() -> Unit {
  println("")
  println("AutoAgent - A lightweight MoonBit Agent runtime")
  println("")
  println("  AutoAgent helps you build and use AI agents.")
  println("  Just tell it what you want to build, and it will")
  println("  create a step-by-step plan for you.")
  println("")
  println("Quick Start:")
  println("  make repl")
  println("  ./scripts/autoagent.sh init")
  println("  ./scripts/autoagent.sh chat")
  println("  autoagent \"build a chatbot for my website\"")
  println("")
  println("Usage:")
  println("  autoagent [OPTIONS] [GOAL]")
  println("  moon run src/main -- [OPTIONS] [GOAL]")
  println("  ./scripts/autoagent.sh [init|chat|run]")
  println("")
  println("Arguments:")
  println("  [GOAL]    What you want to build (be specific!)")
  println("")
  println("Options:")
  println("  -h, --help             Show this help message")
  println("  -v, --version          Show version information")
  println("  -c, --config           Show current configuration")
  println("  --max-steps <N>        Override maximum steps (default: 3)")
  println("  --verbose              Show detailed trace output")
  println("")
  println("Tips for beginners:")
  println("  - Be specific: 'build a chatbot' > 'help'")
  println("  - Use action verbs: build, create, design, write")
  println("  - Include the technology: 'React app', 'Python API'")
  println("  - Use ./scripts/autoagent.sh chat for an interactive session")
  println("  - Try --verbose to inspect traces")
  println("")
  println("More examples:")
  println("  autoagent \"design a user authentication system\"")
  println("  autoagent \"create a CLI tool for file processing\"")
  println("  autoagent --max-steps 5 \"plan a database migration\"")
  println("  autoagent --verbose \"build a blog with comments\"")
}

///|
pub fn show_version() -> Unit {
  println("AutoAgent v0.1.0")
  println("A lightweight MoonBit Agent runtime")
}

///|
pub fn show_config(config : Config) -> Unit {
  println(render_config(config))
}
