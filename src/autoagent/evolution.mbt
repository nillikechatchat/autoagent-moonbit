///|
/// Self-Evaluation Module - Agent performance scoring and improvement suggestions
/// v0.3.3+
///

///|
pub struct EvalDimension {
  name : String
  score : Int
  max_score : Int
  suggestion : String
}

///|
pub fn EvalDimension::new(name : String, score : Int, max_score : Int, suggestion : String) -> EvalDimension {
  { name, score, max_score, suggestion }
}

///|
pub fn EvalDimension::render(self : EvalDimension) -> String {
  let bar_len = self.score * 10 / self.max_score
  let mut bar = ""
  for i in 0..<10 {
    if i < bar_len { bar = bar + "█" } else { bar = bar + "░" }
  }
  "  " + self.name + ": [" + bar + "] " + self.score.to_string() + "/" + self.max_score.to_string() + " " + self.suggestion
}

///|
pub fn evaluate_agent(task_count : Int, success_count : Int, total_tools : Int, message_count : Int) -> String {
  let mut out = "🧠 Agent Self-Evaluation\n"
  out = out + "═══════════════════════════════════\n\n"
  
  let dimensions : Array[EvalDimension] = []
  
  let task_score = if task_count == 0 { 5 } else if success_count * 10 / task_count >= 8 { 9 } else if success_count * 10 / task_count >= 5 { 7 } else { 4 }
  dimensions.push(EvalDimension::new("Task Completion", task_score, 10, if task_score >= 8 { "Excellent" } else { "Needs improvement" }))
  
  let avg_tools = if task_count > 0 { total_tools / task_count } else { 0 }
  let tool_score = if avg_tools == 0 { 5 } else if avg_tools <= 5 { 9 } else if avg_tools <= 10 { 7 } else { 4 }
  dimensions.push(EvalDimension::new("Tool Efficiency", tool_score, 10, if tool_score >= 8 { "Efficient" } else { "Too many calls" }))
  
  let context_score = if message_count > 20 { 8 } else if message_count > 10 { 7 } else { 5 }
  dimensions.push(EvalDimension::new("Context Awareness", context_score, 10, if context_score >= 8 { "Good" } else { "Needs more" }))
  
  let adapt_score = if total_tools > 20 { 9 } else if total_tools > 10 { 7 } else { 5 }
  dimensions.push(EvalDimension::new("Adaptability", adapt_score, 10, if adapt_score >= 8 { "Versatile" } else { "Limited" }))
  
  let learn_score = if task_count > 5 { 8 } else if task_count > 2 { 6 } else { 4 }
  dimensions.push(EvalDimension::new("Learning Progress", learn_score, 10, if learn_score >= 8 { "Growing" } else { "Early stage" }))
  
  for d in dimensions {
    out = out + d.render() + "\n"
  }
  
  let mut total = 0
  for d in dimensions {
    total = total + d.score
  }
  let overall = total / dimensions.length()
  let grade = if overall >= 8 { "A" } else if overall >= 6 { "B" } else if overall >= 4 { "C" } else { "D" }
  
  out = out + "\n═══════════════════════════════════\n"
  out = out + "  Overall: " + overall.to_string() + "/10 (Grade: " + grade + ")\n"
  
  out
}

///|
pub fn optimize_context(messages : Array[LLMMessage], _max_tokens : Int) -> Array[LLMMessage] {
  if messages.length() <= 5 { return messages }
  
  let result : Array[LLMMessage] = []
  if messages.length() > 0 {
    result.push(messages[0])
  }
  
  if messages.length() > 10 {
    let summary = "[Context: " + (messages.length() - 4).to_string() + " messages summarized]"
    result.push({ role: "system", content: summary })
    
    let start = messages.length() - 3
    for i in start..<messages.length() {
      result.push(messages[i])
    }
  } else {
    for i in 1..<messages.length() {
      result.push(messages[i])
    }
  }
  
  result
}

///|
pub fn run_benchmark() -> String {
  let mut out = "⚡ Performance Benchmark\n"
  out = out + "═══════════════════════════════════\n\n"
  
  let start = time_ms()
  let _ = write_file("/tmp/autoagent_bench.txt", "benchmark test")
  let _ = read_file("/tmp/autoagent_bench.txt")
  let file_time = time_ms() - start
  out = out + "  File I/O:        " + file_time.to_string() + "ms\n"
  
  let start2 = time_ms()
  let _ = exec_command("echo hello")
  let cmd_time = time_ms() - start2
  out = out + "  Command exec:    " + cmd_time.to_string() + "ms\n"
  
  let start3 = time_ms()
  let mut s = ""
  for _i in 0..<100 {
    s = s + "x"
  }
  let str_time = time_ms() - start3
  out = out + "  String ops:      " + str_time.to_string() + "ms\n"
  
  let total = file_time + cmd_time + str_time
  out = out + "\n  Total:           " + total.to_string() + "ms\n"
  out = out + "\n═══════════════════════════════════\n"
  
  out
}

///|
pub fn render_tool_chains() -> String {
  let mut out = "🔗 Tool Chains (predefined workflows)\n"
  out = out + "═══════════════════════════════════\n\n"
  
  out = out + "  file-review\n"
  out = out + "    Read, analyze, and report on a file\n"
  out = out + "    Steps: read_file → code_search → file_info\n\n"
  
  out = out + "  code-quality\n"
  out = out + "    Check code quality and suggest improvements\n"
  out = out + "    Steps: read_file → run_command → git_diff\n\n"
  
  out = out + "  project-overview\n"
  out = out + "    Get comprehensive project information\n"
  out = out + "    Steps: list_files → project_info → git_status\n\n"
  
  out = out + "  debug-flow\n"
  out = out + "    Debug an issue systematically\n"
  out = out + "    Steps: code_search → run_command → read_file\n\n"
  
  out = out + "  deploy-prep\n"
  out = out + "    Prepare for deployment\n"
  out = out + "    Steps: git_status → run_command → file_info\n\n"
  
  out
}

///|
pub fn suggest_recovery(error_msg : String) -> String {
  let lower = error_msg.to_lower()
  
  if lower.contains("not found") || lower.contains("no such file") {
    return "💡 Recovery: Check file path, ensure file exists."
  }
  if lower.contains("permission") || lower.contains("denied") {
    return "💡 Recovery: Check file permissions."
  }
  if lower.contains("timeout") || lower.contains("timed out") {
    return "💡 Recovery: Increase timeout, retry."
  }
  if lower.contains("syntax") || lower.contains("parse") {
    return "💡 Recovery: Validate input format."
  }
  if lower.contains("network") || lower.contains("connection") {
    return "💡 Recovery: Check connectivity, retry."
  }
  
  "💡 Recovery: Review error, verify inputs, try alternative."
}

///|
pub fn classify_user_intent(input : String) -> String {
  let lower = input.to_lower()
  
  if lower.contains("create") || lower.contains("build") || lower.contains("make") {
    return "creation"
  }
  if lower.contains("fix") || lower.contains("debug") || lower.contains("error") {
    return "debugging"
  }
  if lower.contains("explain") || lower.contains("what") || lower.contains("how") {
    return "explanation"
  }
  if lower.contains("refactor") || lower.contains("improve") || lower.contains("optimize") {
    return "improvement"
  }
  if lower.contains("test") || lower.contains("verify") || lower.contains("check") {
    return "testing"
  }
  if lower.contains("deploy") || lower.contains("release") {
    return "deployment"
  }
  if lower.contains("search") || lower.contains("find") {
    return "search"
  }
  if lower.contains("help") || lower.contains("usage") {
    return "help"
  }
  
  "general"
}

///|
pub fn intent_icon(intent : String) -> String {
  if intent == "creation" { return "🔨" }
  if intent == "debugging" { return "🐛" }
  if intent == "explanation" { return "📖" }
  if intent == "improvement" { return "✨" }
  if intent == "testing" { return "🧪" }
  if intent == "deployment" { return "🚀" }
  if intent == "search" { return "🔍" }
  if intent == "help" { return "❓" }
  "💬"
}

///|
pub fn scan_for_secrets(content : String, filename : String) -> String {
  let warnings : Array[String] = []
  let lower = content.to_lower()
  
  if lower.contains("api_key") || lower.contains("apikey") {
    warnings.push("⚠️  Possible API key in " + filename)
  }
  if lower.contains("password") && lower.contains("=") {
    warnings.push("⚠️  Possible password in " + filename)
  }
  if lower.contains("secret") && lower.contains("=") {
    warnings.push("⚠️  Possible secret in " + filename)
  }
  if content.contains("BEGIN RSA") || content.contains("BEGIN PRIVATE") {
    warnings.push("🚨 Private key in " + filename)
  }
  
  if warnings.length() == 0 {
    return "✅ No secrets in " + filename
  }
  
  let mut out = ""
  for w in warnings {
    out = out + w + "\n"
  }
  out
}

///|
pub fn check_deploy_readiness(project_path : String) -> String {
  let checks : Array[String] = []
  let mut pass = 0
  let mut fail = 0
  
  let git_out = exec_command("cd " + project_path + " && git status --porcelain 2>/dev/null")
  if git_out.trim().to_owned() == "" {
    checks.push("✅ Git working tree clean")
    pass = pass + 1
  } else {
    checks.push("⚠️  Git has uncommitted changes")
    fail = fail + 1
  }
  
  if file_exists(project_path + "/package.json") || file_exists(project_path + "/Cargo.toml") || file_exists(project_path + "/moon.mod") {
    checks.push("✅ Build config found")
    pass = pass + 1
  } else {
    checks.push("⚠️  No build config found")
    fail = fail + 1
  }
  
  if file_exists(project_path + "/README.md") {
    checks.push("✅ README exists")
    pass = pass + 1
  } else {
    checks.push("⚠️  No README found")
    fail = fail + 1
  }
  
  let mut out = "🚀 Deployment Readiness\n"
  out = out + "═══════════════════════════════════\n\n"
  for c in checks {
    out = out + "  " + c + "\n"
  }
  out = out + "\n  Score: " + pass.to_string() + "/" + (pass + fail).to_string() + "\n"
  
  if fail == 0 {
    out = out + "  ✅ Ready for deployment!\n"
  } else {
    out = out + "  ⚠️  " + fail.to_string() + " issue(s) to fix.\n"
  }
  
  out
}

///|
pub fn generate_project_doc(project_path : String) -> String {
  let mut out = "# Project Documentation\n\n"
  
  let name = if file_exists(project_path + "/moon.mod") {
    let content = read_file(project_path + "/moon.mod")
    extract_field(content, "name")
  } else {
    "Unknown Project"
  }
  out = out + "## " + name + "\n\n"
  
  out = out + "### Source Files\n\n"
  let src_files = exec_command("find " + project_path + "/src -name '*.mbt' 2>/dev/null | head -10")
  let lines = src_files.split("\n")
  for f in lines {
    if f.length() > 0 {
      out = out + "- " + f.to_string() + "\n"
    }
  }
  
  out
}

fn extract_field(content : String, field : String) -> String {
  let search = field + " = \""
  let start = str_index_of(content, search, 0)
  if start == -1 { return "Unknown" }
  let val_start = start + search.length()
  let end = str_index_of(content, "\"", val_start)
  if end == -1 { return "Unknown" }
  content[val_start:end].trim().to_owned()
}
