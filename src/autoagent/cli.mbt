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
  println("AutoAgent - A lightweight MoonBit Agent runtime")
  println("")
  println("Usage:")
  println("  autoagent [OPTIONS] [GOAL]")
  println("  moon run src/main -- [OPTIONS] [GOAL]")
  println("")
  println("Arguments:")
  println("  [GOAL]    The goal for the agent to accomplish")
  println("")
  println("Options:")
  println("  -h, --help             Show this help message")
  println("  -v, --version          Show version information")
  println("  -c, --config           Show current configuration")
  println("  --max-steps <N>        Override maximum steps")
  println("  --verbose              Show detailed trace output")
  println("")
  println("Examples:")
  println("  autoagent \"build a chatbot for my website\"")
  println("  moon run src/main -- \"create a research assistant\"")
  println("  moon run src/main -- --max-steps 5 \"plan a migration\"")
  println("  moon run src/main -- --config")
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
