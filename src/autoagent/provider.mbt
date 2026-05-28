///|
pub(all) struct Provider {
  name : String
}

///|
pub fn Provider::new(name : String) -> Provider {
  { name, }
}

///|
pub fn Provider::complete_trace(self : Provider, trace : RunTrace) -> String {
  let mut body = "AutoAgent provider=\{self.name}\nGoal: \{trace.goal}\nState: \{render_run_state(trace.state)}\nStop: \{render_stop_reason(trace.stop_reason)}"
  for observation in trace.observations {
    body = body + "\n- " + observation
  }
  body
}
