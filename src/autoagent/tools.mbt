///|
/// Tool execution - implements real I/O tools via native FFI.
/// Each tool reads/writes files, runs commands, or searches the web.
///

///|
pub(all) enum ToolResult {
  ToolSuccess(String)
  ToolError(String)
}

///|
/// Execute a tool by name with input. Returns ToolResult.
///
pub fn execute_tool(name : String, input : String, project_root~ : String = "") -> ToolResult {
  let root = if project_root == "" { get_cwd() } else { project_root }
  match name {
    "read_file" => exec_read_file(input, root)
    "write_file" => exec_write_file(input, root)
    "list_files" => exec_list_files(input, root)
    "run_command" => exec_run_command(input)
    "search_web" => exec_search_web(input)
    _ => ToolError("Unknown tool: " + name)
  }
}

///|
/// Resolve a path relative to project root, preventing escape.
///
fn safe_path(path : String, root : String) -> Result[String, String] {
  let full = if path.has_prefix("/") {
    path
  } else {
    root + "/" + path
  }
  // Simple check: path must contain root prefix
  if full.has_prefix(root) {
    Ok(full)
  } else {
    Err("Path outside project: " + path)
  }
}

///|
fn exec_read_file(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      if !file_exists(path) {
        ToolError("File not found: " + input)
      } else {
        let content = read_file(path)
        if content.length() > 8000 {
          ToolSuccess(content[:8000].to_owned() + "\n... (truncated)")
        } else {
          ToolSuccess(content)
        }
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
fn exec_write_file(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match (parsed.value("path"), parsed.value("content")) {
      (Some(Json::String(path)), Some(Json::String(content))) => {
        match safe_path(path, root) {
          Ok(full_path) => {
            // Create parent directory if needed
            let parts = full_path.split("/").to_array()
            if parts.length() > 1 {
              let dir = parts[0:parts.length() - 1].join("/")
              if dir != "" { ignore(mkdir(dir)) }
            }
            if write_file(full_path, content) {
              ToolSuccess("Wrote " + content.length().to_string() + " bytes to " + path)
            } else {
              ToolError("Failed to write: " + path)
            }
          }
          Err(msg) => ToolError(msg)
        }
      }
      _ => ToolError("Invalid write_file input. Expected JSON with 'path' and 'content'.")
    }
  } catch {
    _ => ToolError("Invalid JSON for write_file: " + input)
  }
}

///|
fn exec_list_files(input : String, root : String) -> ToolResult {
  let path = if input == "" { "." } else { input }
  match safe_path(path, root) {
    Ok(dir) => {
      let entries = list_dir(dir)
      if entries == "" {
        ToolSuccess("(empty directory)")
      } else {
        ToolSuccess(entries)
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
fn exec_run_command(input : String) -> ToolResult {
  // Safety check: block dangerous commands
  let blocked = [
    "rm ", "rm\t", "rmdir ", "unlink ", "mkfs", "fdisk", "dd ",
    "shutdown", "reboot", "poweroff", "sudo ", "su ",
    "iptables", "useradd", "userdel", "passwd ",
    "git rm", "git clean", "docker rm", "docker rmi",
    "--delete", "DROP TABLE", "DROP DATABASE", "TRUNCATE",
  ]
  let lower = input.to_lower()
  for b in blocked {
    if lower.contains(b.to_lower()) {
      return ToolError("Command blocked by safety policy: " + input)
    }
  }
  let output = exec_command(input)
  if output.length() > 4000 {
    ToolSuccess(output[:4000].to_owned() + "\n... (truncated)")
  } else if output == "" {
    ToolSuccess("(no output)")
  } else {
    ToolSuccess(output)
  }
}

///|
fn exec_search_web(query : String) -> ToolResult {
  // Use DuckDuckGo HTML search via curl
  let encoded = url_encode(query)
  let url = "https://html.duckduckgo.com/html/?q=" + encoded
  let html = http_post(url, "")
  if html == "" {
    return ToolError("Search unavailable")
  }
  // Simple extraction of result snippets
  let results = extract_search_results(html)
  if results == "" {
    ToolError("No results found for: " + query)
  } else {
    ToolSuccess(results)
  }
}

///|
/// URL-encode a string (percent-encode non-alphanumeric characters)
///
fn url_encode(s : String) -> String {
  let mut out = ""
  for c in s {
    let code = c.to_int()
    if (code >= 48 && code <= 57) || // 0-9
       (code >= 65 && code <= 90) || // A-Z
       (code >= 97 && code <= 122) || // a-z
       c == '-' || c == '_' || c == '.' || c == '~' {
      out = out + c.to_string()
    } else if c == ' ' {
      out = out + "+"
    } else {
      out = out + "%" + hex_pair(code)
    }
  }
  out
}

///|
fn hex_pair(n : Int) -> String {
  let hex = "0123456789ABCDEF"
  let hi = (n >> 4) & 0xF
  let lo = n & 0xF
  hex[hi:hi+1].to_owned() + hex[lo:lo+1].to_owned()
}

fn str_index_of(haystack : String, needle : String, start : Int) -> Int {
  let hlen = haystack.length()
  let nlen = needle.length()
  let mut i = start
  while i + nlen <= hlen {
    if haystack[i:i+nlen] == needle { return i }
    i = i + 1
  }
  -1
}

///|
/// Extract search result snippets from DuckDuckGo HTML
///
fn extract_search_results(html : String) -> String {
  let mut results = ""
  let mut count = 0
  let marker = "result__snippet"
  let mut pos = 0
  while pos < html.length() && count < 5 {
    let idx = str_index_of(html, marker, pos)
    if idx == -1 { break }
    // Find the > after the tag
    let start = str_index_of(html, ">", idx + marker.length())
    if start == -1 { break }
    let snippet_start = start + 1
    let end = str_index_of(html, "</a>", snippet_start)
    if end == -1 { break }
    let snippet = strip_html_tags(html[snippet_start:end].to_owned())
    if snippet != "" {
      count = count + 1
      results = results + count.to_string() + ". " + snippet + "\n"
    }
    pos = end + 4
  }
  results
}

///|
/// Remove HTML tags from a string
///
fn strip_html_tags(s : String) -> String {
  let mut out = ""
  let mut in_tag = false
  for c in s {
    if c == '<' { in_tag = true }
    else if c == '>' { in_tag = false }
    else if !in_tag { out = out + c.to_string() }
  }
  out.trim().to_owned()
}

///|
/// Get tool description for system prompt
///
pub fn get_tool_descriptions() -> String {
  "Available tools:\n" +
  "- read_file: Read a file. Input: file path (relative to project root)\n" +
  "- write_file: Write a file. Input: JSON {\"path\":\"...\",\"content\":\"...\"}\n" +
  "- list_files: List directory. Input: directory path\n" +
  "- run_command: Execute a command. Input: shell command\n" +
  "- search_web: Search the web. Input: search query\n" +
  "\nTo use a tool, output exactly this format:\n" +
  "```tool\n" +
  "{\"name\":\"tool_name\",\"input\":\"tool_input\"}\n" +
  "```\n" +
  "When no tool is needed, respond normally."
}
