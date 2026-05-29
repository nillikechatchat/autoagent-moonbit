///|
/// REPL - Interactive agent loop inspired by Claude Code, Hermes, and Pi.
/// Handles multi-turn conversation, tool execution, and rich terminal display.
///

///|
pub struct ReplState {
  config : LLMConfig
  messages : Array[LLMMessage]
  session_file : String
  memory_file : String
  max_rounds : Int
  project_root : String
}

///|
pub fn ReplState::new(config : LLMConfig, session_dir : String, memory_file : String) -> ReplState {
  ignore(mkdir(session_dir))
  let ts = exec_command("date +%Y%m%d-%H%M%S").trim().to_owned()
  let session_file = session_dir + "/" + ts + ".md"
  ignore(write_file(session_file, "# Session\n\n"))
  {
    config,
    messages: [],
    session_file,
    memory_file,
    max_rounds: 8,
    project_root: get_cwd(),
  }
}

///|
/// Build system prompt with tool descriptions
///
fn build_system_prompt() -> String {
  "You are AutoAgent, a helpful AI coding assistant. " +
  "You can read files, write files, run commands, and search the web.\n\n" +
  get_tool_descriptions() +
  "\n\nBe concise. Create actual files when asked. " +
  "Use tools proactively to help the user."
}

///|
/// Parse LLM response to detect tool call or final reply
///
pub fn parse_response(response : String) -> ResponseAction {
  if response == "" { return Reply("") }
  if response.contains("```tool") {
    let start = str_index_of(response, "```tool", 0)
    let json_start = str_index_of(response, "\n", start)
    if json_start == -1 { return Reply(response) }
    let json_start = json_start + 1
    let end = str_index_of(response, "```", json_start)
    if end == -1 { return Reply(response) }
    let json_str = response[json_start:end].trim().to_owned()
    try {
      let parsed = @json.parse(json_str)
      match parsed {
        Object(obj) => {
          match (obj.get("name"), obj.get("input")) {
            (Some(Json::String(name)), Some(Json::String(input))) => CallTool(name, input)
            _ => Reply(response)
          }
        }
        _ => Reply(response)
      }
    } catch {
      _ => Reply(response)
    }
  } else {
    Reply(response)
  }
}

///|
pub(all) enum ResponseAction {
  Reply(String)
  CallTool(String, String)
}

///|
/// Run a single agent turn: plan → call LLM → parse → execute tools → loop
///
pub fn ReplState::run_turn(self : ReplState, user_input : String) -> String {
  // Add user message
  self.messages.push({ role: "user", content: user_input })

  // Build messages with system prompt
  let all_messages : Array[LLMMessage] = [
    { role: "system", content: build_system_prompt() },
  ]
  for m in self.messages {
    all_messages.push(m)
  }

  let mut final_reply = ""

  for _round in 0..<self.max_rounds {
    // Show thinking indicator
    print_thinking()

    // Call LLM
    let response = self.config.chat_content(all_messages)

    if response == "" {
      // Fallback to deterministic response
      final_reply = fallback_response(user_input)
      break
    }

    // Parse response
    match parse_response(response) {
      Reply(text) => {
        final_reply = text
        break
      }
      CallTool(name, input) => {
        // Show tool execution
        print_tool_start(name, input)

        // Execute tool
        let result = execute_tool(name, input, project_root=self.project_root)
        let result_str = match result {
          ToolSuccess(content) => {
            print_tool_done(name)
            content
          }
          ToolError(msg) => {
            print_tool_failed(name, msg)
            "Error: " + msg
          }
        }

        // Add to conversation
        self.messages.push({ role: "assistant", content: response })
        self.messages.push({ role: "user", content: "[" + name + " result]:\n" + result_str })
        all_messages.push({ role: "assistant", content: response })
        all_messages.push({ role: "user", content: "[" + name + " result]:\n" + result_str })
      }
    }
  }

  if final_reply == "" {
    final_reply = "Reached maximum rounds (" + self.max_rounds.to_string() + ")."
  }

  // Show final reply
  print_reply(final_reply)

  // Save to memory and session
  self.messages.push({ role: "assistant", content: final_reply })
  save_session(self.session_file, user_input, final_reply)
  save_memory(self.memory_file, self.messages)

  final_reply
}

///|
/// Run interactive REPL loop
///
pub fn run_repl(config : LLMConfig, session_dir : String, memory_file : String) -> Unit {
  let state = ReplState::new(config, session_dir, memory_file)

  print_banner(config)

  // Load existing memory
  let existing = load_memory(memory_file)
  for m in existing {
    state.messages.push(m)
  }

  while true {
    print_prompt()
    let input = read_line()
    let trimmed = input.trim().to_owned()
    if trimmed == "" { continue }

    match trimmed {
      "/quit" | "/exit" => {
        print_info("Goodbye.")
        break
      }
      "/clear" => {
        ignore(write_file(memory_file, "[]"))
        state.messages.clear()
        print_info("Memory cleared.")
      }
      "/history" => {
        let session = read_file(state.session_file)
        println(session)
      }
      "/skills" => {
        println("Built-in tools: read_file, write_file, list_files, run_command, search_web")
      }
      "/help" => {
        print_help()
      }
      _ => {
        ignore(state.run_turn(trimmed))
      }
    }
  }
}

///|
/// Run single-shot mode
///
pub fn run_single(config : LLMConfig, goal : String, session_dir : String, memory_file : String) -> String {
  let state = ReplState::new(config, session_dir, memory_file)
  let existing = load_memory(memory_file)
  for m in existing {
    state.messages.push(m)
  }
  state.run_turn(goal)
}

///|
fn fallback_response(goal : String) -> String {
  "I understand you want to: " + goal + "\n\n" +
  "However, no LLM API key is configured. To enable full functionality:\n\n" +
  "```bash\n" +
  "export MCAI_LLM_API_KEY='your-key'\n" +
  "export MCAI_LLM_BASE_URL='https://api.openai.com/v1'\n" +
  "export MCAI_LLM_MODEL='gpt-4o-mini'\n" +
  "```\n\n" +
  "Or edit .autoagent/config.json with your provider settings."
}

///|
fn save_session(session_file : String, user_input : String, reply : String) -> Unit {
  let entry = "## User\n" + user_input + "\n\n## Assistant\n" + reply + "\n\n"
  let existing = read_file(session_file)
  ignore(write_file(session_file, existing + entry))
}

///|
fn save_memory(memory_file : String, messages : Array[LLMMessage]) -> Unit {
  let mut parts = ""
  for i in 0..<messages.length() {
    let m = messages[i]
    if i > 0 { parts = parts + "," }
    parts = parts + "{\"role\":\"" + m.role + "\",\"content\":\"" + m.content + "\"}"
  }
  // Keep last 40 messages
  let total = messages.length()
  let start = if total > 40 { total - 40 } else { 0 }
  let trimmed = messages[start:]
  let mut trimmed_parts = ""
  for i in 0..<trimmed.length() {
    let m = trimmed[i]
    if i > 0 { trimmed_parts = trimmed_parts + "," }
    trimmed_parts = trimmed_parts + "{\"role\":\"" + m.role + "\",\"content\":\"" + m.content + "\"}"
  }
  ignore(write_file(memory_file, "[" + trimmed_parts + "]"))
}

///|
fn load_memory(memory_file : String) -> Array[LLMMessage] {
  let content = read_file(memory_file)
  if content == "" { return [] }
  try {
    let parsed = @json.parse(content)
    match parsed {
      Json::Array(items) => {
        items.filter_map(fn(item) {
          match item {
            Object(obj) => {
              match (obj.get("role"), obj.get("content")) {
                (Some(Json::String(role)), Some(Json::String(content))) => Some({ role, content })
                _ => None
              }
            }
            _ => None
          }
        })
      }
      _ => []
    }
  } catch { _ => [] }
}

///|
fn read_line() -> String {
  exec_command("head -1")
}

// ============================================================
// REPL Display Functions (inspired by Claude Code / Hermes / Pi)
// ============================================================

///|
fn print_banner(config : LLMConfig) -> Unit {
  println("")
  println(ansi_bold() + ansi_cyan() + "  AutoAgent v0.2.0" + ansi_reset())
  println(dim_text("  MoonBit-native agent runtime"))
  println(dim_text("  Brain: MoonBit | I/O: C FFI"))
  if config.is_configured() {
    println(dim_text("  Model: " + config.model))
  } else {
    println(dim_text("  Mode: deterministic (no API key)"))
  }
  println(dim_text("  Commands: /help /clear /history /quit"))
  println("")
}

///|
fn print_prompt() -> Unit {
  println(ansi_bold() + ansi_magenta() + "> " + ansi_reset())
}

///|
fn print_thinking() -> Unit {
  println(ansi_yellow() + "  thinking..." + ansi_reset())
}

///|
fn print_tool_start(name : String, input : String) -> Unit {
  println(ansi_yellow() + "  [" + name + "]" + ansi_reset() + " " + dim_text(input))
}

///|
fn print_tool_done(name : String) -> Unit {
  println(ansi_green() + "  done" + ansi_reset() + " " + dim_text(name))
}

///|
fn print_tool_failed(name : String, reason : String) -> Unit {
  println(ansi_red() + "  failed" + ansi_reset() + " " + name + ": " + reason)
}

///|
fn print_reply(text : String) -> Unit {
  println("")
  println(text)
  println("")
}

///|
fn print_info(msg : String) -> Unit {
  println(ansi_blue() + "  " + msg + ansi_reset())
}

///|
fn print_help() -> Unit {
  println("")
  println(ansi_bold() + "  Commands:" + ansi_reset())
  println("    /help      Show this help")
  println("    /clear     Clear conversation memory")
  println("    /history   Show session history")
  println("    /skills    List available tools")
  println("    /quit      Exit")
  println("")
  println(ansi_bold() + "  Tools:" + ansi_reset())
  println("    read_file, write_file, list_files, run_command, search_web")
  println("")
}
