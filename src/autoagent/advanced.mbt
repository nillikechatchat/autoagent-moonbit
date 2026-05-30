///|
/// Multi-Agent Collaboration Module
/// v0.6.x: Agent delegation, task splitting, parallel execution
///

///|
pub struct AgentRole {
  name : String
  description : String
  capabilities : Array[String]
}

///|
pub fn AgentRole::new(name : String, description : String, capabilities : Array[String]) -> AgentRole {
  { name, description, capabilities }
}

///|
pub fn default_agent_roles() -> Array[AgentRole] {
  let roles : Array[AgentRole] = []
  roles.push(AgentRole::new("coder", "Writes and edits code", ["write_file", "edit_file", "run_command"]))
  roles.push(AgentRole::new("reviewer", "Reviews code quality", ["read_file", "code_search", "git_diff"]))
  roles.push(AgentRole::new("tester", "Writes and runs tests", ["write_file", "run_command", "search_web"]))
  roles.push(AgentRole::new("researcher", "Researches solutions", ["search_web", "http_get", "read_file"]))
  roles.push(AgentRole::new("deployer", "Handles deployment", ["run_command", "git_status", "file_info"]))
  roles
}

///|
pub fn render_agent_roles() -> String {
  let roles = default_agent_roles()
  let mut out = "👥 Agent Roles (Multi-Agent System)\n"
  out = out + "═══════════════════════════════════\n\n"
  for r in roles {
    out = out + "  " + r.name + ": " + r.description + "\n"
    out = out + "    Capabilities: "
    for i, c in r.capabilities {
      if i > 0 { out = out + ", " }
      out = out + c
    }
    out = out + "\n\n"
  }
  out
}

///|
pub struct TaskSplit {
  subtask : String
  assigned_to : String
  priority : Int
  estimated_steps : Int
}

///|
pub fn TaskSplit::new(subtask : String, assigned_to : String, priority : Int, estimated_steps : Int) -> TaskSplit {
  { subtask, assigned_to, priority, estimated_steps }
}

///|
pub fn split_task(goal : String) -> Array[TaskSplit] {
  let splits : Array[TaskSplit] = []
  let lower = goal.to_lower()
  
  if lower.contains("build") || lower.contains("create") || lower.contains("implement") {
    splits.push(TaskSplit::new("Research and plan approach", "researcher", 1, 2))
    splits.push(TaskSplit::new("Implement core functionality", "coder", 2, 5))
    splits.push(TaskSplit::new("Write tests", "tester", 3, 3))
    splits.push(TaskSplit::new("Review and refine", "reviewer", 4, 2))
  } else if lower.contains("fix") || lower.contains("debug") || lower.contains("error") {
    splits.push(TaskSplit::new("Reproduce and analyze issue", "researcher", 1, 2))
    splits.push(TaskSplit::new("Implement fix", "coder", 2, 3))
    splits.push(TaskSplit::new("Verify fix with tests", "tester", 3, 2))
  } else if lower.contains("refactor") || lower.contains("improve") || lower.contains("optimize") {
    splits.push(TaskSplit::new("Analyze current implementation", "reviewer", 1, 2))
    splits.push(TaskSplit::new("Plan refactoring approach", "researcher", 2, 1))
    splits.push(TaskSplit::new("Execute refactoring", "coder", 3, 4))
    splits.push(TaskSplit::new("Run regression tests", "tester", 4, 2))
  } else {
    splits.push(TaskSplit::new("Analyze requirements", "researcher", 1, 2))
    splits.push(TaskSplit::new("Execute task", "coder", 2, 3))
    splits.push(TaskSplit::new("Verify results", "tester", 3, 2))
  }
  
  splits
}

///|
pub fn render_task_splits(goal : String) -> String {
  let splits = split_task(goal)
  let mut out = "📋 Task Decomposition\n"
  out = out + "═══════════════════════════════════\n\n"
  out = out + "  Goal: " + goal + "\n\n"
  
  for s in splits {
    out = out + "  " + s.priority.to_string() + ". [" + s.assigned_to + "] " + s.subtask + "\n"
    out = out + "     Est. steps: " + s.estimated_steps.to_string() + "\n\n"
  }
  
  let mut total = 0
  for s in splits {
    total = total + s.estimated_steps
  }
  out = out + "  Total estimated steps: " + total.to_string() + "\n"
  out
}

///|
/// Code Intelligence Module
/// v0.8.x: Code metrics, complexity analysis, pattern detection
///

///|
pub fn analyze_code_complexity(code : String) -> String {
  let lines = code.split("\n")
  let mut total_lines = 0
  let mut blank_lines = 0
  let mut comment_lines = 0
  let mut max_line_len = 0
  let mut func_count = 0
  
  for line in lines {
    total_lines = total_lines + 1
    let trimmed = line.trim().to_owned()
    if trimmed.length() == 0 {
      blank_lines = blank_lines + 1
    } else if trimmed.has_prefix("//") || trimmed.has_prefix("#") || trimmed.has_prefix("/*") {
      comment_lines = comment_lines + 1
    }
    if trimmed.length() > max_line_len {
      max_line_len = trimmed.length()
    }
    if trimmed.has_prefix("fn ") || trimmed.has_prefix("pub fn ") || trimmed.has_prefix("function ") || trimmed.has_prefix("def ") {
      func_count = func_count + 1
    }
  }
  
  let code_lines = total_lines - blank_lines - comment_lines
  let comment_ratio = if code_lines > 0 { comment_lines * 100 / code_lines } else { 0 }
  
  let mut out = "📊 Code Complexity Analysis\n"
  out = out + "═══════════════════════════════════\n\n"
  out = out + "  Total lines:     " + total_lines.to_string() + "\n"
  out = out + "  Code lines:      " + code_lines.to_string() + "\n"
  out = out + "  Blank lines:     " + blank_lines.to_string() + "\n"
  out = out + "  Comment lines:   " + comment_lines.to_string() + "\n"
  out = out + "  Comment ratio:   " + comment_ratio.to_string() + "%\n"
  out = out + "  Functions:       " + func_count.to_string() + "\n"
  out = out + "  Max line length: " + max_line_len.to_string() + "\n\n"
  
  // Quality assessment
  let quality = if comment_ratio >= 20 && func_count > 0 && max_line_len <= 120 { "A" }
                else if comment_ratio >= 10 && func_count > 0 { "B" }
                else if func_count > 0 { "C" }
                else { "D" }
  out = out + "  Quality Grade:   " + quality + "\n"
  
  out
}

///|
pub fn detect_code_patterns(code : String) -> String {
  let patterns : Array[String] = []
  let lower = code.to_lower()
  
  if lower.contains("todo") || lower.contains("fixme") || lower.contains("hack") {
    patterns.push("📝 TODO/FIXME markers found")
  }
  if lower.contains("unwrap()") {
    patterns.push("⚠️  unwrap() usage - potential panics")
  }
  if lower.contains("clone()") {
    patterns.push("ℹ️  clone() usage - check if necessary")
  }
  if lower.contains("unsafe") {
    patterns.push("🚨 unsafe block detected")
  }
  if lower.contains("console.log") || lower.contains("println!") || lower.contains("print(") {
    patterns.push("📝 Debug print statements found")
  }
  if lower.contains("password") || lower.contains("secret") || lower.contains("api_key") {
    patterns.push("🔒 Sensitive data references")
  }
  if lower.contains("http://") {
    patterns.push("⚠️  Non-HTTPS URLs found")
  }
  
  if patterns.length() == 0 {
    return "✅ No notable patterns detected."
  }
  
  let mut out = "🔍 Code Pattern Detection\n"
  out = out + "═══════════════════════════════════\n\n"
  for p in patterns {
    out = out + "  " + p + "\n"
  }
  out
}

///|
/// Test Automation Module
/// v0.9.x: Test generation, coverage estimation
///

///|
pub fn generate_test_suggestion(function_name : String, function_type : String) -> String {
  let mut out = "🧪 Test Suggestions for: " + function_name + "\n"
  out = out + "═══════════════════════════════════\n\n"
  
  out = out + "  Recommended test cases:\n\n"
  
  if function_type == "read" {
    out = out + "  1. Happy path - valid input returns expected output\n"
    out = out + "  2. Empty input - handles empty/null gracefully\n"
    out = out + "  3. Large input - handles large data efficiently\n"
    out = out + "  4. Error case - invalid path returns error\n"
  } else if function_type == "write" {
    out = out + "  1. Happy path - writes valid data successfully\n"
    out = out + "  2. Permission error - handles write failures\n"
    out = out + "  3. Disk full - handles storage errors\n"
    out = out + "  4. Concurrent write - handles race conditions\n"
  } else if function_type == "process" {
    out = out + "  1. Happy path - normal processing succeeds\n"
    out = out + "  2. Edge case - boundary values\n"
    out = out + "  3. Error case - invalid input types\n"
    out = out + "  4. Performance - timing constraints\n"
  } else {
    out = out + "  1. Happy path - normal operation\n"
    out = out + "  2. Edge case - boundary conditions\n"
    out = out + "  3. Error case - failure scenarios\n"
    out = out + "  4. Integration - interaction with other components\n"
  }
  
  out
}

///|
pub fn estimate_test_coverage(code_lines : Int, test_lines : Int) -> String {
  let ratio = if code_lines > 0 { test_lines * 100 / code_lines } else { 0 }
  let grade = if ratio >= 80 { "A (Excellent)" }
              else if ratio >= 60 { "B (Good)" }
              else if ratio >= 40 { "C (Fair)" }
              else if ratio >= 20 { "D (Low)" }
              else { "F (Critical)" }
  
  let mut out = "📈 Test Coverage Estimate\n"
  out = out + "═══════════════════════════════════\n\n"
  out = out + "  Code lines:    " + code_lines.to_string() + "\n"
  out = out + "  Test lines:    " + test_lines.to_string() + "\n"
  out = out + "  Ratio:         " + ratio.to_string() + "%\n"
  out = out + "  Grade:         " + grade + "\n\n"
  
  if ratio < 40 {
    out = out + "  ⚠️  Consider adding more tests!\n"
  }
  
  out
}

///|
/// Documentation Generator Module
/// v0.9.x: Auto-generate docs from code
///

///|
pub fn generate_api_doc(functions : Array[String]) -> String {
  let mut out = "# API Documentation\n\n"
  out = out + "## Functions\n\n"
  
  for i, fn_name in functions {
    out = out + "### " + (i + 1).to_string() + ". " + fn_name + "\n\n"
    out = out + "**Description:** [TODO: Add description]\n\n"
    out = out + "**Parameters:**\n"
    out = out + "- [TODO: Document parameters]\n\n"
    out = out + "**Returns:**\n"
    out = out + "- [TODO: Document return value]\n\n"
    out = out + "**Example:**\n"
    out = out + "```moonbit\n"
    out = out + "// TODO: Add usage example\n"
    out = out + "```\n\n"
  }
  
  out
}

///|
pub fn generate_changelog(entries : Array[String]) -> String {
  let mut out = "# Changelog\n\n"
  out = out + "## " + exec_command("date +%Y-%m-%d").trim().to_owned() + "\n\n"
  for e in entries {
    out = out + "- " + e + "\n"
  }
  out
}

///|
/// Release Management Module
/// v1.0.0: Version management, release checklist
///

///|
pub fn release_checklist(version : String) -> String {
  let mut out = "📦 Release Checklist: v" + version + "\n"
  out = out + "═══════════════════════════════════\n\n"
  
  out = out + "  [ ] All tests passing\n"
  out = out + "  [ ] No critical bugs\n"
  out = out + "  [ ] Documentation updated\n"
  out = out + "  [ ] Changelog updated\n"
  out = out + "  [ ] Version number bumped\n"
  out = out + "  [ ] Binary built and tested\n"
  out = out + "  [ ] Release notes drafted\n"
  out = out + "  [ ] Git tag created\n"
  out = out + "  [ ] Distribution package ready\n\n"
  
  out = out + "  Run: make test && make build-native && make dist\n"
  out
}

///|
pub fn generate_release_notes(version : String, features : Array[String]) -> String {
  let mut out = "# AutoAgent v" + version + " Release Notes\n\n"
  out = out + "## What's New\n\n"
  for f in features {
    out = out + "- " + f + "\n"
  }
  out = out + "\n## Installation\n\n"
  out = out + "```bash\n"
  out = out + "tar -xzf autoagent-" + version + "-linux-x86_64.tar.gz\n"
  out = out + "cd autoagent-" + version + "\n"
  out = out + "./autoagent chat\n"
  out = out + "```\n\n"
  out = out + "## Configuration\n\n"
  out = out + "Set environment variables:\n"
  out = out + "```bash\n"
  out = out + "export MCAI_LLM_API_KEY='your-key'\n"
  out = out + "export MCAI_LLM_BASE_URL='https://api.openai.com/v1'\n"
  out = out + "export MCAI_LLM_MODEL='gpt-4o-mini'\n"
  out = out + "```\n"
  out
}
