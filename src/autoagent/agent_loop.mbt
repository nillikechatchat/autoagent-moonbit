///|
pub(all) enum AgentAction {
  Think(String)
  CallTool(String, String)
  Reply(String)
  Error(String)
}

///|
pub fn AgentAction::to_json(self : AgentAction) -> String {
  match self {
    Think(reason) => "{\"action\":\"think\",\"reason\":\"" + esc(reason) + "\"}"
    CallTool(name, input) => "{\"action\":\"tool\",\"name\":\"" + esc(name) + "\",\"input\":\"" + esc(input) + "\"}"
    Reply(text) => "{\"action\":\"reply\",\"text\":\"" + esc(text) + "\"}"
    Error(msg) => "{\"action\":\"error\",\"message\":\"" + esc(msg) + "\"}"
  }
}

///|
pub fn esc(s : String) -> String {
  let mut out = ""
  for c in s {
    if c == '\n' { out = out + "\\n" }
    else if c == '\r' { out = out + "\\r" }
    else if c == '\t' { out = out + "\\t" }
    else if c == '"' { out = out + "\\\"" }
    else if c == '\\' { out = out + "\\\\" }
    else { out = out + c.to_string() }
  }
  out
}

///|
pub(all) struct Conversation {
  mut turns : Array[Turn]
}

///|
pub(all) struct Turn {
  role : String
  content : String
}

///|
pub fn Conversation::new() -> Conversation {
  { turns: [] }
}

///|
pub fn Conversation::add(self : Conversation, role : String, content : String) -> Unit {
  self.turns.push({ role, content })
}

///|
pub fn Conversation::last_user(self : Conversation) -> String {
  let mut i = self.turns.length() - 1
  while i >= 0 {
    if self.turns[i].role == "user" {
      return self.turns[i].content
    }
    i = i - 1
  }
  ""
}

///|
pub fn Conversation::has_tool_calls(self : Conversation) -> Bool {
  if self.turns.length() == 0 { return false }
  let last = self.turns[self.turns.length() - 1]
  last.role == "assistant" && last.content.contains("```tool")
}

///|
pub fn Conversation::extract_tool_call(self : Conversation) -> (String, String)? {
  if self.turns.length() == 0 { return None }
  let last = self.turns[self.turns.length() - 1]
  if !last.content.contains("```tool") { return None }

  let marker_start = "```tool"
  let marker_end = "```"
  let content = last.content

  // Find start
  let mut si = 0
  let mut found_start = false
  while si + marker_start.length() <= content.length() {
    if content[si:si + marker_start.length()] == marker_start {
      found_start = true
      break
    }
    si = si + 1
  }
  if !found_start { return None }

  // Find end
  let after_start = content[si + marker_start.length():]
  let trimmed = after_start.trim_start()
  let mut ei = 0
  let mut found_end = false
  while ei + marker_end.length() <= trimmed.length() {
    if trimmed[ei:ei + marker_end.length()] == marker_end {
      found_end = true
      break
    }
    ei = ei + 1
  }
  if !found_end { return None }

  let json_str = trimmed[0:ei].to_owned()
  let tool_name = json_field(json_str, "name")
  let tool_input = json_field(json_str, "input")
  Some((tool_name, tool_input))
}

///|
pub fn json_field(json : String, field : String) -> String {
  let search = "\"" + field + "\":"
  let mut i = 0
  while i + search.length() <= json.length() {
    if json[i:i + search.length()] == search {
      let after = json[i + search.length():]
      let trimmed = after.trim_start()
      if trimmed.has_prefix("\"") {
        let value = trimmed[1:]
        let mut ei = 0
        while ei < value.length() {
          // Handle escaped quotes
          if value[ei:ei+1].to_owned() == "\\" && ei + 1 < value.length() {
            ei = ei + 2
            continue
          }
          if value[ei:ei+1].to_owned() == "\"" { break }
          ei = ei + 1
        }
        // Unescape the value
        let raw = value[0:ei].to_owned()
        return unescape_json(raw)
      } else {
        let mut ei = 0
        while ei < trimmed.length() {
          let c = trimmed[ei:ei+1].to_owned()
          if c == "," || c == "}" || c == " " || c == "\n" { break }
          ei = ei + 1
        }
        return trimmed[0:ei].to_owned()
      }
    }
    i = i + 1
  }
  ""
}

///|
fn unescape_json(s : String) -> String {
  let mut out = ""
  let mut i = 0
  while i < s.length() {
    if s[i:i+1].to_owned() == "\\" && i + 1 < s.length() {
      let next = s[i+1:i+2].to_owned()
      if next == "n" { out = out + "\n" }
      else if next == "r" { out = out + "\r" }
      else if next == "t" { out = out + "\t" }
      else if next == "\"" { out = out + "\"" }
      else if next == "\\" { out = out + "\\" }
      else { out = out + next }
      i = i + 2
    } else {
      out = out + s[i:i+1].to_owned()
      i = i + 1
    }
  }
  out
}

///|
pub fn Conversation::to_messages_json(self : Conversation, system : String) -> String {
  let mut out = "[{\"role\":\"system\",\"content\":\"" + esc(system) + "\"}"
  for turn in self.turns {
    out = out + ",{\"role\":\"" + turn.role + "\",\"content\":\"" + esc(turn.content) + "\"}"
  }
  out = out + "]"
  out
}

///|
pub fn Conversation::remove_tool_block(self : Conversation) -> String {
  if self.turns.length() == 0 { return "" }
  let last = self.turns[self.turns.length() - 1]
  let content = last.content
  if !content.contains("```tool") { return content }

  // Remove ```tool ... ``` blocks
  let mut result = ""
  let mut i = 0
  while i < content.length() {
    if i + 7 <= content.length() && content[i:i+7] == "```tool" {
      // Skip until closing ```
      let mut j = i + 7
      while j + 3 <= content.length() {
        if content[j:j+3] == "```" {
          i = j + 3
          break
        }
        j = j + 1
      }
      if j + 3 > content.length() { break }
    } else {
      result = result + content[i:i+1].to_owned()
      i = i + 1
    }
  }
  result.trim_start().to_owned()
}
