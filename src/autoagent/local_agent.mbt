///|
/// Local Agent Engine - Autonomous reasoning without LLM.
/// Parses user intent, selects tools, executes, and learns from interactions.
///

///|
/// Intent classification from user input
///
pub(all) enum UserIntent {
  FileRead(String)       // read/show/display file
  FileWrite(String)      // write/create file
  FileEdit(String)       // edit/modify file
  FileList(String)       // list/show directory
  FileSearch(String)     // find/search files
  CodeSearch(String)     // search in code
  RunCommand(String)     // execute command
  GitStatus              // git status
  GitDiff(String)        // git diff
  WebSearch(String)      // search web
  ProjectInfo            // show project info
  SystemInfo             // show system info
  MemoryWrite(String)    // save to memory
  MemoryRead             // read memory
  Help                   // help
  Chat(String)           // general conversation
  Unknown(String)
} derive(Debug)

///|
/// Classify user intent from natural language
///
pub fn classify_intent(input : String) -> UserIntent {
  let lower = input.to_lower()
  let trimmed = input.trim().to_owned()

  // Help
  if lower == "help" || lower == "/help" || lower == "?" {
    return Help
  }

  // File operations - read
  if lower.contains("read") || lower.contains("show") || lower.contains("display") || lower.contains("cat") || lower.contains("view") {
    let path = extract_path(trimmed)
    if path != "" { return FileRead(path) }
  }

  // File operations - write
  if lower.contains("write") || lower.contains("create") || lower.contains("save") || lower.contains("new file") {
    let path = extract_path(trimmed)
    if path != "" { return FileWrite(path) }
  }

  // File operations - edit
  if lower.contains("edit") || lower.contains("modify") || lower.contains("change") || lower.contains("update") {
    let path = extract_path(trimmed)
    if path != "" { return FileEdit(path) }
  }

  // File operations - list
  if lower.contains("list") || lower.contains("ls") || lower.contains("dir") || lower.contains("directory") {
    let path = extract_path(trimmed)
    return FileList(if path == "" { "." } else { path })
  }

  // Search operations
  if lower.contains("find") || lower.contains("search") || lower.contains("locate") {
    if lower.contains("file") || lower.contains("name") {
      return FileSearch(extract_search_query(trimmed))
    }
    if lower.contains("code") || lower.contains("content") || lower.contains("text") {
      return CodeSearch(extract_search_query(trimmed))
    }
    return FileSearch(extract_search_query(trimmed))
  }

  // Command execution with prefix
  if lower.has_prefix("run ") || lower.has_prefix("execute ") || lower.has_prefix("exec ") || lower.has_prefix("$ ") {
    return RunCommand(trimmed[4:].trim().to_owned())
  }

  // Common commands that should be executed directly
  let common_commands = ["pwd", "whoami", "date", "echo", "uname", "df", "du", "ps", "env", "which", "uptime"]
  for cmd in common_commands {
    if lower == cmd || lower.has_prefix(cmd + " ") {
      return RunCommand(trimmed)
    }
  }

  // Git operations
  if lower.contains("git status") || lower == "status" {
    return GitStatus
  }
  if lower.contains("git diff") || (lower == "diff") {
    return GitDiff("")
  }

  // Web search
  if lower.contains("search web") || lower.contains("google") || lower.contains("look up online") {
    return WebSearch(extract_search_query(trimmed))
  }

  // Info requests
  if lower.contains("project") && (lower.contains("info") || lower.contains("status") || lower.contains("overview")) {
    return ProjectInfo
  }

  if lower.contains("system") && (lower.contains("info") || lower.contains("status")) {
    return SystemInfo
  }

  // Memory operations
  if lower.contains("remember") || lower.contains("note") || lower.contains("memo") {
    return MemoryWrite(trimmed)
  }

  if lower.contains("recall") || lower.contains("memory") || lower.contains("history") {
    return MemoryRead
  }

  // Greetings
  if lower.contains("hello") || lower.contains("hi") || lower.contains("hey") || lower.contains("greetings") {
    return Chat(trimmed)
  }

  // Questions
  if lower.contains("what") || lower.contains("how") || lower.contains("why") || lower.contains("when") || lower.contains("where") {
    return Chat(trimmed)
  }

  // Try to detect file paths
  let path = extract_path(trimmed)
  if path != "" && (path.contains("/") || path.contains(".")) {
    return FileRead(path)
  }

  // Default to chat
  Chat(trimmed)
}

///|
/// Extract file path from input
///
fn extract_path(input : String) -> String {
  let trimmed = input.trim().to_owned()

  // Check for quoted paths
  let quote_start = str_index_of(trimmed, "\"", 0)
  if quote_start != -1 {
    let quote_end = str_index_of(trimmed, "\"", quote_start + 1)
    if quote_end != -1 {
      return trimmed[quote_start + 1:quote_end].to_owned()
    }
  }

  // Check for single quoted paths
  let quote_start = str_index_of(trimmed, "'", 0)
  if quote_start != -1 {
    let quote_end = str_index_of(trimmed, "'", quote_start + 1)
    if quote_end != -1 {
      return trimmed[quote_start + 1:quote_end].to_owned()
    }
  }

  // Look for common file extensions
  let extensions = [".mbt", ".md", ".json", ".txt", ".js", ".ts", ".py", ".c", ".h", ".go", ".rs", ".toml", ".yaml", ".yml", ".sh", ".html", ".css"]
  for ext in extensions {
    let idx = str_index_of(trimmed, ext, 0)
    if idx != -1 {
      // Find the start of the path (look backwards for space or start)
      let mut start = idx
      while start > 0 {
        let c = trimmed[start - 1]
        if c == ' ' || c == '\t' || c == '\n' { break }
        start = start - 1
      }
      let path = trimmed[start:idx + ext.length()].to_owned()
      if path.length() > 1 { return path }
    }
  }

  ""
}

///|
/// Extract search query from input
///
fn extract_search_query(input : String) -> String {
  let lower = input.to_lower()

  // Remove common prefixes
  let prefixes = ["search for ", "find ", "look for ", "locate ", "search ", "find files ", "search code "]
  let mut result = input
  for prefix in prefixes {
    let idx = str_index_of(lower, prefix, 0)
    if idx == 0 {
      result = input[prefix.length():].to_owned()
      break
    }
  }

  result.trim().to_owned()
}

///|
/// Execute intent autonomously
///
pub fn execute_intent(intent : UserIntent, project_root : String) -> String {
  match intent {
    FileRead(path) => {
      let result = execute_tool("read_file", path, project_root=project_root)
      match result {
        ToolSuccess(content) => content
        ToolError(msg) => "Error reading file: " + msg
      }
    }
    FileList(path) => {
      let result = execute_tool("list_files", path, project_root=project_root)
      match result {
        ToolSuccess(content) => content
        ToolError(msg) => "Error listing directory: " + msg
      }
    }
    FileSearch(query) => {
      // find_files expects a simple pattern, not JSON
      let result = execute_tool("find_files", query, project_root=project_root)
      match result {
        ToolSuccess(content) => content
        ToolError(msg) => "Error searching files: " + msg
      }
    }
    CodeSearch(query) => {
      // code_search expects JSON with pattern field
      let input = "{\"pattern\":\"" + query + "\"}"
      let result = execute_tool("code_search", input, project_root=project_root)
      match result {
        ToolSuccess(content) => content
        ToolError(msg) => "Error searching code: " + msg
      }
    }
    RunCommand(cmd) => {
      let result = execute_tool("run_command", cmd, project_root=project_root)
      match result {
        ToolSuccess(content) => content
        ToolError(msg) => "Error executing command: " + msg
      }
    }
    GitStatus => {
      let result = execute_tool("git_status", "", project_root=project_root)
      match result {
        ToolSuccess(content) => content
        ToolError(msg) => "Error getting git status: " + msg
      }
    }
    GitDiff(path) => {
      let result = execute_tool("git_diff", path, project_root=project_root)
      match result {
        ToolSuccess(content) => content
        ToolError(msg) => "Error getting diff: " + msg
      }
    }
    WebSearch(query) => {
      let result = execute_tool("search_web", query, project_root=project_root)
      match result {
        ToolSuccess(content) => content
        ToolError(msg) => "Error searching web: " + msg
      }
    }
    ProjectInfo => {
      let result = execute_tool("project_info", "", project_root=project_root)
      match result {
        ToolSuccess(content) => content
        ToolError(msg) => "Error getting project info: " + msg
      }
    }
    SystemInfo => {
      let result = execute_tool("system_info", "", project_root=project_root)
      match result {
        ToolSuccess(content) => content
        ToolError(msg) => "Error getting system info: " + msg
      }
    }
    MemoryWrite(content) => {
      let input = "{\"key\":\"user_note\",\"value\":\"" + content + "\"}"
      let result = execute_tool("memory_write", input, project_root=project_root)
      match result {
        ToolSuccess(msg) => msg
        ToolError(msg) => "Error saving to memory: " + msg
      }
    }
    MemoryRead => {
      let result = execute_tool("memory_read", "", project_root=project_root)
      match result {
        ToolSuccess(content) => content
        ToolError(msg) => "Error reading memory: " + msg
      }
    }
    Help => {
      "I'm AutoAgent, your AI coding assistant. I can:\n\n" +
      "• Read, write, and edit files\n" +
      "• Search for files and code\n" +
      "• Execute commands\n" +
      "• Check git status and diffs\n" +
      "• Search the web\n" +
      "• Show project and system info\n" +
      "• Remember notes for you\n\n" +
      "Just tell me what you need in natural language!"
    }
    Chat(input) => {
      // Try to be helpful even without LLM
      generate_chat_response(input)
    }
    FileWrite(path) => {
      "I can help you write to '" + path + "'. What content would you like to write?"
    }
    FileEdit(path) => {
      "I can help you edit '" + path + "'. What changes would you like to make?"
    }
    Unknown(_) => {
      "I'm not sure how to help with that. Try asking me to:\n" +
      "• Read or list files\n" +
      "• Search for code\n" +
      "• Run a command\n" +
      "• Check git status"
    }
  }
}

///|
/// Generate helpful chat response without LLM
///
fn generate_chat_response(input : String) -> String {
  let lower = input.to_lower()

  // Greetings
  if lower.contains("hello") || lower.contains("hi") || lower.contains("hey") || lower.contains("greetings") {
    return "Hello! I'm AutoAgent, your AI coding assistant. How can I help you today?"
  }

  // How are you
  if lower.contains("how are you") || lower.contains("how do you do") {
    return "I'm doing great! I'm ready to help you with your coding tasks. What would you like to work on?"
  }

  // What can you do
  if lower.contains("what can you do") || lower.contains("capabilities") || lower.contains("features") {
    return "I can help you with:\n\n" +
      "• **File operations**: Read, write, edit, list, search files\n" +
      "• **Code search**: Find patterns in your codebase\n" +
      "• **Command execution**: Run shell commands safely\n" +
      "• **Git integration**: Check status, view diffs\n" +
      "• **Web search**: Look up information online\n" +
      "• **Project analysis**: Get project overview and stats\n" +
      "• **Memory**: Remember notes and recall them later\n\n" +
      "Just tell me what you need in natural language!"
  }

  // Thank you
  if lower.contains("thank") || lower.contains("thanks") {
    return "You're welcome! Let me know if you need anything else."
  }

  // Goodbye
  if lower.contains("bye") || lower.contains("goodbye") || lower.contains("see you") {
    return "Goodbye! Have a great day!"
  }

  // Try to extract any file path and read it
  let path = extract_path(input)
  if path != "" {
    let result = execute_tool("read_file", path, project_root=get_cwd())
    match result {
      ToolSuccess(content) => {
        if content.length() > 2000 {
          return "Here's the beginning of '" + path + "':\n\n" + content[:2000].to_owned() + "\n\n... (truncated)"
        }
        return "Here's the content of '" + path + "':\n\n" + content
      }
      ToolError(_) => {
        // Fall through to default response
        ignore("file not found")
      }
    }
  }

  // Default helpful response
  "I understand you said: \"" + input + "\"\n\n" +
  "I can help you with file operations, code search, command execution, and more. " +
  "Try something like:\n" +
  "• \"read README.md\"\n" +
  "• \"list files in src/\"\n" +
  "• \"search for function main\"\n" +
  "• \"run make test\"\n" +
  "• \"git status\""
}
