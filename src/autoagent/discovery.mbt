///|
/// Tool Discovery Module - Automatically discover and recommend tools based on context
/// v0.3.1 Feature: Smart tool recommendation engine
///

///|
pub struct ToolRecommendation {
  tool_name : String
  reason : String
  confidence : Float
  category : String
}

///|
pub fn ToolRecommendation::new(
  tool_name : String,
  reason : String,
  confidence : Float,
  category : String,
) -> ToolRecommendation {
  { tool_name, reason, confidence, category }
}

///|
pub struct ToolDiscoverer {
  discovered_tools : Array[ToolRecommendation]
  context_keywords : Array[String]
}

///|
pub fn ToolDiscoverer::new() -> ToolDiscoverer {
  {
    discovered_tools: [],
    context_keywords: [],
  }
}

///|
/// Analyze user input and recommend relevant tools
///
pub fn ToolDiscoverer::analyze_input(self : ToolDiscoverer, input : String) -> Array[ToolRecommendation] {
  let recommendations : Array[ToolRecommendation] = []
  let lower_input = input.to_lower()
  
  // File operations
  if lower_input.contains("read") || lower_input.contains("view") || lower_input.contains("show") {
    if lower_input.contains("file") || lower_input.contains("content") {
      recommendations.push(ToolRecommendation::new(
        "read_file",
        "User wants to read file content",
        0.95,
        "file_operations"
      ))
    }
  }
  
  if lower_input.contains("write") || lower_input.contains("create") || lower_input.contains("make") {
    if lower_input.contains("file") {
      recommendations.push(ToolRecommendation::new(
        "write_file",
        "User wants to create/write a file",
        0.95,
        "file_operations"
      ))
    }
  }
  
  if lower_input.contains("edit") || lower_input.contains("modify") || lower_input.contains("change") || lower_input.contains("update") {
    recommendations.push(ToolRecommendation::new(
      "edit_file",
      "User wants to edit an existing file",
      0.90,
      "file_operations"
    ))
  }
  
  // Directory operations
  if lower_input.contains("list") || lower_input.contains("show") || lower_input.contains("directory") || lower_input.contains("folder") {
    recommendations.push(ToolRecommendation::new(
      "list_files",
      "User wants to list directory contents",
      0.85,
      "file_operations"
    ))
  }
  
  // Command execution
  if lower_input.contains("run") || lower_input.contains("execute") || lower_input.contains("command") || lower_input.contains("shell") {
    recommendations.push(ToolRecommendation::new(
      "run_command",
      "User wants to execute a shell command",
      0.90,
      "command_execution"
    ))
  }
  
  // Search operations
  if lower_input.contains("search") || lower_input.contains("find") || lower_input.contains("lookup") {
    if lower_input.contains("web") || lower_input.contains("internet") || lower_input.contains("google") {
      recommendations.push(ToolRecommendation::new(
        "search_web",
        "User wants to search the web",
        0.95,
        "search"
      ))
    } else if lower_input.contains("file") || lower_input.contains("code") {
      recommendations.push(ToolRecommendation::new(
        "code_search",
        "User wants to search code content",
        0.85,
        "search"
      ))
    }
  }
  
  // Git operations
  if lower_input.contains("git") {
    if lower_input.contains("status") {
      recommendations.push(ToolRecommendation::new(
        "git_status",
        "User wants to check git status",
        0.95,
        "version_control"
      ))
    }
    if lower_input.contains("diff") || lower_input.contains("difference") || lower_input.contains("change") {
      recommendations.push(ToolRecommendation::new(
        "git_diff",
        "User wants to see git diff",
        0.90,
        "version_control"
      ))
    }
  }
  
  // Project analysis
  if lower_input.contains("project") || lower_input.contains("structure") || lower_input.contains("info") {
    recommendations.push(ToolRecommendation::new(
      "project_info",
      "User wants project information",
      0.80,
      "analysis"
    ))
  }
  
  // Environment
  if lower_input.contains("env") || lower_input.contains("environment") || lower_input.contains("system") {
    recommendations.push(ToolRecommendation::new(
      "env_info",
      "User wants environment information",
      0.85,
      "analysis"
    ))
  }
  
  // Memory operations
  if lower_input.contains("remember") || lower_input.contains("save") || lower_input.contains("memory") {
    recommendations.push(ToolRecommendation::new(
      "memory_write",
      "User wants to save information to memory",
      0.80,
      "memory"
    ))
  }
  
  if lower_input.contains("recall") || lower_input.contains("history") || lower_input.contains("previous") {
    recommendations.push(ToolRecommendation::new(
      "memory_read",
      "User wants to recall saved information",
      0.80,
      "memory"
    ))
  }
  
  // File exploration shortcuts
  if lower_input.contains("head") || lower_input.contains("first") || lower_input.contains("top") {
    recommendations.push(ToolRecommendation::new(
      "head_file",
      "User wants to see the beginning of a file",
      0.85,
      "file_operations"
    ))
  }
  
  if lower_input.contains("tail") || lower_input.contains("last") || lower_input.contains("end") {
    recommendations.push(ToolRecommendation::new(
      "tail_file",
      "User wants to see the end of a file",
      0.85,
      "file_operations"
    ))
  }
  
  // Information gathering
  if lower_input.contains("what") || lower_input.contains("how") || lower_input.contains("when") {
    if lower_input.contains("time") || lower_input.contains("date") {
      recommendations.push(ToolRecommendation::new(
        "timestamp",
        "User wants date/time information",
        0.75,
        "utilities"
      ))
    }
  }
  
  recommendations
}

///|
/// Discover tools by scanning project structure
///
pub fn ToolDiscoverer::scan_project(self : ToolDiscoverer, root_path : String) -> Array[ToolRecommendation] {
  let recommendations : Array[ToolRecommendation] = []
  
  // Check for common project files
  if file_exists(root_path + "/package.json") {
    recommendations.push(ToolRecommendation::new(
      "read_file",
      "Node.js project detected - package.json found",
      0.90,
      "project_detection"
    ))
  }
  
  if file_exists(root_path + "/Cargo.toml") {
    recommendations.push(ToolRecommendation::new(
      "read_file",
      "Rust project detected - Cargo.toml found",
      0.90,
      "project_detection"
    ))
  }
  
  if file_exists(root_path + "/go.mod") {
    recommendations.push(ToolRecommendation::new(
      "read_file",
      "Go project detected - go.mod found",
      0.90,
      "project_detection"
    ))
  }
  
  if file_exists(root_path + "/moon.mod") {
    recommendations.push(ToolRecommendation::new(
      "read_file",
      "MoonBit project detected - moon.mod found",
      0.90,
      "project_detection"
    ))
  }
  
  if file_exists(root_path + "/Makefile") || file_exists(root_path + "/makefile") {
    recommendations.push(ToolRecommendation::new(
      "run_command",
      "Makefile detected - build automation available",
      0.85,
      "project_detection"
    ))
  }
  
  // Check for .git directory
  let git_entries = list_dir(root_path)
  if git_entries.contains(".git") {
    recommendations.push(ToolRecommendation::new(
      "git_status",
      "Git repository detected",
      0.95,
      "project_detection"
    ))
  }
  
  recommendations
}

///|
/// Format recommendations for display
///
pub fn ToolDiscoverer::render_recommendations(self : ToolDiscoverer, recommendations : Array[ToolRecommendation]) -> String {
  if recommendations.length() == 0 {
    return "No specific tools recommended. Use /tools to see all available tools."
  }
  
  let mut out = "💡 Recommended tools:\n\n"
  
  // Group by category
  let categories : Array[String] = []
  for r in recommendations {
    if !categories.contains(r.category) {
      categories.push(r.category)
    }
  }
  
  for cat in categories {
    out = out + "📁 " + cat + "\n"
    for r in recommendations {
      if r.category == cat {
        let conf_bar = if r.confidence >= 0.9 { "███" } 
                       else if r.confidence >= 0.8 { "██░" } 
                       else if r.confidence >= 0.7 { "█░░" } 
                       else { "░░░" }
        out = out + "   " + conf_bar + " " + r.tool_name + " - " + r.reason + "\n"
      }
    }
    out = out + "\n"
  }
  
  out
}

///|
/// Get quick suggestions (top 3)
///
pub fn ToolDiscoverer::quick_suggestions(self : ToolDiscoverer, input : String) -> String {
  let recs = self.analyze_input(input)
  
  if recs.length() == 0 {
    return ""
  }
  
  // Sort by confidence (simple bubble sort for small array)
  let sorted = recs
  for i in 0..<sorted.length() {
    for j in (i + 1)..<(if sorted.length() > 3 { 3 } else { sorted.length() }) {
      if sorted[i].confidence < sorted[j].confidence {
        let temp = sorted[i]
        sorted[i] = sorted[j]
        sorted[j] = temp
      }
    }
  }
  
  let mut suggestions = "Try:"
  let limit = if sorted.length() > 3 { 3 } else { sorted.length() }
  for i in 0..<limit {
    suggestions = suggestions + " /" + sorted[i].tool_name
  }
  
  suggestions
}
