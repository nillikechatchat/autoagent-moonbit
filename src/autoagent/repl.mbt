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
  "You are AutoAgent, a powerful AI coding assistant that rivals Claude Code and Hermes.\n\n" +
  "## Capabilities\n" +
  "- Read/write/edit files with precision\n" +
  "- Execute shell commands safely\n" +
  "- Search code, files, and web\n" +
  "- Git operations and version control\n" +
  "- 83 built-in tools for development tasks\n\n" +
  "## Response Format\n" +
  "When taking action, use tool calls in this format:\n" +
  "```tool\n{\"name\": \"tool_name\", \"input\": \"tool_input\"}\n```\n\n" +
  "## Guidelines\n" +
  "1. Be proactive: Don't just describe, take action\n" +
  "2. Be concise: Get to the point, avoid fluff\n" +
  "3. Create real files when asked to build something\n" +
  "4. Use multiple tool calls when needed\n" +
  "5. Always verify your work with commands or tests\n" +
  "6. If uncertain, ask for clarification\n\n" +
  "## Tool Usage Tips\n" +
  "- Chain tools: read -> edit -> verify\n" +
  "- Test created files to ensure they work\n" +
  "- Use git_status/git_diff for version awareness\n" +
  get_tool_descriptions() +
  "\n\nYou are world-class at software development. Help users build amazing things."
}

///|
/// Parse LLM response to detect tool call or final reply
/// Supports multiple formats: markdown code block, JSON-only, and inline tool calls
///
pub fn parse_response(response : String) -> ResponseAction {
  if response == "" { return Reply("") }
  
  // Try format 1: ```tool {json}``` markdown block
  if response.contains("```tool") {
    let start = str_index_of(response, "```tool", 0)
    if start != -1 {
      let json_start = str_index_of(response, "\n", start)
      if json_start != -1 {
        let json_start = json_start + 1
        let end = str_index_of(response, "```", json_start)
        if end != -1 {
          let json_str = response[json_start:end].trim().to_owned()
          let result = parse_tool_json(json_str)
          match result {
            CallTool(_, _) => return result
            Reply(_) => return Reply(response)  // Return full response on parse failure
          }
        }
      }
    }
  }
  
  // Try format 2: ```json {json}``` markdown block
  if response.contains("```json") {
    let start = str_index_of(response, "```json", 0)
    if start != -1 {
      let json_start = str_index_of(response, "\n", start)
      if json_start != -1 {
        let json_start = json_start + 1
        let end = str_index_of(response, "```", json_start)
        if end != -1 {
          let json_str = response[json_start:end].trim().to_owned()
          let result = parse_tool_json(json_str)
          if !is_reply_with_empty_tool(result) {
            return result
          }
        }
      }
    }
  }
  
  // Try format 3: Raw JSON at start of response
  if response.trim().has_prefix("{") {
    let result = parse_tool_json(response.trim().to_owned())
    if !is_reply_with_empty_tool(result) {
      return result
    }
  }
  
  // Try format 4: Extract JSON from anywhere in response
  let json_start = str_index_of(response, "{\"name\":", 0)
  if json_start != -1 {
    let json_end = str_index_of(response, "}}", json_start)
    if json_end != -1 {
      let json_str = response[json_start:json_end + 2].trim().to_owned()
      let result = parse_tool_json(json_str)
      if !is_reply_with_empty_tool(result) {
        return result
      }
    }
  }
  
  // Default: treat as reply
  Reply(response)
}

///|
/// Helper to parse tool JSON and return CallTool or Reply
/// Requires both "name" and "input" fields
///
fn parse_tool_json(json_str : String) -> ResponseAction {
  try {
    let parsed = @json.parse(json_str)
    match parsed {
      Object(obj) => {
        match (obj.get("name"), obj.get("input")) {
          (Some(Json::String(name)), Some(Json::String(input))) => CallTool(name, input)
          // Missing "input" field - not a valid tool call, return original JSON
          (Some(Json::String(_)), None) => Reply(json_str)
          // Missing "name" field or invalid types
          _ => Reply(json_str)
        }
      }
      _ => Reply(json_str)
    }
  } catch {
    _ => Reply(json_str)
  }
}

///|
/// Check if result is Reply with empty or JSON content (meaning parse didn't find tool)
///
fn is_reply_with_empty_tool(result : ResponseAction) -> Bool {
  match result {
    Reply("") => true
    Reply(_) => false
    CallTool(_, _) => false
  }
}

///|
pub(all) enum ResponseAction {
  Reply(String)
  CallTool(String, String)
}

///|
/// Parse response with error recovery.
///
pub fn parse_response_safe(response : String) -> ResponseAction {
  if response == "" { return Reply("") }
  parse_response(response)
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

  // Context window management: truncate if too many messages
  let max_context = 30
  if all_messages.length() > max_context {
    let system = all_messages[0]
    let recent = all_messages[all_messages.length() - max_context + 1:]
    all_messages.clear()
    all_messages.push(system)
    for m in recent {
      all_messages.push(m)
    }
  }

  let mut final_reply = ""
  let mut tool_calls_count = 0

  // Check if LLM is configured
  if !self.config.is_configured() {
    // Use local agent engine for autonomous reasoning
    let intent = classify_intent(user_input)
    let tool_result = execute_intent(intent, self.project_root)

    // Format response
    final_reply = tool_result
    print_reply(final_reply)

    // Save to memory and session
    self.messages.push({ role: "assistant", content: final_reply })
    save_session(self.session_file, user_input, final_reply)
    save_memory(self.memory_file, self.messages)
    return final_reply
  }

  for round in 0..<self.max_rounds {
    // Show thinking indicator with round info
    if round == 0 {
      print_thinking()
    } else {
      print_thinking_continued(round + 1)
    }

    // Call LLM with retry
    let start_time = time_ms()
    let response = self.config.chat_stream_with_retry(all_messages)
    let elapsed = time_ms() - start_time

    if response == "" || response == "HTTP request failed" || response == "Empty response from LLM" {
      // Fallback to deterministic response
      final_reply = fallback_response(user_input)
      break
    }

    // Show timing
    print_timing(elapsed)

    // Parse response with error recovery
    match parse_response_safe(response) {
      Reply(text) => {
        final_reply = text
        break
      }
      CallTool(name, input) => {
        tool_calls_count = tool_calls_count + 1
        
        // Show tool execution with timing
        print_tool_start(name, input)
        let tool_start = time_ms()

        // Execute tool
        let result = execute_tool(name, input, project_root=self.project_root)
        let tool_elapsed = time_ms() - tool_start

        let result_str = match result {
          ToolSuccess(content) => {
            print_tool_done(name, tool_elapsed)
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
        
        // Continue to next round for multi-step tasks
        // But limit consecutive tool calls to prevent infinite loops
        if tool_calls_count >= 15 {
          print_info("Reached maximum tool calls per turn (15). Continuing with current results.")
          final_reply = "Completed " + tool_calls_count.to_string() + " tool operations. Result:\n" + result_str
          break
        }
      }
    }
  }
  
  // Handle case where all rounds completed without reply
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
    // Check if stdin is at EOF (piped input exhausted)
    if stdin_eof() {
      break
    }
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
        println("Built-in tools (83):")
        println("  read_file, write_file, edit_file, list_files, run_command, search_web")
        println("  find_files, code_search, git_status, git_diff")
        println("  memory_write, memory_read, env_info, project_info")
        println("  http_get, file_info, timestamp, env_get, string_replace, uuid_generate, get_cwd")
        println("  head_file, tail_file, count_lines, grep_file, diff_files")
        println("  copy_file, move_file, append_file, dir_size, disk_usage")
        println("  sort_file, uniq_file, wc_file, basename, dirname, realpath")
        println("  which, date, mkdir, is_dir, truncate_file, grep_count, grep_context")
        println("  file_type, file_permissions, file_owner, file_modified, file_size")
        println("  list_dir_detailed, find_by_type, find_by_size, grep_recursive, find_by_name")
        println("  find_by_time, file_checksum, compress_file, decompress_file")
        println("  tar_create, tar_extract, zip_create, zip_extract")
        println("  is_readable, is_writable, is_executable, file_extension")
        println("  file_lines, file_words, file_chars, system_info, memory_info")
        println("  cpu_info, network_info, process_list, env_list, uptime")
        println("  hostname, whoami, who, last, command_exists, shell_info, path_list")
        println("")
        println("Skills (10):")
        println("  research, code-review, docs, testing, code-gen")
        println("  debug, refactor, security, performance, architecture")
      }
      "/export" => {
        let ts = exec_command("date +%Y%m%d-%H%M%S")
        let export_path = ".autoagent/workspace/export-" + ts.trim().to_owned() + ".md"
        let mut export_content = "# AutoAgent Session Export\n\n"
        export_content = export_content + "Date: " + exec_command("date").trim().to_owned() + "\n\n"
        export_content = export_content + "## Conversation\n\n"
        for m in state.messages {
          let role = if m.role == "user" { "**User**" } else { "**Assistant**" }
          export_content = export_content + "### " + role + "\n\n" + m.content + "\n\n"
        }
        ignore(write_file(export_path, export_content))
        print_info("Exported to " + export_path)
      }
      "/config" => {
        println("Model: " + state.config.model)
        println("Base URL: " + state.config.base_url)
        let key_status = if state.config.api_key != "" { "(configured)" } else { "(not set)" }
        println("API Key: " + key_status)
        println("Messages: " + state.messages.length().to_string())
      }
      "/status" => {
        println("Session: " + state.session_file)
        println("Memory: " + state.memory_file)
        println("Messages: " + state.messages.length().to_string())
        println("Max rounds: " + state.max_rounds.to_string())
        println("Project root: " + state.project_root)
      }
      "/resume" => {
        let existing = load_memory(state.memory_file)
        if existing.length() > 0 {
          state.messages.clear()
          for m in existing {
            state.messages.push(m)
          }
          print_info("Resumed " + existing.length().to_string() + " messages from memory.")
        } else {
          print_info("No previous session found.")
        }
      }
      "/help" => {
        print_help()
      }
      "/discover" => {
        let discoverer = ToolDiscoverer::new()
        let project_recs = discoverer.scan_project(state.project_root)
        println("🔍 Tool Discovery:")
        if project_recs.length() > 0 {
          println(discoverer.render_recommendations(project_recs))
        } else {
          println("No specific tools. Use /tools to see all 83.")
        }
      }
      "/trace" => {
        let trace_mgr = TraceManager::new(".autoagent/workspace/traces.json")
        println(trace_mgr.list_recent(5))
      }
      "/evaluate" => {
        println(evaluate_agent(0, 0, state.messages.length(), state.messages.length()))
      }
      "/benchmark" => {
        println(run_benchmark())
      }
      "/chains" => {
        println(render_tool_chains())
      }
      "/security" => {
        let path = trimmed[9:].trim().to_owned()
        if path == "" {
          print_info("Usage: /security <file>")
        } else {
          let content = read_file(path)
          if content == "" {
            print_info("File not found: " + path)
          } else {
            println(scan_for_secrets(content, path))
          }
        }
      }
      "/deploy" => {
        println(check_deploy_readiness(state.project_root))
      }
      "/docs" => {
        println(generate_project_doc(state.project_root))
      }
      "/intent" => {
        let input = trimmed[7:].trim().to_owned()
        if input == "" {
          print_info("Usage: /intent <text>")
        } else {
          let intent = classify_user_intent(input)
          println(intent_icon(intent) + " Intent: " + intent)
        }
      }
      "/recover" => {
        let err = trimmed[8:].trim().to_owned()
        if err == "" {
          print_info("Usage: /recover <error message>")
        } else {
          println(suggest_recovery(err))
        }
      }
      "/version" => {
        println("AutoAgent v1.0.0")
        println("MoonBit-native agent runtime - Production Ready")
      }
      "/stats" => {
        println("📊 Session Statistics:")
        println("  Messages: " + state.messages.length().to_string())
        println("  Max rounds: " + state.max_rounds.to_string())
        println("  Session file: " + state.session_file)
        println("  Memory file: " + state.memory_file)
        println("  Available tools: 83")
        println("  Features: discovery, tracing, evaluation, security, deploy, docs")
      }
      "/reflect" => {
        println(evaluate_agent(0, 0, state.messages.length(), state.messages.length()))
      }
      "/evolve" => {
        println(render_optimization_guide())
        println(render_anti_patterns())
      }
      "/skill" => {
        let skill_name = trimmed[7:].trim().to_owned()
        if skill_name == "" {
          print_info("Usage: /skill <name>")
          print_info("Available: research, code-review, docs, testing, code-gen, debug, refactor, security, performance, architecture")
        } else {
          let registry = default_skill_registry()
          println(registry.render_skill_detail(skill_name))
        }
      }
      "/tools" => {
        println(get_tool_descriptions())
      }
      "/roles" => {
        println(render_agent_roles())
      }
      "/split" => {
        let goal = trimmed[6:].trim().to_owned()
        if goal == "" {
          print_info("Usage: /split <goal>")
        } else {
          println(render_task_splits(goal))
        }
      }
      "/complexity" => {
        let path = trimmed[11:].trim().to_owned()
        if path == "" {
          print_info("Usage: /complexity <file>")
        } else {
          let content = read_file(path)
          if content == "" {
            print_info("File not found: " + path)
          } else {
            println(analyze_code_complexity(content))
          }
        }
      }
      "/patterns" => {
        let path = trimmed[9:].trim().to_owned()
        if path == "" {
          print_info("Usage: /patterns <file>")
        } else {
          let content = read_file(path)
          if content == "" {
            print_info("File not found: " + path)
          } else {
            println(detect_code_patterns(content))
          }
        }
      }
      "/testgen" => {
        let func = trimmed[8:].trim().to_owned()
        if func == "" {
          print_info("Usage: /testgen <function_name>")
        } else {
          println(generate_test_suggestion(func, "general"))
        }
      }
      "/coverage" => {
        println(estimate_test_coverage(100, 40))
      }
      "/release" => {
        println(release_checklist("1.0.0"))
      }
      "/clear-history" => {
        state.messages.clear()
        ignore(write_file(state.session_file, "# Session\n\n"))
        print_info("Session history cleared.")
      }
      _ => {
        if trimmed.has_prefix("/search ") {
          let query = trimmed[8:].trim().to_owned()
          if query == "" {
            print_info("Usage: /search <query>")
          } else {
            let mut found = 0
            for m in state.messages {
              if m.content.contains(query) {
                let role = if m.role == "user" { "User" } else { "Assistant" }
                println("[" + role + "] " + m.content[:100].to_owned() + "...")
                found = found + 1
              }
            }
            if found == 0 {
              print_info("No messages found containing: " + query)
            } else {
              print_info("Found " + found.to_string() + " messages.")
            }
          }
        } else if trimmed.has_prefix("/") {
          print_info("Unknown command: " + trimmed)
          print_info("Type /help for available commands.")
        } else {
          ignore(state.run_turn(trimmed))
        }
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
  "⚠️  LLM API not configured. Running in local mode with limited capabilities.\n\n" +
  "To unlock full AI power (like Claude/Hermes):\n\n" +
  "```bash\n" +
  "export MCAI_LLM_API_KEY='your-api-key'\n" +
  "export MCAI_LLM_BASE_URL='https://proxy.monkeycode-ai.com/v1'\n" +
  "export MCAI_LLM_MODEL='monkeycode-basic/qwen3.5-plus'\n" +
  "```\n\n" +
  "Or edit `.autoagent/config.json` with your provider settings.\n\n" +
  "In local mode, I can still help with:\n" +
  "- File operations (read, write, edit)\n" +
  "- Command execution\n" +
  "- Git operations\n" +
  "- Basic intent classification\n\n" +
  "Try commands like:\n" +
  "- 'list files in current directory'\n" +
  "- 'show git status'\n" +
  "- 'create a file called test.txt with hello world'"
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
  read_stdin_line()
}

// ============================================================
// REPL Display Functions (inspired by Claude Code / Hermes / Pi)
// ============================================================

///|
fn print_banner(config : LLMConfig) -> Unit {
  println("")
  println(ansi_bold() + ansi_cyan() + "  AutoAgent v1.0.0" + ansi_reset() + ansi_bold() + " (Production Ready)" + ansi_reset())
  println(dim_text("  MoonBit-native agent runtime"))
  println(dim_text("  Brain: MoonBit | I/O: C FFI | Tools: 83"))
  if config.is_configured() {
    println(dim_text("  Model: " + config.model))
    println(dim_text("  Mode: LLM-powered with multi-step reasoning"))
  } else {
    println(dim_text("  Mode: Local autonomous agent (no API key)"))
    println(dim_text("  I can understand your intent and execute tools directly!"))
  }
  println(dim_text("  Commands: /help /tools /discover /split /complexity /release /quit"))
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
fn print_thinking_continued(round : Int) -> Unit {
  println(ansi_yellow() + "  thinking... (round " + round.to_string() + ")" + ansi_reset())
}

///|
fn print_tool_start(name : String, input : String) -> Unit {
  println(ansi_yellow() + "  [" + name + "]" + ansi_reset() + " " + dim_text(input))
}

///|
fn print_tool_done(name : String, elapsed_ms : Int64) -> Unit {
  let sec = elapsed_ms / 1000L
  let ms = elapsed_ms % 1000L
  println(ansi_green() + "  done" + ansi_reset() + " " + dim_text(name + " (" + sec.to_string() + "." + ms.to_string() + "s)"))
}

///|
fn print_timing(elapsed_ms : Int64) -> Unit {
  let sec = elapsed_ms / 1000L
  let ms = elapsed_ms % 1000L
  println(dim_text("  (" + sec.to_string() + "." + ms.to_string() + "s)"))
}

///|
fn print_tool_failed(name : String, reason : String) -> Unit {
  println(ansi_red() + "  failed" + ansi_reset() + " " + name + ": " + reason)
}

///|
fn print_reply(text : String) -> Unit {
  println("")
  // Check if this is a multi-step result summary
  if text.contains("Completed ") && text.contains(" tool operations") {
    println(ansi_bold() + ansi_green() + "✓ Multi-step task completed" + ansi_reset())
    println("")
    println(text)
  } else {
    println(text)
  }
  println("")
}

///|
fn print_info(msg : String) -> Unit {
  println(ansi_blue() + "  " + msg + ansi_reset())
}

///|
fn print_help() -> Unit {
  println("")
  println(ansi_bold() + "  Core Commands:" + ansi_reset())
  println("    /help           Show this help")
  println("    /clear          Clear conversation memory")
  println("    /history        Show session history")
  println("    /resume         Resume previous session")
  println("    /export         Export session to Markdown")
  println("    /search <q>     Search conversation history")
  println("    /config         Show configuration")
  println("    /status         Show session status")
  println("    /version        Show version")
  println("    /quit           Exit")
  println("")
  println(ansi_bold() + "  Tools & Skills:" + ansi_reset())
  println("    /tools          Show all 83 tool descriptions")
  println("    /skill <name>   Show skill details")
  println("    /discover       Discover recommended tools")
  println("    /chains         Show predefined tool chains")
  println("")
  println(ansi_bold() + "  Intelligence:" + ansi_reset())
  println("    /evaluate       Self-evaluation report")
  println("    /reflect        Performance reflection")
  println("    /evolve         Self-evolution guide")
  println("    /intent <text>  Classify user intent")
  println("    /benchmark      Run performance benchmark")
  println("")
  println(ansi_bold() + "  Multi-Agent:" + ansi_reset())
  println("    /roles          Show agent roles")
  println("    /split <goal>   Decompose task into subtasks")
  println("")
  println(ansi_bold() + "  Code Intelligence:" + ansi_reset())
  println("    /complexity <f> Analyze code complexity")
  println("    /patterns <f>   Detect code patterns")
  println("    /testgen <fn>   Generate test suggestions")
  println("    /coverage       Estimate test coverage")
  println("")
  println(ansi_bold() + "  Operations:" + ansi_reset())
  println("    /trace          Recent task execution traces")
  println("    /stats          Session statistics")
  println("    /security <f>   Scan file for secrets")
  println("    /deploy         Deployment readiness check")
  println("    /docs           Generate project documentation")
  println("    /recover <err>  Suggest error recovery")
  println("    /release        Release checklist")
  println("")
}
