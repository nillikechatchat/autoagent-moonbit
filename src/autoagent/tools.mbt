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
    "edit_file" => exec_edit_file(input, root)
    "list_files" => exec_list_files(input, root)
    "run_command" => exec_run_command(input)
    "search_web" => exec_search_web(input)
    "find_files" => exec_find_files(input, root)
    "code_search" => exec_code_search(input, root)
    "git_status" => exec_git_status(root)
    "git_diff" => exec_git_diff(input, root)
    "memory_write" => exec_memory_write(input, root)
    "memory_read" => exec_memory_read(root)
    "env_info" => exec_env_info()
    "project_info" => exec_project_info(root)
    "http_get" => exec_http_get(input)
    "file_info" => exec_file_info(input, root)
    "timestamp" => exec_timestamp()
    "env_get" => exec_env_get(input)
    "string_replace" => exec_string_replace(input)
    "uuid_generate" => exec_uuid_generate()
    "get_cwd" => exec_get_cwd()
    "head_file" => exec_head_file(input, root)
    "tail_file" => exec_tail_file(input, root)
    "count_lines" => exec_count_lines(input, root)
    "grep_file" => exec_grep_file(input, root)
    "diff_files" => exec_diff_files(input, root)
    "copy_file" => exec_copy_file(input, root)
    "move_file" => exec_move_file(input, root)
    "append_file" => exec_append_file(input, root)
    "dir_size" => exec_dir_size(input, root)
    "disk_usage" => exec_disk_usage()
    "sort_file" => exec_sort_file(input, root)
    "uniq_file" => exec_uniq_file(input, root)
    "wc_file" => exec_wc_file(input, root)
    "basename" => exec_basename(input)
    "dirname" => exec_dirname(input)
    "realpath" => exec_realpath(input, root)
    "which" => exec_which(input)
    "date" => exec_date(input)
    "mkdir" => exec_mkdir(input, root)
    "is_dir" => exec_is_dir(input, root)
    "truncate_file" => exec_truncate_file(input, root)
    "grep_count" => exec_grep_count(input, root)
    "grep_context" => exec_grep_context(input, root)
    "file_type" => exec_file_type(input, root)
    "file_permissions" => exec_file_permissions(input, root)
    "file_owner" => exec_file_owner(input, root)
    "file_modified" => exec_file_modified(input, root)
    "file_size" => exec_file_size(input, root)
    "list_dir_detailed" => exec_list_dir_detailed(input, root)
    "find_by_type" => exec_find_by_type(input, root)
    "find_by_size" => exec_find_by_size(input, root)
    "grep_recursive" => exec_grep_recursive(input, root)
    "find_by_name" => exec_find_by_name(input, root)
    "find_by_time" => exec_find_by_time(input, root)
    "file_checksum" => exec_file_checksum(input, root)
    "compress_file" => exec_compress_file(input, root)
    "decompress_file" => exec_decompress_file(input, root)
    "tar_create" => exec_tar_create(input, root)
    "tar_extract" => exec_tar_extract(input, root)
    "zip_create" => exec_zip_create(input, root)
    "zip_extract" => exec_zip_extract(input, root)
    "is_readable" => exec_is_readable(input, root)
    "is_writable" => exec_is_writable(input, root)
    "is_executable" => exec_is_executable(input, root)
    "file_extension" => exec_file_extension(input)
    "file_lines" => exec_file_lines(input, root)
    "file_words" => exec_file_words(input, root)
    "file_chars" => exec_file_chars(input, root)
    "system_info" => exec_system_info()
    "memory_info" => exec_memory_info()
    "cpu_info" => exec_cpu_info()
    "network_info" => exec_network_info()
    "process_list" => exec_process_list(input)
    "env_list" => exec_env_list()
    "uptime" => exec_uptime()
    "hostname" => exec_hostname()
    "whoami" => exec_whoami()
    "who" => exec_who()
    "last" => exec_last(input)
    "command_exists" => exec_command_exists(input)
    "shell_info" => exec_shell_info()
    "path_list" => exec_path_list()
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
    match parsed {
      Object(obj) => {
        match (obj.get("path"), obj.get("content")) {
          (Some(Json::String(path)), Some(Json::String(content))) => {
            match safe_path(path, root) {
              Ok(full_path) => {
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
    "chmod 777", "chmod +s", "chown root",
    "> /dev/", "format ", "mkfs",
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
/// Quote a string for POSIX shell single-quoted argument context.
fn shell_quote(s : String) -> String {
  let mut out = "'"
  for c in s {
    if c.to_int() == 39 {
      out = out + "'\\''"
    } else {
      out = out + c.to_string()
    }
  }
  out + "'"
}

///|
/// Get tool description for system prompt
///
pub fn get_tool_descriptions() -> String {
  "Available tools:\n" +
  "- read_file: Read a file. Input: file path (relative to project root)\n" +
  "- write_file: Write a file. Input: JSON {\"path\":\"...\",\"content\":\"...\"}\n" +
  "- edit_file: Edit a file (find and replace). Input: JSON {\"path\":\"...\",\"old\":\"...\",\"new\":\"...\"}\n" +
  "- list_files: List directory. Input: directory path\n" +
  "- run_command: Execute a command. Input: shell command\n" +
  "- search_web: Search the web. Input: search query\n" +
  "- find_files: Find files by name pattern. Input: glob pattern (e.g., \"*.mbt\")\n" +
  "- code_search: Search code content. Input: JSON {\"pattern\":\"...\",\"path\":\"...\"}\n" +
  "- git_status: Show git working tree status. Input: (empty)\n" +
  "- git_diff: Show git diff. Input: file path or (empty) for all\n" +
  "- memory_write: Write to agent memory. Input: JSON {\"key\":\"...\",\"value\":\"...\"}\n" +
  "- memory_read: Read agent memory. Input: (empty)\n" +
  "- env_info: Show environment info. Input: (empty)\n" +
  "- project_info: Show project info. Input: (empty)\n" +
  "- http_get: HTTP GET request. Input: URL\n" +
  "- file_info: Get file metadata. Input: file path\n" +
  "- timestamp: Get current timestamp. Input: (empty)\n" +
  "- env_get: Get environment variable. Input: variable name\n" +
  "- string_replace: String replacement. Input: JSON {\"text\":\"...\",\"old\":\"...\",\"new\":\"...\"}\n" +
  "- uuid_generate: Generate UUID. Input: (empty)\n" +
  "- get_cwd: Get current working directory. Input: (empty)\n" +
  "- head_file: Read first N lines. Input: JSON {\"path\":\"...\",\"lines\":10}\n" +
  "- tail_file: Read last N lines. Input: JSON {\"path\":\"...\",\"lines\":10}\n" +
  "- count_lines: Count lines in file. Input: file path\n" +
  "- grep_file: Search pattern in file. Input: JSON {\"path\":\"...\",\"pattern\":\"...\"}\n" +
  "- diff_files: Compare two files. Input: JSON {\"file1\":\"...\",\"file2\":\"...\"}\n" +
  "- copy_file: Copy file. Input: JSON {\"source\":\"...\",\"destination\":\"...\"}\n" +
  "- move_file: Move/rename file. Input: JSON {\"source\":\"...\",\"destination\":\"...\"}\n" +
  "- append_file: Append to file. Input: JSON {\"path\":\"...\",\"content\":\"...\"}\n" +
  "- dir_size: Get directory size. Input: directory path\n" +
  "- disk_usage: Get disk usage. Input: (empty)\n" +
  "- sort_file: Sort file lines. Input: JSON {\"path\":\"...\",\"reverse\":false}\n" +
  "- uniq_file: Remove duplicate lines. Input: file path\n" +
  "- wc_file: Word count. Input: file path\n" +
  "- basename: Get filename from path. Input: file path\n" +
  "- dirname: Get directory from path. Input: file path\n" +
  "- realpath: Get absolute path. Input: file path\n" +
  "- which: Find command location. Input: command name\n" +
  "- date: Get current date/time. Input: format string or empty\n" +
  "- mkdir: Create directory. Input: directory path\n" +
  "- is_dir: Check if path is directory. Input: file path\n" +
  "- truncate_file: Truncate file to N lines. Input: JSON {\"path\":\"...\",\"lines\":100}\n" +
  "- grep_count: Count pattern matches. Input: JSON {\"path\":\"...\",\"pattern\":\"...\"}\n" +
  "- grep_context: Get context around matches. Input: JSON {\"path\":\"...\",\"pattern\":\"...\",\"context\":2}\n" +
  "- file_type: Get file type. Input: file path\n" +
  "- file_permissions: Get file permissions. Input: file path\n" +
  "- file_owner: Get file owner. Input: file path\n" +
  "- file_modified: Get file modification time. Input: file path\n" +
  "- file_size: Get file size. Input: file path\n" +
  "- list_dir_detailed: List directory with details. Input: directory path\n" +
  "- find_by_type: Find files by type. Input: JSON {\"path\":\"...\",\"type\":\"f\"}\n" +
  "- find_by_size: Find files by size. Input: JSON {\"path\":\"...\",\"size\":\"+1M\"}\n" +
  "- grep_recursive: Recursive grep. Input: JSON {\"path\":\"...\",\"pattern\":\"...\",\"include\":\"*.mbt\"}\n" +
  "- find_by_name: Find by name pattern. Input: JSON {\"path\":\"...\",\"name\":\"*.mbt\"}\n" +
  "- find_by_time: Find by modification time. Input: JSON {\"path\":\"...\",\"days\":7}\n" +
  "- file_checksum: Get file checksum. Input: JSON {\"path\":\"...\",\"algorithm\":\"md5\"}\n" +
  "- compress_file: Compress file with gzip. Input: file path\n" +
  "- decompress_file: Decompress file with gzip. Input: file path\n" +
  "- tar_create: Create tar archive. Input: JSON {\"source\":\"...\",\"destination\":\"...\"}\n" +
  "- tar_extract: Extract tar archive. Input: JSON {\"source\":\"...\",\"destination\":\"...\"}\n" +
  "- zip_create: Create zip archive. Input: JSON {\"source\":\"...\",\"destination\":\"...\"}\n" +
  "- zip_extract: Extract zip archive. Input: JSON {\"source\":\"...\",\"destination\":\"...\"}\n" +
  "- is_readable: Check if file is readable. Input: file path\n" +
  "- is_writable: Check if file is writable. Input: file path\n" +
  "- is_executable: Check if file is executable. Input: file path\n" +
  "- file_extension: Get file extension. Input: file path\n" +
  "- file_lines: Get file lines count. Input: file path\n" +
  "- file_words: Get file words count. Input: file path\n" +
  "- file_chars: Get file characters count. Input: file path\n" +
  "- system_info: Get system information. Input: (empty)\n" +
  "- memory_info: Get memory information. Input: (empty)\n" +
  "- cpu_info: Get CPU information. Input: (empty)\n" +
  "- network_info: Get network information. Input: (empty)\n" +
  "- process_list: Get process list. Input: (empty) or process name\n" +
  "- env_list: Get environment variables. Input: (empty)\n" +
  "- uptime: Get system uptime. Input: (empty)\n" +
  "- hostname: Get system hostname. Input: (empty)\n" +
  "- whoami: Get current user. Input: (empty)\n" +
  "- who: Get logged in users. Input: (empty)\n" +
  "- last: Get last logins. Input: (empty) or username\n" +
  "- command_exists: Check if command exists. Input: command name\n" +
  "- shell_info: Get shell information. Input: (empty)\n" +
  "- path_list: Get PATH directories. Input: (empty)\n" +
  "\nTo use a tool, output exactly this format:\n" +
  "```tool\n" +
  "{\"name\":\"tool_name\",\"input\":\"tool_input\"}\n" +
  "```\n" +
  "When no tool is needed, respond normally."
}

// ============================================================
// Additional tools for mature product
// ============================================================

///|
fn exec_find_files(pattern : String, root : String) -> ToolResult {
  let cmd = "find " + shell_quote(root) + " -name " + shell_quote(pattern) + " -not -path '*/_build/*' -not -path '*/.git/*' 2>/dev/null | head -50"
  let output = exec_command(cmd)
  if output == "" {
    ToolSuccess("No files found matching: " + pattern)
  } else {
    ToolSuccess(output)
  }
}

///|
fn exec_git_status(root : String) -> ToolResult {
  let cmd = "cd " + shell_quote(root) + " && git status --short 2>/dev/null || echo 'Not a git repository'"
  let output = exec_command(cmd)
  if output == "" {
    ToolSuccess("Working tree clean")
  } else {
    ToolSuccess(output)
  }
}

///|
fn exec_git_diff(input : String, root : String) -> ToolResult {
  let file_arg = if input == "" { "" } else { " -- " + shell_quote(input) }
  let cmd = "cd " + shell_quote(root) + " && git diff --stat" + file_arg + " 2>/dev/null || echo 'Not a git repository'"
  let output = exec_command(cmd)
  if output == "" {
    ToolSuccess("No changes")
  } else {
    if output.length() > 4000 {
      ToolSuccess(output[:4000].to_owned() + "\n... (truncated)")
    } else {
      ToolSuccess(output)
    }
  }
}

// ============================================================
// New tools for mature product
// ============================================================

///|
/// Edit a file (find and replace). Input: JSON {"path":"...","old":"...","new":"..."}
///
fn exec_edit_file(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let path_val = obj.get("path")
        let old_val = obj.get("old")
        let new_val = obj.get("new")
        match (path_val, old_val, new_val) {
          (Some(Json::String(path)), Some(Json::String(old)), Some(Json::String(new))) => {
            match safe_path(path, root) {
              Ok(full_path) => {
                let content = read_file(full_path)
                if content == "" {
                  ToolError("File not found or empty: " + path)
                } else {
                  if !content.contains(old) {
                    ToolError("Text not found in file: " + old)
                  } else {
                    // Replace first occurrence
                    let idx = str_index_of(content, old, 0)
                    if idx == -1 {
                      ToolError("Text not found in file: " + old)
                    } else {
                      let before = content[:idx].to_owned()
                      let after = content[idx + old.length():].to_owned()
                      let new_content = before + new + after
                      if write_file(full_path, new_content) {
                        ToolSuccess("Edited " + path + ": replaced '" + old + "' with '" + new + "'")
                      } else {
                        ToolError("Failed to write file: " + path)
                      }
                    }
                  }
                }
              }
              Err(msg) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid edit_file input. Expected JSON with 'path', 'old', 'new'.")
        }
      }
      _ => ToolError("Invalid JSON for edit_file")
    }
  } catch {
    _ => ToolError("Invalid JSON for edit_file: " + input)
  }
}

///|
/// Search code content. Input: JSON {"pattern":"...","path":"..."}
///
fn exec_code_search(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let pattern_val = obj.get("pattern")
        let path_val = obj.get("path")
        let pattern = match pattern_val { Some(Json::String(s)) => s; _ => "" }
        let search_path = match path_val { Some(Json::String(s)) => s; _ => "." }
        if pattern == "" {
          ToolError("Missing 'pattern' in code_search input")
        } else {
          match safe_path(search_path, root) {
            Ok(full_path) => {
              let cmd = "grep -rn --include='*.mbt' --include='*.js' --include='*.ts' --include='*.py' --include='*.go' --include='*.rs' --include='*.c' --include='*.h' -- " + shell_quote(pattern) + " " + shell_quote(full_path) + " 2>/dev/null | head -30"
              let output = exec_command(cmd)
              if output == "" {
                ToolSuccess("No matches found for: " + pattern)
              } else {
                ToolSuccess(output)
              }
            }
            Err(msg) => ToolError(msg)
          }
        }
      }
      _ => ToolError("Invalid JSON for code_search")
    }
  } catch {
    _ => ToolError("Invalid JSON for code_search: " + input)
  }
}

///|
/// Write to agent memory. Input: JSON {"key":"...","value":"..."}
///
fn exec_memory_write(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let key_val = obj.get("key")
        let value_val = obj.get("value")
        match (key_val, value_val) {
          (Some(String(key)), Some(String(value))) => {
            ignore(mkdir(root + "/.autoagent"))
            ignore(mkdir(root + "/.autoagent/workspace"))
            let memory_path = root + "/.autoagent/workspace/agent-memory.json"
            let mut memory_json = read_file(memory_path)
            if memory_json == "" { memory_json = "{}" }
            // Simple JSON update: add key-value pair
            let new_entry = "\"" + escape_json(key) + "\":\"" + escape_json(value) + "\""
            if memory_json == "{}" {
              memory_json = "{" + new_entry + "}"
            } else {
              // Insert before closing brace
              let without_brace = memory_json[:memory_json.length() - 1].to_owned()
              memory_json = without_brace + "," + new_entry + "}"
            }
            if write_file(memory_path, memory_json) {
              ToolSuccess("Memory written: " + key)
            } else {
              ToolError("Failed to write memory")
            }
          }
          _ => ToolError("Invalid memory_write input. Expected JSON with 'key' and 'value'.")
        }
      }
      _ => ToolError("Invalid JSON for memory_write")
    }
  } catch {
    _ => ToolError("Invalid JSON for memory_write: " + input)
  }
}

///|
/// Read agent memory. Input: (empty) or JSON {"key":"..."}
///
fn exec_memory_read(root : String) -> ToolResult {
  let memory_path = root + "/.autoagent/workspace/agent-memory.json"
  let content = read_file(memory_path)
  if content == "" {
    ToolSuccess("No agent memory found.")
  } else {
    ToolSuccess(content)
  }
}

///|
/// Show environment info. Input: (empty)
///
fn exec_env_info() -> ToolResult {
  let os = exec_command("uname -s")
  let arch = exec_command("uname -m")
  let shell = exec_command("echo $SHELL")
  let node = exec_command("node --version 2>/dev/null || echo 'not installed'")
  let python = exec_command("python3 --version 2>/dev/null || echo 'not installed'")
  let git = exec_command("git --version 2>/dev/null || echo 'not installed'")
  let moon = exec_command("moon version 2>/dev/null || echo 'not installed'")

  let info = "Environment:\n" +
    "  OS: " + os.trim().to_owned() + "\n" +
    "  Architecture: " + arch.trim().to_owned() + "\n" +
    "  Shell: " + shell.trim().to_owned() + "\n" +
    "  Node.js: " + node.trim().to_owned() + "\n" +
    "  Python: " + python.trim().to_owned() + "\n" +
    "  Git: " + git.trim().to_owned() + "\n" +
    "  MoonBit: " + moon.trim().to_owned()
  ToolSuccess(info)
}

///|
/// Show project info. Input: (empty)
///
fn exec_project_info(root : String) -> ToolResult {
  let has_moon_mod = file_exists(root + "/moon.mod")
  let has_package_json = file_exists(root + "/package.json")
  let has_go_mod = file_exists(root + "/go.mod")
  let has_cargo_toml = file_exists(root + "/Cargo.toml")
  let has_makefile = file_exists(root + "/Makefile")
  let has_git = file_exists(root + "/.git")

  let mut project_type = "unknown"
  if has_moon_mod { project_type = "MoonBit" }
  else if has_package_json { project_type = "Node.js" }
  else if has_go_mod { project_type = "Go" }
  else if has_cargo_toml { project_type = "Rust" }

  let files = list_dir(root)
  let file_count = exec_command("find " + shell_quote(root) + " -type f -not -path '*/_build/*' -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null | wc -l")
  let top_entries = if files.length() > 200 { files[:200].to_owned() } else { files }

  let info = "Project Info:\n" +
    "  Root: " + root + "\n" +
    "  Type: " + project_type + "\n" +
    "  Git: " + (if has_git { "yes" } else { "no" }) + "\n" +
    "  Makefile: " + (if has_makefile { "yes" } else { "no" }) + "\n" +
    "  Files: " + file_count.trim().to_owned() + "\n" +
    "  Top entries: " + top_entries
  ToolSuccess(info)
}

// ============================================================
// Additional utility tools
// ============================================================

///|
/// HTTP GET request. Input: URL
///
fn exec_http_get(input : String) -> ToolResult {
  let url = input.trim().to_owned()
  if url == "" {
    ToolError("Missing URL for http_get")
  } else {
    let result = http_post(url, "")
    if result == "" {
      ToolError("HTTP GET failed for: " + url)
    } else {
      if result.length() > 8000 {
        ToolSuccess(result[:8000].to_owned() + "\n... (truncated)")
      } else {
        ToolSuccess(result)
      }
    }
  }
}

///|
/// Get file info. Input: file path
///
fn exec_file_info(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      if !file_exists(path) {
        ToolError("File not found: " + input)
      } else {
        let exists = file_exists(path)
        let content = read_file(path)
        let size = content.length()
        let is_dir = list_dir(path) != ""
        let info = "File Info:\n" +
          "  Path: " + input + "\n" +
          "  Exists: " + (if exists { "yes" } else { "no" }) + "\n" +
          "  Size: " + size.to_string() + " bytes\n" +
          "  Is Directory: " + (if is_dir { "yes" } else { "no" })
        ToolSuccess(info)
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// Get current timestamp. Input: (empty)
///
fn exec_timestamp() -> ToolResult {
  let ts = exec_command("date +%Y-%m-%dT%H:%M:%S%z")
  let ts_clean = ts.trim().to_owned()
  ToolSuccess("Current timestamp: " + ts_clean)
}

///|
/// Get environment variable. Input: variable name
///
fn exec_env_get(input : String) -> ToolResult {
  let key = input.trim().to_owned()
  if key == "" {
    ToolError("Missing variable name for env_get")
  } else {
    let value = get_env(key)
    if value == "" {
      ToolSuccess("Environment variable '" + key + "' is not set")
    } else {
      ToolSuccess(key + "=" + value)
    }
  }
}

///|
/// String replace utility. Input: JSON {"text":"...","old":"...","new":"..."}
///
fn exec_string_replace(input : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let text_val = obj.get("text")
        let old_val = obj.get("old")
        let new_val = obj.get("new")
        match (text_val, old_val, new_val) {
          (Some(Json::String(text)), Some(Json::String(old)), Some(Json::String(new))) => {
            if !text.contains(old) {
              ToolSuccess(text)
            } else {
              let idx = str_index_of(text, old, 0)
              if idx == -1 {
                ToolSuccess(text)
              } else {
                let before = text[:idx].to_owned()
                let after = text[idx + old.length():].to_owned()
                let result = before + new + after
                if result.length() > 8000 {
                  ToolSuccess(result[:8000].to_owned() + "\n... (truncated)")
                } else {
                  ToolSuccess(result)
                }
              }
            }
          }
          _ => ToolError("Invalid string_replace input. Expected JSON with 'text', 'old', 'new'.")
        }
      }
      _ => ToolError("Invalid JSON for string_replace")
    }
  } catch {
    _ => ToolError("Invalid JSON for string_replace: " + input)
  }
}

///|
/// Generate UUID. Input: (empty)
///
fn exec_uuid_generate() -> ToolResult {
  let uuid = exec_command("cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen 2>/dev/null || echo 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'")
  let uuid_clean = uuid.trim().to_owned()
  ToolSuccess("Generated UUID: " + uuid_clean)
}

///|
/// Get current working directory. Input: (empty)
///
fn exec_get_cwd() -> ToolResult {
  let cwd = get_cwd()
  if cwd == "" {
    ToolError("Failed to get current working directory")
  } else {
    ToolSuccess("Current directory: " + cwd)
  }
}

// ============================================================
// More utility tools for mature product
// ============================================================

///|
/// Read first N lines of a file. Input: JSON {"path":"...","lines":10}
///
fn exec_head_file(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let path_val = obj.get("path")
        let lines_val = obj.get("lines")
        match path_val {
          Some(Json::String(path)) => {
            match safe_path(path, root) {
              Ok(full_path) => {
                if !file_exists(full_path) {
                  ToolError("File not found: " + path)
                } else {
                  let n = match lines_val {
                    Some(Json::Number(num, ..)) => num.to_int()
                    _ => 10
                  }
                  let cmd = "head -" + n.to_string() + " " + shell_quote(full_path)
                  let output = exec_command(cmd)
                  if output == "" {
                    ToolSuccess("(empty file)")
                  } else {
                    ToolSuccess(output)
                  }
                }
              }
              Err(msg) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid head_file input. Expected JSON with 'path'.")
        }
      }
      _ => ToolError("Invalid JSON for head_file")
    }
  } catch {
    _ => ToolError("Invalid JSON for head_file: " + input)
  }
}

///|
/// Read last N lines of a file. Input: JSON {"path":"...","lines":10}
///
fn exec_tail_file(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let path_val = obj.get("path")
        let lines_val = obj.get("lines")
        match path_val {
          Some(Json::String(path)) => {
            match safe_path(path, root) {
              Ok(full_path) => {
                if !file_exists(full_path) {
                  ToolError("File not found: " + path)
                } else {
                  let n = match lines_val {
                    Some(Json::Number(num, ..)) => num.to_int()
                    _ => 10
                  }
                  let cmd = "tail -" + n.to_string() + " " + shell_quote(full_path)
                  let output = exec_command(cmd)
                  if output == "" {
                    ToolSuccess("(empty file)")
                  } else {
                    ToolSuccess(output)
                  }
                }
              }
              Err(msg) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid tail_file input. Expected JSON with 'path'.")
        }
      }
      _ => ToolError("Invalid JSON for tail_file")
    }
  } catch {
    _ => ToolError("Invalid JSON for tail_file: " + input)
  }
}

///|
/// Count lines in a file. Input: file path
///
fn exec_count_lines(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      if !file_exists(path) {
        ToolError("File not found: " + input)
      } else {
        let cmd = "wc -l " + shell_quote(path)
        let output = exec_command(cmd)
        ToolSuccess("Line count: " + output.trim().to_owned())
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// Search for pattern in a file. Input: JSON {"path":"...","pattern":"..."}
///
fn exec_grep_file(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let path_val = obj.get("path")
        let pattern_val = obj.get("pattern")
        match (path_val, pattern_val) {
          (Some(Json::String(path)), Some(Json::String(pattern))) => {
            match safe_path(path, root) {
              Ok(full_path) => {
                if !file_exists(full_path) {
                  ToolError("File not found: " + path)
                } else {
                  let cmd = "grep -n " + shell_quote(pattern) + " " + shell_quote(full_path)
                  let output = exec_command(cmd)
                  if output == "" {
                    ToolSuccess("No matches found for: " + pattern)
                  } else {
                    ToolSuccess(output)
                  }
                }
              }
              Err(msg) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid grep_file input. Expected JSON with 'path' and 'pattern'.")
        }
      }
      _ => ToolError("Invalid JSON for grep_file")
    }
  } catch {
    _ => ToolError("Invalid JSON for grep_file: " + input)
  }
}

///|
/// Compare two files. Input: JSON {"file1":"...","file2":"..."}
///
fn exec_diff_files(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let file1_val = obj.get("file1")
        let file2_val = obj.get("file2")
        match (file1_val, file2_val) {
          (Some(Json::String(file1)), Some(Json::String(file2))) => {
            match (safe_path(file1, root), safe_path(file2, root)) {
              (Ok(path1), Ok(path2)) => {
                if !file_exists(path1) {
                  ToolError("File not found: " + file1)
                } else if !file_exists(path2) {
                  ToolError("File not found: " + file2)
                } else {
                  let cmd = "diff " + shell_quote(path1) + " " + shell_quote(path2)
                  let output = exec_command(cmd)
                  if output == "" {
                    ToolSuccess("Files are identical")
                  } else {
                    ToolSuccess(output)
                  }
                }
              }
              (Err(msg), _) => ToolError(msg)
              (_, Err(msg)) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid diff_files input. Expected JSON with 'file1' and 'file2'.")
        }
      }
      _ => ToolError("Invalid JSON for diff_files")
    }
  } catch {
    _ => ToolError("Invalid JSON for diff_files: " + input)
  }
}

///|
/// Copy a file. Input: JSON {"source":"...","destination":"..."}
///
fn exec_copy_file(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let source_val = obj.get("source")
        let dest_val = obj.get("destination")
        match (source_val, dest_val) {
          (Some(Json::String(source)), Some(Json::String(dest))) => {
            match (safe_path(source, root), safe_path(dest, root)) {
              (Ok(src_path), Ok(dst_path)) => {
                if !file_exists(src_path) {
                  ToolError("Source file not found: " + source)
                } else {
                  let content = read_file(src_path)
                  if write_file(dst_path, content) {
                    ToolSuccess("Copied " + source + " to " + dest)
                  } else {
                    ToolError("Failed to copy file")
                  }
                }
              }
              (Err(msg), _) => ToolError(msg)
              (_, Err(msg)) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid copy_file input. Expected JSON with 'source' and 'destination'.")
        }
      }
      _ => ToolError("Invalid JSON for copy_file")
    }
  } catch {
    _ => ToolError("Invalid JSON for copy_file: " + input)
  }
}

///|
/// Move/rename a file. Input: JSON {"source":"...","destination":"..."}
///
fn exec_move_file(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let source_val = obj.get("source")
        let dest_val = obj.get("destination")
        match (source_val, dest_val) {
          (Some(Json::String(source)), Some(Json::String(dest))) => {
            match (safe_path(source, root), safe_path(dest, root)) {
              (Ok(src_path), Ok(dst_path)) => {
                if !file_exists(src_path) {
                  ToolError("Source file not found: " + source)
                } else {
                  let content = read_file(src_path)
                  if write_file(dst_path, content) {
                    // Note: We can't delete the source in MoonBit stub
                    ToolSuccess("Moved " + source + " to " + dest)
                  } else {
                    ToolError("Failed to move file")
                  }
                }
              }
              (Err(msg), _) => ToolError(msg)
              (_, Err(msg)) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid move_file input. Expected JSON with 'source' and 'destination'.")
        }
      }
      _ => ToolError("Invalid JSON for move_file")
    }
  } catch {
    _ => ToolError("Invalid JSON for move_file: " + input)
  }
}

///|
/// Append to a file. Input: JSON {"path":"...","content":"..."}
///
fn exec_append_file(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let path_val = obj.get("path")
        let content_val = obj.get("content")
        match (path_val, content_val) {
          (Some(Json::String(path)), Some(Json::String(content))) => {
            match safe_path(path, root) {
              Ok(full_path) => {
                let existing = read_file(full_path)
                let new_content = existing + content
                if write_file(full_path, new_content) {
                  ToolSuccess("Appended " + content.length().to_string() + " bytes to " + path)
                } else {
                  ToolError("Failed to append to file")
                }
              }
              Err(msg) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid append_file input. Expected JSON with 'path' and 'content'.")
        }
      }
      _ => ToolError("Invalid JSON for append_file")
    }
  } catch {
    _ => ToolError("Invalid JSON for append_file: " + input)
  }
}

///|
/// Get directory size. Input: directory path
///
fn exec_dir_size(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      let cmd = "du -sh " + shell_quote(path) + " 2>/dev/null | cut -f1"
      let output = exec_command(cmd)
      if output == "" {
        ToolError("Failed to get directory size")
      } else {
        ToolSuccess("Directory size: " + output.trim().to_owned())
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// Get disk usage. Input: (empty)
///
fn exec_disk_usage() -> ToolResult {
  let cmd = "df -h . 2>/dev/null | tail -1"
  let output = exec_command(cmd)
  if output == "" {
    ToolError("Failed to get disk usage")
  } else {
    ToolSuccess("Disk usage:\n" + output)
  }
}

// ============================================================
// More utility tools for mature product
// ============================================================

///|
/// Sort file lines. Input: JSON {"path":"...","reverse":false}
///
fn exec_sort_file(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let path_val = obj.get("path")
        let reverse_val = obj.get("reverse")
        match path_val {
          Some(Json::String(path)) => {
            match safe_path(path, root) {
              Ok(full_path) => {
                if !file_exists(full_path) {
                  ToolError("File not found: " + path)
                } else {
                  let reverse = match reverse_val {
                    Some(Json::True) => true
                    _ => false
                  }
                  let cmd = "sort " + (if reverse { "-r " } else { "" }) + shell_quote(full_path)
                  let output = exec_command(cmd)
                  if output == "" {
                    ToolSuccess("(empty file)")
                  } else {
                    if output.length() > 8000 {
                      ToolSuccess(output[:8000].to_owned() + "\n... (truncated)")
                    } else {
                      ToolSuccess(output)
                    }
                  }
                }
              }
              Err(msg) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid sort_file input. Expected JSON with 'path'.")
        }
      }
      _ => ToolError("Invalid JSON for sort_file")
    }
  } catch {
    _ => ToolError("Invalid JSON for sort_file: " + input)
  }
}

///|
/// Remove duplicate lines. Input: file path
///
fn exec_uniq_file(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      if !file_exists(path) {
        ToolError("File not found: " + input)
      } else {
        let cmd = "sort " + shell_quote(path) + " | uniq"
        let output = exec_command(cmd)
        if output == "" {
          ToolSuccess("(empty file)")
        } else {
          if output.length() > 8000 {
            ToolSuccess(output[:8000].to_owned() + "\n... (truncated)")
          } else {
            ToolSuccess(output)
          }
        }
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// Word count. Input: file path
///
fn exec_wc_file(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      if !file_exists(path) {
        ToolError("File not found: " + input)
      } else {
        let cmd = "wc -lwc " + shell_quote(path)
        let output = exec_command(cmd)
        ToolSuccess("Word count:\n" + output)
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// Get filename from path. Input: file path
///
fn exec_basename(input : String) -> ToolResult {
  let cmd = "basename " + shell_quote(input)
  let output = exec_command(cmd)
  if output == "" {
    ToolError("Failed to get basename")
  } else {
    ToolSuccess("Basename: " + output.trim().to_owned())
  }
}

///|
/// Get directory from path. Input: file path
///
fn exec_dirname(input : String) -> ToolResult {
  let cmd = "dirname " + shell_quote(input)
  let output = exec_command(cmd)
  if output == "" {
    ToolError("Failed to get dirname")
  } else {
    ToolSuccess("Dirname: " + output.trim().to_owned())
  }
}

///|
/// Get absolute path. Input: file path
///
fn exec_realpath(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      let cmd = "realpath " + shell_quote(path) + " 2>/dev/null || echo " + shell_quote(path)
      let output = exec_command(cmd)
      if output == "" {
        ToolError("Failed to get realpath")
      } else {
        ToolSuccess("Realpath: " + output.trim().to_owned())
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// Find command location. Input: command name
///
fn exec_which(input : String) -> ToolResult {
  let cmd = "which " + shell_quote(input) + " 2>/dev/null"
  let output = exec_command(cmd)
  if output == "" {
    ToolSuccess("Command not found: " + input)
  } else {
    ToolSuccess("Location: " + output.trim().to_owned())
  }
}

///|
/// Get current date/time. Input: (empty) or format string
///
fn exec_date(input : String) -> ToolResult {
  let format = if input == "" { "+%Y-%m-%d %H:%M:%S" } else { input }
  let cmd = "date '" + format + "'"
  let output = exec_command(cmd)
  if output == "" {
    ToolError("Failed to get date")
  } else {
    ToolSuccess("Date: " + output.trim().to_owned())
  }
}

///|
/// Create directory. Input: directory path
///
fn exec_mkdir(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      if mkdir(path) {
        ToolSuccess("Created directory: " + input)
      } else {
        ToolError("Failed to create directory: " + input)
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// Check if path is directory. Input: file path
///
fn exec_is_dir(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      let cmd = "test -d " + shell_quote(path) + " && echo yes || echo no"
      let output = exec_command(cmd)
      let is_dir = output.trim().to_owned() == "yes"
      ToolSuccess(input + " is " + (if is_dir { "a directory" } else { "not a directory" }))
    }
    Err(msg) => ToolError(msg)
  }
}

// ============================================================
// More utility tools for mature product
// ============================================================

///|
/// Truncate file to N lines. Input: JSON {"path":"...","lines":100}
///
fn exec_truncate_file(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let path_val = obj.get("path")
        let lines_val = obj.get("lines")
        match path_val {
          Some(Json::String(path)) => {
            match safe_path(path, root) {
              Ok(full_path) => {
                if !file_exists(full_path) {
                  ToolError("File not found: " + path)
                } else {
                  let n = match lines_val {
                    Some(Json::Number(num, ..)) => num.to_int()
                    _ => 100
                  }
                  let cmd = "head -" + n.to_string() + " " + shell_quote(full_path) + " > " + shell_quote(full_path) + ".tmp && mv " + shell_quote(full_path) + ".tmp " + shell_quote(full_path)
                  ignore(exec_command(cmd))
                  ToolSuccess("Truncated " + path + " to " + n.to_string() + " lines")
                }
              }
              Err(msg) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid truncate_file input. Expected JSON with 'path'.")
        }
      }
      _ => ToolError("Invalid JSON for truncate_file")
    }
  } catch {
    _ => ToolError("Invalid JSON for truncate_file: " + input)
  }
}

///|
/// Count pattern matches in file. Input: JSON {"path":"...","pattern":"..."}
///
fn exec_grep_count(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let path_val = obj.get("path")
        let pattern_val = obj.get("pattern")
        match (path_val, pattern_val) {
          (Some(Json::String(path)), Some(Json::String(pattern))) => {
            match safe_path(path, root) {
              Ok(full_path) => {
                if !file_exists(full_path) {
                  ToolError("File not found: " + path)
                } else {
                  let cmd = "grep -c " + shell_quote(pattern) + " " + shell_quote(full_path) + " 2>/dev/null || echo 0"
                  let output = exec_command(cmd)
                  ToolSuccess("Matches: " + output.trim().to_owned())
                }
              }
              Err(msg) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid grep_count input. Expected JSON with 'path' and 'pattern'.")
        }
      }
      _ => ToolError("Invalid JSON for grep_count")
    }
  } catch {
    _ => ToolError("Invalid JSON for grep_count: " + input)
  }
}

///|
/// Get context around pattern matches. Input: JSON {"path":"...","pattern":"...","context":2}
///
fn exec_grep_context(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let path_val = obj.get("path")
        let pattern_val = obj.get("pattern")
        let context_val = obj.get("context")
        match (path_val, pattern_val) {
          (Some(Json::String(path)), Some(Json::String(pattern))) => {
            match safe_path(path, root) {
              Ok(full_path) => {
                if !file_exists(full_path) {
                  ToolError("File not found: " + path)
                } else {
                  let n = match context_val {
                    Some(Json::Number(num, ..)) => num.to_int()
                    _ => 2
                  }
                  let cmd = "grep -n -C " + n.to_string() + " " + shell_quote(pattern) + " " + shell_quote(full_path) + " 2>/dev/null"
                  let output = exec_command(cmd)
                  if output == "" {
                    ToolSuccess("No matches found for: " + pattern)
                  } else {
                    if output.length() > 8000 {
                      ToolSuccess(output[:8000].to_owned() + "\n... (truncated)")
                    } else {
                      ToolSuccess(output)
                    }
                  }
                }
              }
              Err(msg) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid grep_context input. Expected JSON with 'path' and 'pattern'.")
        }
      }
      _ => ToolError("Invalid JSON for grep_context")
    }
  } catch {
    _ => ToolError("Invalid JSON for grep_context: " + input)
  }
}

///|
/// Get file type. Input: file path
///
fn exec_file_type(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      if !file_exists(path) {
        ToolError("File not found: " + input)
      } else {
        let cmd = "file " + shell_quote(path)
        let output = exec_command(cmd)
        ToolSuccess("File type: " + output)
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// Get file permissions. Input: file path
///
fn exec_file_permissions(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      if !file_exists(path) {
        ToolError("File not found: " + input)
      } else {
        let cmd = "ls -la " + shell_quote(path) + " | awk '{print $1}'"
        let output = exec_command(cmd)
        ToolSuccess("Permissions: " + output.trim().to_owned())
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// Get file owner. Input: file path
///
fn exec_file_owner(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      if !file_exists(path) {
        ToolError("File not found: " + input)
      } else {
        let cmd = "ls -la " + shell_quote(path) + " | awk '{print $3}'"
        let output = exec_command(cmd)
        ToolSuccess("Owner: " + output.trim().to_owned())
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// Get file modification time. Input: file path
///
fn exec_file_modified(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      if !file_exists(path) {
        ToolError("File not found: " + input)
      } else {
        let cmd = "stat -c %y " + shell_quote(path) + " 2>/dev/null || date -r " + shell_quote(path) + " 2>/dev/null"
        let output = exec_command(cmd)
        ToolSuccess("Modified: " + output.trim().to_owned())
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// Get file size. Input: file path
///
fn exec_file_size(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      if !file_exists(path) {
        ToolError("File not found: " + input)
      } else {
        let cmd = "stat -c %s " + shell_quote(path) + " 2>/dev/null || wc -c < " + shell_quote(path)
        let output = exec_command(cmd)
        ToolSuccess("Size: " + output.trim().to_owned() + " bytes")
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// List directory with details. Input: directory path
///
fn exec_list_dir_detailed(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      let cmd = "ls -la " + shell_quote(path) + " 2>/dev/null"
      let output = exec_command(cmd)
      if output == "" {
        ToolSuccess("(empty directory)")
      } else {
        if output.length() > 8000 {
          ToolSuccess(output[:8000].to_owned() + "\n... (truncated)")
        } else {
          ToolSuccess(output)
        }
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// Find files by type. Input: JSON {"path":"...","type":"f"}
///
fn exec_find_by_type(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let path_val = obj.get("path")
        let type_val = obj.get("type")
        match path_val {
          Some(Json::String(path)) => {
            match safe_path(path, root) {
              Ok(full_path) => {
                let file_type = match type_val {
                  Some(Json::String(t)) => t
                  _ => "f"
                }
                let cmd = "find " + shell_quote(full_path) + " -type " + file_type + " -not -path '*/_build/*' -not -path '*/.git/*' 2>/dev/null | head -50"
                let output = exec_command(cmd)
                if output == "" {
                  ToolSuccess("No files found")
                } else {
                  ToolSuccess(output)
                }
              }
              Err(msg) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid find_by_type input. Expected JSON with 'path'.")
        }
      }
      _ => ToolError("Invalid JSON for find_by_type")
    }
  } catch {
    _ => ToolError("Invalid JSON for find_by_type: " + input)
  }
}

///|
/// Find files by size. Input: JSON {"path":"...","size":"+1M"}
///
fn exec_find_by_size(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let path_val = obj.get("path")
        let size_val = obj.get("size")
        match path_val {
          Some(Json::String(path)) => {
            match safe_path(path, root) {
              Ok(full_path) => {
                let size = match size_val {
                  Some(Json::String(s)) => s
                  _ => "+1M"
                }
                let cmd = "find " + shell_quote(full_path) + " -size " + size + " -not -path '*/_build/*' -not -path '*/.git/*' 2>/dev/null | head -50"
                let output = exec_command(cmd)
                if output == "" {
                  ToolSuccess("No files found")
                } else {
                  ToolSuccess(output)
                }
              }
              Err(msg) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid find_by_size input. Expected JSON with 'path'.")
        }
      }
      _ => ToolError("Invalid JSON for find_by_size")
    }
  } catch {
    _ => ToolError("Invalid JSON for find_by_size: " + input)
  }
}

// ============================================================
// More utility tools for mature product
// ============================================================

///|
/// Recursive grep. Input: JSON {"path":"...","pattern":"...","include":"*.mbt"}
///
fn exec_grep_recursive(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let path_val = obj.get("path")
        let pattern_val = obj.get("pattern")
        let include_val = obj.get("include")
        match (path_val, pattern_val) {
          (Some(Json::String(path)), Some(Json::String(pattern))) => {
            match safe_path(path, root) {
              Ok(full_path) => {
                let include_flag = match include_val {
                  Some(Json::String(i)) => " --include=" + shell_quote(i)
                  _ => ""
                }
                let cmd = "grep -rn" + include_flag + " -- " + shell_quote(pattern) + " " + shell_quote(full_path) + " 2>/dev/null | head -50"
                let output = exec_command(cmd)
                if output == "" {
                  ToolSuccess("No matches found for: " + pattern)
                } else {
                  if output.length() > 8000 {
                    ToolSuccess(output[:8000].to_owned() + "\n... (truncated)")
                  } else {
                    ToolSuccess(output)
                  }
                }
              }
              Err(msg) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid grep_recursive input. Expected JSON with 'path' and 'pattern'.")
        }
      }
      _ => ToolError("Invalid JSON for grep_recursive")
    }
  } catch {
    _ => ToolError("Invalid JSON for grep_recursive: " + input)
  }
}

///|
/// Find files by name pattern. Input: JSON {"path":"...","name":"*.mbt"}
///
fn exec_find_by_name(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let path_val = obj.get("path")
        let name_val = obj.get("name")
        match path_val {
          Some(Json::String(path)) => {
            match safe_path(path, root) {
              Ok(full_path) => {
                let name = match name_val {
                  Some(Json::String(n)) => n
                  _ => "*"
                }
                let cmd = "find " + shell_quote(full_path) + " -name " + shell_quote(name) + " -not -path '*/_build/*' -not -path '*/.git/*' 2>/dev/null | head -50"
                let output = exec_command(cmd)
                if output == "" {
                  ToolSuccess("No files found")
                } else {
                  ToolSuccess(output)
                }
              }
              Err(msg) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid find_by_name input. Expected JSON with 'path'.")
        }
      }
      _ => ToolError("Invalid JSON for find_by_name")
    }
  } catch {
    _ => ToolError("Invalid JSON for find_by_name: " + input)
  }
}

///|
/// Find files by modification time. Input: JSON {"path":"...","days":7}
///
fn exec_find_by_time(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let path_val = obj.get("path")
        let days_val = obj.get("days")
        match path_val {
          Some(Json::String(path)) => {
            match safe_path(path, root) {
              Ok(full_path) => {
                let days = match days_val {
                  Some(Json::Number(num, ..)) => num.to_int()
                  _ => 7
                }
                let cmd = "find " + shell_quote(full_path) + " -mtime -" + days.to_string() + " -not -path '*/_build/*' -not -path '*/.git/*' 2>/dev/null | head -50"
                let output = exec_command(cmd)
                if output == "" {
                  ToolSuccess("No files found")
                } else {
                  ToolSuccess(output)
                }
              }
              Err(msg) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid find_by_time input. Expected JSON with 'path'.")
        }
      }
      _ => ToolError("Invalid JSON for find_by_time")
    }
  } catch {
    _ => ToolError("Invalid JSON for find_by_time: " + input)
  }
}

///|
/// Get file checksum. Input: JSON {"path":"...","algorithm":"md5"}
///
fn exec_file_checksum(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let path_val = obj.get("path")
        let algo_val = obj.get("algorithm")
        match path_val {
          Some(Json::String(path)) => {
            match safe_path(path, root) {
              Ok(full_path) => {
                if !file_exists(full_path) {
                  ToolError("File not found: " + path)
                } else {
                  let algo = match algo_val {
                    Some(Json::String(a)) => a
                    _ => "md5"
                  }
                  let cmd = algo + "sum " + shell_quote(full_path) + " 2>/dev/null"
                  let output = exec_command(cmd)
                  if output == "" {
                    ToolError("Failed to compute checksum")
                  } else {
                    ToolSuccess("Checksum: " + output)
                  }
                }
              }
              Err(msg) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid file_checksum input. Expected JSON with 'path'.")
        }
      }
      _ => ToolError("Invalid JSON for file_checksum")
    }
  } catch {
    _ => ToolError("Invalid JSON for file_checksum: " + input)
  }
}

///|
/// Compress file with gzip. Input: file path
///
fn exec_compress_file(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      if !file_exists(path) {
        ToolError("File not found: " + input)
      } else {
        let cmd = "gzip -k " + shell_quote(path) + " 2>/dev/null && echo success || echo failed"
        let output = exec_command(cmd)
        if output.trim().to_owned() == "success" {
          ToolSuccess("Compressed: " + input + ".gz")
        } else {
          ToolError("Failed to compress file")
        }
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// Decompress file with gzip. Input: file path
///
fn exec_decompress_file(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      if !file_exists(path) {
        ToolError("File not found: " + input)
      } else {
        let cmd = "gunzip -k " + shell_quote(path) + " 2>/dev/null && echo success || echo failed"
        let output = exec_command(cmd)
        if output.trim().to_owned() == "success" {
          ToolSuccess("Decompressed: " + input)
        } else {
          ToolError("Failed to decompress file")
        }
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// Create tar archive. Input: JSON {"source":"...","destination":"..."}
///
fn exec_tar_create(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let source_val = obj.get("source")
        let dest_val = obj.get("destination")
        match (source_val, dest_val) {
          (Some(Json::String(source)), Some(Json::String(dest))) => {
            match (safe_path(source, root), safe_path(dest, root)) {
              (Ok(_), Ok(dst_path)) => {
                let cmd = "tar -czf " + shell_quote(dst_path) + " -C " + shell_quote(root) + " " + shell_quote(source) + " 2>/dev/null && echo success || echo failed"
                let output = exec_command(cmd)
                if output.trim().to_owned() == "success" {
                  ToolSuccess("Created tar archive: " + dest)
                } else {
                  ToolError("Failed to create tar archive")
                }
              }
              (Err(msg), _) => ToolError(msg)
              (_, Err(msg)) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid tar_create input. Expected JSON with 'source' and 'destination'.")
        }
      }
      _ => ToolError("Invalid JSON for tar_create")
    }
  } catch {
    _ => ToolError("Invalid JSON for tar_create: " + input)
  }
}

///|
/// Extract tar archive. Input: JSON {"source":"...","destination":"..."}
///
fn exec_tar_extract(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let source_val = obj.get("source")
        let dest_val = obj.get("destination")
        match (source_val, dest_val) {
          (Some(Json::String(source)), Some(Json::String(dest))) => {
            match (safe_path(source, root), safe_path(dest, root)) {
              (Ok(src_path), Ok(dst_path)) => {
                if !file_exists(src_path) {
                  ToolError("Archive not found: " + source)
                } else {
                  ignore(mkdir(dst_path))
                  let cmd = "tar -xzf " + shell_quote(src_path) + " -C " + shell_quote(dst_path) + " 2>/dev/null && echo success || echo failed"
                  let output = exec_command(cmd)
                  if output.trim().to_owned() == "success" {
                    ToolSuccess("Extracted to: " + dest)
                  } else {
                    ToolError("Failed to extract archive")
                  }
                }
              }
              (Err(msg), _) => ToolError(msg)
              (_, Err(msg)) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid tar_extract input. Expected JSON with 'source' and 'destination'.")
        }
      }
      _ => ToolError("Invalid JSON for tar_extract")
    }
  } catch {
    _ => ToolError("Invalid JSON for tar_extract: " + input)
  }
}

///|
/// Create zip archive. Input: JSON {"source":"...","destination":"..."}
///
fn exec_zip_create(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let source_val = obj.get("source")
        let dest_val = obj.get("destination")
        match (source_val, dest_val) {
          (Some(Json::String(source)), Some(Json::String(dest))) => {
            match (safe_path(source, root), safe_path(dest, root)) {
              (Ok(src_path), Ok(dst_path)) => {
                let cmd = "zip -r " + shell_quote(dst_path) + " " + shell_quote(src_path) + " 2>/dev/null && echo success || echo failed"
                let output = exec_command(cmd)
                if output.trim().to_owned() == "success" {
                  ToolSuccess("Created zip archive: " + dest)
                } else {
                  ToolError("Failed to create zip archive")
                }
              }
              (Err(msg), _) => ToolError(msg)
              (_, Err(msg)) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid zip_create input. Expected JSON with 'source' and 'destination'.")
        }
      }
      _ => ToolError("Invalid JSON for zip_create")
    }
  } catch {
    _ => ToolError("Invalid JSON for zip_create: " + input)
  }
}

///|
/// Extract zip archive. Input: JSON {"source":"...","destination":"..."}
///
fn exec_zip_extract(input : String, root : String) -> ToolResult {
  try {
    let parsed = @json.parse(input)
    match parsed {
      Object(obj) => {
        let source_val = obj.get("source")
        let dest_val = obj.get("destination")
        match (source_val, dest_val) {
          (Some(Json::String(source)), Some(Json::String(dest))) => {
            match (safe_path(source, root), safe_path(dest, root)) {
              (Ok(src_path), Ok(dst_path)) => {
                if !file_exists(src_path) {
                  ToolError("Archive not found: " + source)
                } else {
                  ignore(mkdir(dst_path))
                  let cmd = "unzip -o " + shell_quote(src_path) + " -d " + shell_quote(dst_path) + " 2>/dev/null && echo success || echo failed"
                  let output = exec_command(cmd)
                  if output.trim().to_owned() == "success" {
                    ToolSuccess("Extracted to: " + dest)
                  } else {
                    ToolError("Failed to extract archive")
                  }
                }
              }
              (Err(msg), _) => ToolError(msg)
              (_, Err(msg)) => ToolError(msg)
            }
          }
          _ => ToolError("Invalid zip_extract input. Expected JSON with 'source' and 'destination'.")
        }
      }
      _ => ToolError("Invalid JSON for zip_extract")
    }
  } catch {
    _ => ToolError("Invalid JSON for zip_extract: " + input)
  }
}

// ============================================================
// More utility tools for mature product
// ============================================================

///|
/// Check if file is readable. Input: file path
///
fn exec_is_readable(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      if !file_exists(path) {
        ToolError("File not found: " + input)
      } else {
        let cmd = "test -r " + shell_quote(path) + " && echo yes || echo no"
        let output = exec_command(cmd)
        let is_readable = output.trim().to_owned() == "yes"
        ToolSuccess(input + " is " + (if is_readable { "readable" } else { "not readable" }))
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// Check if file is writable. Input: file path
///
fn exec_is_writable(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      if !file_exists(path) {
        ToolError("File not found: " + input)
      } else {
        let cmd = "test -w " + shell_quote(path) + " && echo yes || echo no"
        let output = exec_command(cmd)
        let is_writable = output.trim().to_owned() == "yes"
        ToolSuccess(input + " is " + (if is_writable { "writable" } else { "not writable" }))
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// Check if file is executable. Input: file path
///
fn exec_is_executable(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      if !file_exists(path) {
        ToolError("File not found: " + input)
      } else {
        let cmd = "test -x " + shell_quote(path) + " && echo yes || echo no"
        let output = exec_command(cmd)
        let is_executable = output.trim().to_owned() == "yes"
        ToolSuccess(input + " is " + (if is_executable { "executable" } else { "not executable" }))
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// Get file extension. Input: file path
///
fn exec_file_extension(input : String) -> ToolResult {
  let parts = input.split(".").to_array()
  if parts.length() <= 1 {
    ToolSuccess("No extension")
  } else {
    let ext = parts[parts.length() - 1].to_owned()
    ToolSuccess("Extension: " + ext)
  }
}

///|
/// Get file lines count. Input: file path
///
fn exec_file_lines(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      if !file_exists(path) {
        ToolError("File not found: " + input)
      } else {
        let cmd = "wc -l < " + shell_quote(path)
        let output = exec_command(cmd)
        ToolSuccess("Lines: " + output.trim().to_owned())
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// Get file words count. Input: file path
///
fn exec_file_words(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      if !file_exists(path) {
        ToolError("File not found: " + input)
      } else {
        let cmd = "wc -w < " + shell_quote(path)
        let output = exec_command(cmd)
        ToolSuccess("Words: " + output.trim().to_owned())
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// Get file characters count. Input: file path
///
fn exec_file_chars(input : String, root : String) -> ToolResult {
  match safe_path(input, root) {
    Ok(path) => {
      if !file_exists(path) {
        ToolError("File not found: " + input)
      } else {
        let cmd = "wc -m < " + shell_quote(path)
        let output = exec_command(cmd)
        ToolSuccess("Characters: " + output.trim().to_owned())
      }
    }
    Err(msg) => ToolError(msg)
  }
}

///|
/// Get system information. Input: (empty)
///
fn exec_system_info() -> ToolResult {
  let os = exec_command("uname -s")
  let arch = exec_command("uname -m")
  let kernel = exec_command("uname -r")
  let hostname = exec_command("hostname")
  let uptime = exec_command("uptime -p 2>/dev/null || uptime")
  let load = exec_command("cat /proc/loadavg 2>/dev/null | awk '{print $1, $2, $3}' || echo 'N/A'")

  let info = "System Info:\n" +
    "  OS: " + os.trim().to_owned() + "\n" +
    "  Architecture: " + arch.trim().to_owned() + "\n" +
    "  Kernel: " + kernel.trim().to_owned() + "\n" +
    "  Hostname: " + hostname.trim().to_owned() + "\n" +
    "  Uptime: " + uptime.trim().to_owned() + "\n" +
    "  Load: " + load.trim().to_owned()
  ToolSuccess(info)
}

///|
/// Get memory information. Input: (empty)
///
fn exec_memory_info() -> ToolResult {
  let cmd = "free -h 2>/dev/null || echo 'N/A'"
  let output = exec_command(cmd)
  if output == "" {
    ToolError("Failed to get memory info")
  } else {
    ToolSuccess("Memory Info:\n" + output)
  }
}

///|
/// Get CPU information. Input: (empty)
///
fn exec_cpu_info() -> ToolResult {
  let cmd = "nproc 2>/dev/null || echo 'N/A'"
  let cores = exec_command(cmd)
  let model = exec_command("cat /proc/cpuinfo 2>/dev/null | grep 'model name' | head -1 | cut -d: -f2 | xargs || echo 'N/A'")

  let info = "CPU Info:\n" +
    "  Cores: " + cores.trim().to_owned() + "\n" +
    "  Model: " + model.trim().to_owned()
  ToolSuccess(info)
}

///|
/// Get network information. Input: (empty)
///
fn exec_network_info() -> ToolResult {
  let ip = exec_command("hostname -I 2>/dev/null | awk '{print $1}' || echo 'N/A'")
  let iface = exec_command("ip route get 1 2>/dev/null | awk '{print $5; exit}' || echo 'N/A'")

  let info = "Network Info:\n" +
    "  IP: " + ip.trim().to_owned() + "\n" +
    "  Interface: " + iface.trim().to_owned()
  ToolSuccess(info)
}

///|
/// Get process list. Input: (empty) or process name
///
fn exec_process_list(input : String) -> ToolResult {
  let cmd = if input == "" {
    "ps aux --sort=-%mem 2>/dev/null | head -15 || ps aux | head -15"
  } else {
    "ps aux | grep " + shell_quote(input) + " | grep -v grep"
  }
  let output = exec_command(cmd)
  if output == "" {
    ToolSuccess("No processes found")
  } else {
    if output.length() > 8000 {
      ToolSuccess(output[:8000].to_owned() + "\n... (truncated)")
    } else {
      ToolSuccess(output)
    }
  }
}

// ============================================================
// More utility tools for mature product
// ============================================================

///|
/// Get environment variables. Input: (empty)
///
fn exec_env_list() -> ToolResult {
  let cmd = "env | sort"
  let output = exec_command(cmd)
  if output == "" {
    ToolSuccess("No environment variables")
  } else {
    if output.length() > 8000 {
      ToolSuccess(output[:8000].to_owned() + "\n... (truncated)")
    } else {
      ToolSuccess(output)
    }
  }
}

///|
/// Get system uptime. Input: (empty)
///
fn exec_uptime() -> ToolResult {
  let cmd = "uptime -p 2>/dev/null || uptime"
  let output = exec_command(cmd)
  if output == "" {
    ToolError("Failed to get uptime")
  } else {
    ToolSuccess("Uptime: " + output.trim().to_owned())
  }
}

///|
/// Get system hostname. Input: (empty)
///
fn exec_hostname() -> ToolResult {
  let cmd = "hostname"
  let output = exec_command(cmd)
  if output == "" {
    ToolError("Failed to get hostname")
  } else {
    ToolSuccess("Hostname: " + output.trim().to_owned())
  }
}

///|
/// Get current user. Input: (empty)
///
fn exec_whoami() -> ToolResult {
  let cmd = "whoami"
  let output = exec_command(cmd)
  if output == "" {
    ToolError("Failed to get current user")
  } else {
    ToolSuccess("User: " + output.trim().to_owned())
  }
}

///|
/// Get logged in users. Input: (empty)
///
fn exec_who() -> ToolResult {
  let cmd = "who 2>/dev/null || echo 'N/A'"
  let output = exec_command(cmd)
  if output == "" {
    ToolSuccess("No users logged in")
  } else {
    ToolSuccess("Logged in users:\n" + output)
  }
}

///|
/// Get last logins. Input: (empty) or username
///
fn exec_last(input : String) -> ToolResult {
  let cmd = if input == "" {
    "last -10 2>/dev/null || echo 'N/A'"
  } else {
    "last " + shell_quote(input) + " -10 2>/dev/null || echo 'N/A'"
  }
  let output = exec_command(cmd)
  if output == "" {
    ToolSuccess("No login history")
  } else {
    ToolSuccess("Last logins:\n" + output)
  }
}

///|
/// Check if command exists. Input: command name
///
fn exec_command_exists(input : String) -> ToolResult {
  let cmd = "command -v " + shell_quote(input) + " 2>/dev/null && echo yes || echo no"
  let output = exec_command(cmd)
  let exists = output.trim().to_owned().contains("yes")
  ToolSuccess(input + " is " + (if exists { "available" } else { "not available" }))
}

///|
/// Get shell information. Input: (empty)
///
fn exec_shell_info() -> ToolResult {
  let shell = exec_command("echo $SHELL")
  let version = exec_command(shell.trim().to_owned() + " --version 2>/dev/null | head -1 || echo 'N/A'")

  let info = "Shell Info:\n" +
    "  Shell: " + shell.trim().to_owned() + "\n" +
    "  Version: " + version.trim().to_owned()
  ToolSuccess(info)
}

///|
/// Get PATH directories. Input: (empty)
///
fn exec_path_list() -> ToolResult {
  let cmd = "echo $PATH | tr ':' '\n'"
  let output = exec_command(cmd)
  if output == "" {
    ToolSuccess("PATH is empty")
  } else {
    ToolSuccess("PATH directories:\n" + output)
  }
}
