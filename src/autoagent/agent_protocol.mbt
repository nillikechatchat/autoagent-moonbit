///|
pub(all) struct APIMessage {
  role : String
  content : String
}

///|
pub fn escape_json(s : String) -> String {
  let mut out = ""
  for c in s {
    if c == '\n' {
      out = out + "\\n"
    } else if c == '\r' {
      out = out + "\\r"
    } else if c == '\t' {
      out = out + "\\t"
    } else if c == '"' {
      out = out + "\\\""
    } else if c == '\\' {
      out = out + "\\\\"
    } else {
      out = out + c.to_string()
    }
  }
  out
}

///|
pub fn render_llm_request(messages : Array[APIMessage]) -> String {
  let mut out = "{\"type\":\"llm_call\",\"messages\":["
  for i, msg in messages {
    if i > 0 { out = out + "," }
    out = out + "{\"role\":\"" + msg.role + "\",\"content\":\"" + escape_json(msg.content) + "\"}"
  }
  out = out + "]}"
  out
}

///|
pub fn render_tool_call(tool_name : String, tool_input : String) -> String {
  "{\"type\":\"tool_call\",\"tool\":\"" + tool_name + "\",\"input\":\"" + escape_json(tool_input) + "\"}"
}

///|
pub fn render_final_answer(answer : String) -> String {
  "{\"type\":\"final_answer\",\"answer\":\"" + escape_json(answer) + "\"}"
}

///|
pub fn render_error(msg : String) -> String {
  "{\"type\":\"error\",\"message\":\"" + escape_json(msg) + "\"}"
}
