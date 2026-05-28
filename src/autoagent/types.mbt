///|
pub(all) enum Role {
  User
  Assistant
  System
  Tool
} derive(Debug, Eq)

///|
pub(all) struct Message {
  role : Role
  content : String
} derive(Debug, Eq)

///|
pub(all) struct Step {
  id : Int
  action : String
  input : String
  reason : String
} derive(Debug, Eq)

///|
pub(all) enum StepResult {
  Success(String)
  Failure(String)
} derive(Debug, Eq)

///|
pub(all) enum RiskLevel {
  Low
  Medium
  High
} derive(Debug, Eq)

///|
pub(all) struct ToolSpec {
  name : String
  description : String
  category : String
  risk : RiskLevel
} derive(Debug, Eq)

///|
pub(all) struct ToolCall {
  name : String
  input : String
} derive(Debug, Eq)

///|
pub(all) enum RunState {
  Ready
  Running
  Completed
  Failed
} derive(Debug, Eq)

///|
pub(all) enum StopReason {
  CompletedAllSteps
  EmptyGoal
  InputTooLong
  ToolFailure(String)
} derive(Debug, Eq)

///|
pub(all) struct RunTrace {
  goal : String
  state : RunState
  stop_reason : StopReason
  steps : Array[Step]
  observations : Array[String]
  answer : String
} derive(Debug, Eq)

///|
pub fn message(role : Role, content : String) -> Message {
  { role, content }
}

///|
pub fn step(id : Int, action : String, input : String, reason : String) -> Step {
  { id, action, input, reason }
}

///|
pub fn render_role(role : Role) -> String {
  match role {
    User => "user"
    Assistant => "assistant"
    System => "system"
    Tool => "tool"
  }
}

///|
pub fn render_message(msg : Message) -> String {
  "[\{render_role(msg.role)}] \{msg.content}"
}

///|
pub fn render_step(s : Step) -> String {
  "\{s.id}. \{s.action}: \{s.input} (reason: \{s.reason})"
}

///|
pub fn render_stop_reason(reason : StopReason) -> String {
  match reason {
    CompletedAllSteps => "completed all planned steps"
    EmptyGoal => "empty goal"
    InputTooLong => "input too long"
    ToolFailure(name) => "tool failure: \{name}"
  }
}

///|
pub fn render_run_state(state : RunState) -> String {
  match state {
    Ready => "ready"
    Running => "running"
    Completed => "completed"
    Failed => "failed"
  }
}

///|
pub fn render_risk_level(risk : RiskLevel) -> String {
  match risk {
    Low => "low"
    Medium => "medium"
    High => "high"
  }
}
