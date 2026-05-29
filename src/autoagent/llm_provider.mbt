///|
/// LLM Provider - makes HTTP calls to OpenAI-compatible APIs.
/// Uses native C FFI for HTTP (no shell/Python dependency).
///

///|
pub struct LLMConfig {
  base_url : String
  api_key : String
  model : String
  timeout_seconds : Int
}

///|
pub struct LLMMessage {
  role : String
  content : String
}

///|
pub fn LLMConfig::from_env_and_file(config_path : String) -> LLMConfig {
  let mut api_key = get_env("MCAI_LLM_API_KEY")
  let mut base_url = get_env("MCAI_LLM_BASE_URL")
  let mut model = get_env("MCAI_LLM_MODEL")

  if api_key == "" {
    api_key = get_env("OPENAI_API_KEY")
  }

  // Fallback to config file
  if api_key == "" || base_url == "" || model == "" {
    let config_json = read_file(config_path)
    if config_json != "" {
      try {
        let parsed = @json.parse(config_json)
        match parsed {
          Object(root) => {
            let provider = root.get("provider")
            match provider {
              Some(p) => {
                if p is Object(po) {
                  if api_key == "" {
                    match po.get("api_key") {
                      Some(k) => { if k is Json::String(s) { api_key = s } }
                      None => ()
                    }
                  }
                  if base_url == "" {
                    match po.get("base_url") {
                      Some(u) => { if u is Json::String(s) { base_url = s } }
                      None => ()
                    }
                  }
                  if model == "" {
                    match po.get("model") {
                      Some(m) => { if m is Json::String(s) { model = s } }
                      None => ()
                    }
                  }
                }
              }
              None => ()
            }
          }
          _ => ()
        }
      } catch { _ => () }
    }
  }

  {
    base_url: if base_url == "" { "https://proxy.monkeycode-ai.com/v1" } else { base_url },
    api_key: api_key,
    model: if model == "" { "monkeycode-basic/qwen3.5-plus" } else { model },
    timeout_seconds: 60,
  }
}

///|
pub fn LLMConfig::is_configured(self : LLMConfig) -> Bool {
  self.api_key != ""
}

///|
/// Build JSON request body for chat completions
///
fn build_chat_request(model : String, messages : Array[LLMMessage]) -> String {
  let mut msgs_parts = ""
  for i in 0..<messages.length() {
    let m = messages[i]
    if i > 0 { msgs_parts = msgs_parts + "," }
    msgs_parts = msgs_parts + "{\"role\":\"" + m.role + "\",\"content\":\"" + m.content + "\"}"
  }
  "{\"model\":\"" + model + "\",\"messages\":[" + msgs_parts + "],\"temperature\":0.2,\"max_tokens\":2000}"
}

///|
/// Parse LLM response to extract the assistant message content
///
pub fn parse_llm_response(json_str : String) -> String {
  if json_str == "" { return "" }
  try {
    let parsed = @json.parse(json_str)
    match parsed {
      Object(obj) => {
        match obj.get("choices") {
          Some(Json::Array(choices)) => {
            if choices.length() > 0 {
              match choices[0] {
                Object(choice_obj) => {
                  match choice_obj.get("message") {
                    Some(msg) => {
                      match msg {
                        Object(msg_obj) => {
                          match msg_obj.get("content") {
                            Some(Json::String(content)) => content
                            _ => ""
                          }
                        }
                        _ => ""
                      }
                    }
                    None => ""
                  }
                }
                _ => ""
              }
            } else { "" }
          }
          _ => ""
        }
      }
      _ => ""
    }
  } catch { _ => "" }
}

///|
/// Call LLM API. Returns assistant message content.
///
pub fn LLMConfig::chat(self : LLMConfig, messages : Array[LLMMessage]) -> String {
  if !self.is_configured() { return "" }
  let url = self.base_url + "/chat/completions"
  let body = build_chat_request(self.model, messages)
  http_post(url, body, auth_token=self.api_key)
}

///|
/// Call LLM API with streaming. Prints chunks to stdout in real-time.
///
pub fn LLMConfig::chat_stream(self : LLMConfig, messages : Array[LLMMessage]) -> String {
  if !self.is_configured() { return "" }
  let url = self.base_url + "/chat/completions"
  let body = build_chat_request(self.model, messages)
  http_post_stream(url, body, auth_token=self.api_key)
}

///|
/// Call LLM API and return parsed content.
///
pub fn LLMConfig::chat_content(self : LLMConfig, messages : Array[LLMMessage]) -> String {
  let resp = self.chat(messages)
  parse_llm_response(resp)
}
