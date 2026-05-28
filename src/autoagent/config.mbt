///|
pub(all) struct ProviderConfig {
  name : String
  api_key : String
  base_url : String
  model : String
  timeout_seconds : Int
}

///|
pub(all) struct AgentAppConfig {
  name : String
  system_prompt : String
  max_steps : Int
  max_goal_length : Int
  max_tool_output_length : Int
}

///|
pub(all) struct Config {
  provider : ProviderConfig
  agent : AgentAppConfig
}

///|
pub fn default_provider_config() -> ProviderConfig {
  {
    name: "deterministic",
    api_key: "",
    base_url: "",
    model: "",
    timeout_seconds: 30,
  }
}

///|
pub fn default_agent_app_config() -> AgentAppConfig {
  {
    name: "AutoAgent",
    system_prompt: "Help users build lightweight agents from scratch and use agents well.",
    max_steps: 3,
    max_goal_length: 1000,
    max_tool_output_length: 500,
  }
}

///|
pub fn default_config() -> Config {
  {
    provider: default_provider_config(),
    agent: default_agent_app_config(),
  }
}

///|
pub fn Config::to_agent_config(self : Config) -> AgentConfig {
  {
    name: self.agent.name,
    system_prompt: self.agent.system_prompt,
    max_steps: self.agent.max_steps,
    max_goal_length: self.agent.max_goal_length,
    max_tool_output_length: self.agent.max_tool_output_length,
  }
}

///|
pub fn Config::is_deterministic(self : Config) -> Bool {
  self.provider.name == "deterministic"
}

///|
pub fn render_config(config : Config) -> String {
  let mut out = "Config:\n"
  out = out + "  provider.name: \{config.provider.name}\n"
  out = out + "  provider.model: \{if config.provider.model == "" { "(none)" } else { config.provider.model }}\n"
  out = out + "  provider.base_url: \{if config.provider.base_url == "" { "(none)" } else { config.provider.base_url }}\n"
  out = out + "  provider.timeout: \{config.provider.timeout_seconds}s\n"
  out = out + "  agent.name: \{config.agent.name}\n"
  out = out + "  agent.max_steps: \{config.agent.max_steps}\n"
  out = out + "  agent.max_goal_length: \{config.agent.max_goal_length}\n"
  out = out + "  agent.max_tool_output_length: \{config.agent.max_tool_output_length}\n"
  out
}
