///|
pub(all) enum ProviderType {
  Deterministic
  LLM
} derive(Debug, Eq)

///|
pub(all) struct Provider {
  name : String
  provider_type : ProviderType
  model : String
  base_url : String
  timeout_seconds : Int
}

///|
pub fn Provider::new(name : String) -> Provider {
  { name, provider_type: Deterministic, model: "", base_url: "", timeout_seconds: 30 }
}

///|
pub fn Provider::new_llm(name : String, model : String, base_url : String, timeout : Int) -> Provider {
  { name, provider_type: LLM, model, base_url, timeout_seconds: timeout }
}

///|
pub fn Provider::is_deterministic(self : Provider) -> Bool {
  self.provider_type == Deterministic
}

///|
pub fn Provider::complete_trace(self : Provider, trace : RunTrace) -> String {
  match self.provider_type {
    Deterministic => deterministic_complete(self, trace)
    LLM => llm_complete(self, trace)
  }
}

///|
fn deterministic_complete(_provider : Provider, trace : RunTrace) -> String {
  let mut body = ""
  for observation in trace.observations {
    body = body + observation + "\n\n"
  }
  if trace.state == Completed {
    body = body + "What would you like to do next?"
  } else {
    body = body + "Something went wrong. Try rephrasing or ask for help."
  }
  body
}

///|
fn llm_complete(provider : Provider, trace : RunTrace) -> String {
  let prompt = build_llm_prompt(trace)
  "LLM Provider (\{provider.model}) would process:\n\{prompt}"
}

///|
fn build_llm_prompt(trace : RunTrace) -> String {
  let mut prompt = "Goal: \{trace.goal}\n"
  prompt = prompt + "State: \{render_run_state(trace.state)}\n"
  prompt = prompt + "Observations:\n"
  for obs in trace.observations {
    prompt = prompt + "- " + obs + "\n"
  }
  prompt = prompt + "Please provide a final answer."
  prompt
}

///|
pub fn Provider::to_config(self : Provider) -> ProviderConfig {
  {
    name: self.name,
    api_key: "",
    base_url: self.base_url,
    model: self.model,
    timeout_seconds: self.timeout_seconds,
  }
}
