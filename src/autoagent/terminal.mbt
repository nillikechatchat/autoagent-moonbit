///|
const ESC : String = "\u001b"

///|
pub fn ansi_reset() -> String {
  ESC + "[0m"
}

///|
pub fn ansi_bold() -> String {
  ESC + "[1m"
}

///|
pub fn ansi_dim() -> String {
  ESC + "[2m"
}

///|
pub fn ansi_red() -> String {
  ESC + "[31m"
}

///|
pub fn ansi_green() -> String {
  ESC + "[32m"
}

///|
pub fn ansi_yellow() -> String {
  ESC + "[33m"
}

///|
pub fn ansi_blue() -> String {
  ESC + "[34m"
}

///|
pub fn ansi_magenta() -> String {
  ESC + "[35m"
}

///|
pub fn ansi_cyan() -> String {
  ESC + "[36m"
}

///|
pub fn ansi_gray() -> String {
  ESC + "[90m"
}

///|
pub fn color_text(text : String, color : String) -> String {
  color + text + ansi_reset()
}

///|
pub fn bold_text(text : String) -> String {
  ansi_bold() + text + ansi_reset()
}

///|
pub fn dim_text(text : String) -> String {
  ansi_dim() + text + ansi_reset()
}

///|
pub fn header(text : String) -> String {
  "\n" + ansi_bold() + ansi_cyan() + text + ansi_reset()
}

///|
pub fn success(text : String) -> String {
  ansi_green() + "✓ " + ansi_reset() + text
}

///|
pub fn error_text(text : String) -> String {
  ansi_red() + "✗ " + ansi_reset() + text
}

///|
pub fn warning(text : String) -> String {
  ansi_yellow() + "⚠ " + ansi_reset() + text
}

///|
pub fn info(text : String) -> String {
  ansi_blue() + "ℹ " + ansi_reset() + text
}

///|
pub fn step_label(step : Int, total : Int, label : String) -> String {
  ansi_cyan() + "[\{step}/\{total}]" + ansi_reset() + " " + label
}

///|
pub fn tool_start(tool_name : String) -> String {
  ansi_yellow() + "⟳ " + ansi_reset() + "Executing " + bold_text(tool_name) + "..."
}

///|
pub fn tool_done(tool_name : String) -> String {
  ansi_green() + "✓ " + ansi_reset() + bold_text(tool_name) + " completed"
}

///|
pub fn tool_failed(tool_name : String, reason : String) -> String {
  ansi_red() + "✗ " + ansi_reset() + bold_text(tool_name) + " failed: " + reason
}

///|
pub fn divider() -> String {
  ansi_gray() + "────────────────────────────────────────" + ansi_reset()
}

///|
pub fn format_state(state : RunState) -> String {
  match state {
    Completed => ansi_green() + "completed" + ansi_reset()
    Failed => ansi_red() + "failed" + ansi_reset()
    Running => ansi_yellow() + "running" + ansi_reset()
    Ready => ansi_blue() + "ready" + ansi_reset()
  }
}

///|
pub fn format_stop(reason : StopReason) -> String {
  match reason {
    CompletedAllSteps => ansi_green() + "completed all planned steps" + ansi_reset()
    EmptyGoal => ansi_yellow() + "empty goal" + ansi_reset()
    InputTooLong => ansi_red() + "input too long" + ansi_reset()
    ToolFailure(name) => ansi_red() + "tool failure: " + name + ansi_reset()
  }
}

///|
pub fn format_trace(trace : RunTrace) -> String {
  let mut out = ""
  out = out + header("=== AutoAgent Trace ===") + "\n"
  out = out + "  Goal:   " + bold_text(trace.goal) + "\n"
  out = out + "  State:  " + format_state(trace.state) + "\n"
  out = out + "  Stop:   " + format_stop(trace.stop_reason) + "\n"
  out = out + "  Steps:  " + trace.steps.length().to_string() + "\n"
  out = out + "  Obs:    " + trace.observations.length().to_string() + "\n"
  out = out + divider() + "\n"
  for obs in trace.observations {
    out = out + "  " + dim_text("•") + " " + obs + "\n"
  }
  out = out + divider() + "\n"
  out
}

///|
pub fn format_answer(answer : String) -> String {
  header("=== Answer ===") + "\n" + answer
}

///|
pub fn banner() -> String {
  let mut out = ""
  out = out + "\n"
  out = out + ansi_bold() + ansi_cyan() + "  AutoAgent v0.2.0" + ansi_reset() + "\n"
  out = out + dim_text("  A lightweight MoonBit Agent runtime") + "\n"
  out = out + "\n"
  out
}

///|
pub fn format_step(step : Step, total : Int, result : StepResult) -> String {
  let status = match result {
    Success(_) => ansi_green() + "✓" + ansi_reset()
    Failure(_) => ansi_red() + "✗" + ansi_reset()
  }
  let action_str = bold_text(step.action)
  let reason_str = dim_text("(" + step.reason + ")")
  "  " + status + " " + step_label(step.id, total, action_str) + " " + reason_str
}

///|
pub fn format_run_summary(trace : RunTrace) -> String {
  let mut out = ""
  out = out + header("Run Summary") + "\n"
  out = out + "  Goal:    " + trace.goal + "\n"
  out = out + "  Status:  " + format_state(trace.state) + "\n"
  out = out + "  Stop:    " + format_stop(trace.stop_reason) + "\n"
  out = out + "  Steps:   " + trace.steps.length().to_string() + "\n"
  out = out + "  Results: " + trace.observations.length().to_string() + "\n"
  out
}
