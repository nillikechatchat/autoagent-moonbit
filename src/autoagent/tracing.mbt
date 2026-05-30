///|
/// Task Execution Trace Module - Record and analyze task execution history
/// v0.3.2 Feature: Comprehensive task tracing and playback
///

///|
pub struct TaskStep {
  step_index : Int
  tool_name : String
  tool_input : String
  result : String
  success : Bool
  duration_ms : Int64
}

///|
pub fn TaskStep::new(
  step_index : Int,
  tool_name : String,
  tool_input : String,
  result : String,
  success : Bool,
  duration_ms : Int64,
) -> TaskStep {
  { step_index, tool_name, tool_input, result, success, duration_ms }
}

///|
pub struct TaskTrace {
  task_id : String
  goal : String
  steps : Array[TaskStep]
  start_time : String
  end_time : String
  total_duration_ms : Int64
  success : Bool
  tags : Array[String]
}

///|
pub fn TaskTrace::new(
  task_id : String,
  goal : String,
  steps : Array[TaskStep],
  start_time : String,
  end_time : String,
  total_duration_ms : Int64,
  success : Bool,
  tags : Array[String],
) -> TaskTrace {
  { task_id, goal, steps, start_time, end_time, total_duration_ms, success, tags }
}

///|
pub fn TaskTrace::add_step(self : TaskTrace, step : TaskStep) -> TaskTrace {
  let new_steps = self.steps
  new_steps.push(step)
  
  let new_total = self.total_duration_ms + step.duration_ms
  
  TaskTrace::new(
    self.task_id,
    self.goal,
    new_steps,
    self.start_time,
    self.end_time,
    new_total,
    self.success,
    self.tags,
  )
}

///|
pub fn TaskTrace::complete(self : TaskTrace, success : Bool) -> TaskTrace {
  TaskTrace::new(
    self.task_id,
    self.goal,
    self.steps,
    self.start_time,
    exec_command("date -Iseconds").trim().to_owned(),
    self.total_duration_ms,
    success,
    self.tags,
  )
}

///|
pub fn TaskTrace::add_tag(self : TaskTrace, tag : String) -> TaskTrace {
  let new_tags = self.tags
  if !new_tags.contains(tag) {
    new_tags.push(tag)
  }
  TaskTrace::new(
    self.task_id,
    self.goal,
    self.steps,
    self.start_time,
    self.end_time,
    self.total_duration_ms,
    self.success,
    new_tags,
  )
}

///|
fn escape_trace_json(s : String) -> String {
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
pub fn TaskTrace::to_json(self : TaskTrace) -> String {
  let mut out = "{\"task_id\":\"" + escape_trace_json(self.task_id) + "\","
  out = out + "\"goal\":\"" + escape_trace_json(self.goal) + "\","
  out = out + "\"start_time\":\"" + escape_trace_json(self.start_time) + "\","
  out = out + "\"end_time\":\"" + escape_trace_json(self.end_time) + "\","
  out = out + "\"total_duration_ms\":" + self.total_duration_ms.to_string() + ","
  out = out + "\"success\":" + (if self.success { "true" } else { "false" }) + ","
  
  // Steps
  out = out + "\"steps\":["
  for i, step in self.steps {
    if i > 0 { out = out + "," }
    out = out + "{"
    out = out + "\"step\":" + step.step_index.to_string() + ","
    out = out + "\"tool\":\"" + escape_trace_json(step.tool_name) + "\","
    out = out + "\"success\":" + (if step.success { "true" } else { "false" }) + ","
    out = out + "\"duration_ms\":" + step.duration_ms.to_string()
    out = out + "}"
  }
  out = out + "],"
  
  // Tags
  out = out + "\"tags\":["
  for i, tag in self.tags {
    if i > 0 { out = out + "," }
    out = out + "\"" + escape_trace_json(tag) + "\""
  }
  out = out + "]}"
  
  out
}

///|
pub struct TraceManager {
  traces : Array[TaskTrace]
  storage_path : String
}

///|
pub fn TraceManager::new(storage_path : String) -> TraceManager {
  { traces: [], storage_path }
}

///|
pub fn TraceManager::create_trace(self : TraceManager, goal : String) -> TaskTrace {
  let task_id = "task_" + exec_command("date +%Y%m%d%H%M%S").trim().to_owned()
  TaskTrace::new(task_id, goal, [], "", "", 0L, false, [])
}

///|
pub fn TraceManager::add_trace(self : TraceManager, trace : TaskTrace) -> Unit {
  self.traces.push(trace)
}

///|
pub fn TraceManager::get_statistics(self : TraceManager) -> String {
  if self.traces.length() == 0 {
    return "No task traces recorded yet."
  }
  
  let total_tasks = self.traces.length()
  let mut successful = 0
  let mut total_steps = 0
  
  for t in self.traces {
    if t.success { successful = successful + 1 }
    total_steps = total_steps + t.steps.length()
  }
  
  let success_rate = (successful * 100) / total_tasks
  let avg_steps = total_steps / total_tasks
  
  let mut out = "📊 Task Execution Statistics\n\n"
  out = out + "Total Tasks: " + total_tasks.to_string() + "\n"
  out = out + "Success Rate: " + success_rate.to_string() + "%\n"
  out = out + "Avg Steps: " + avg_steps.to_string() + "\n\n"
  
  out
}

///|
pub fn TraceManager::list_recent(self : TraceManager, limit : Int) -> String {
  if self.traces.length() == 0 {
    return "No recent tasks."
  }
  
  let start = if self.traces.length() > limit { self.traces.length() - limit } else { 0 }
  
  let mut out = "📋 Recent Tasks:\n\n"
  for i in start..<self.traces.length() {
    let t = self.traces[i]
    let status = if t.success { "✅" } else { "❌" }
    out = out + status + " [" + t.task_id + "] " + t.goal + "\n"
    out = out + "   ⏱ Steps: " + t.steps.length().to_string() + "\n\n"
  }
  
  out
}

///|
pub fn save_traces(traces : Array[TaskTrace], path : String) -> Bool {
  let mut json = "["
  for i, trace in traces {
    if i > 0 { json = json + "," }
    json = json + trace.to_json()
  }
  json = json + "]"
  write_file(path, json)
}
