///|
pub(all) struct SkillTool {
  name : String
  description : String
  category : String
  risk : RiskLevel
}

///|
pub(all) struct Skill {
  name : String
  description : String
  category : String
  instructions : String
  tools : Array[SkillTool]
  keywords : Array[String]
}

///|
pub fn Skill::new(
  name : String,
  description : String,
  category : String,
  instructions : String,
  tools : Array[SkillTool],
  keywords : Array[String],
) -> Skill {
  { name, description, category, instructions, tools, keywords }
}

///|
pub fn Skill::tool_names(self : Skill) -> Array[String] {
  let names : Array[String] = []
  for t in self.tools {
    names.push(t.name)
  }
  names
}

///|
pub fn Skill::has_tool(self : Skill, name : String) -> Bool {
  for t in self.tools {
    if t.name == name {
      return true
    }
  }
  false
}

///|
pub fn SkillTool::new(
  name : String,
  description : String,
  category : String,
  risk : RiskLevel,
) -> SkillTool {
  { name, description, category, risk }
}

///|
pub(all) struct SkillRegistry {
  mut skills : Array[Skill]
}

///|
pub fn SkillRegistry::new() -> SkillRegistry {
  { skills: [] }
}

///|
pub fn SkillRegistry::register(self : SkillRegistry, skill : Skill) -> Unit {
  self.skills.push(skill)
}

///|
pub fn SkillRegistry::find(self : SkillRegistry, name : String) -> Skill? {
  for s in self.skills {
    if s.name == name {
      return Some(s)
    }
  }
  None
}

///|
pub fn SkillRegistry::all(self : SkillRegistry) -> Array[Skill] {
  self.skills
}

///|
pub fn SkillRegistry::names(self : SkillRegistry) -> Array[String] {
  let names : Array[String] = []
  for s in self.skills {
    names.push(s.name)
  }
  names
}

///|
pub fn SkillRegistry::select_for_goal(self : SkillRegistry, goal : String) -> Array[Skill] {
  let lower = goal[:].to_lower().to_owned()
  let selected : Array[Skill] = []
  for s in self.skills {
    for kw in s.keywords {
      if lower.contains(kw) && !skill_array_contains(selected, s.name) {
        selected.push(s)
      }
    }
  }
  selected
}

///|
fn skill_array_contains(arr : Array[Skill], name : String) -> Bool {
  for s in arr {
    if s.name == name {
      return true
    }
  }
  false
}

///|
pub fn SkillRegistry::all_tools(self : SkillRegistry) -> Array[Tool] {
  let tools : Array[Tool] = []
  for s in self.skills {
    for t in s.tools {
      tools.push(Tool::new(t.name, t.description, t.category, t.risk))
    }
  }
  tools
}

///|
pub fn SkillRegistry::all_instructions(self : SkillRegistry) -> String {
  let mut out = ""
  for s in self.skills {
    if s.instructions != "" {
      if out != "" { out = out + "\n\n" }
      out = out + "[" + s.name + " Skill]\n" + s.instructions
    }
  }
  out
}

///|
pub fn SkillRegistry::render_skill_list(self : SkillRegistry) -> String {
  if self.skills.length() == 0 {
    return "No skills loaded."
  }
  let mut out = "Loaded skills:\n"
  for s in self.skills {
    out = out + "  " + s.name + " - " + s.description + " (" + s.category + ")\n"
    out = out + "    tools: "
    let tool_names = s.tool_names()
    for i, tn in tool_names {
      if i > 0 { out = out + ", " }
      out = out + tn
    }
    out = out + "\n"
  }
  out
}

///|
pub fn SkillRegistry::render_skill_detail(self : SkillRegistry, name : String) -> String {
  match self.find(name) {
    Some(s) => {
      let mut out = "Skill: " + s.name + "\n"
      out = out + "Description: " + s.description + "\n"
      out = out + "Category: " + s.category + "\n"
      if s.instructions != "" {
        out = out + "\nInstructions:\n" + s.instructions + "\n"
      }
      if s.tools.length() > 0 {
        out = out + "\nTools:\n"
        for t in s.tools {
          out = out + "  - " + t.name + ": " + t.description + " (risk: " + render_risk_level(t.risk) + ")\n"
        }
      }
      if s.keywords.length() > 0 {
        out = out + "\nKeywords: "
        for i, kw in s.keywords {
          if i > 0 { out = out + ", " }
          out = out + kw
        }
        out = out + "\n"
      }
      out
    }
    None => "Skill not found: " + name
  }
}

///|
pub fn SkillRegistry::execute_skill_tool(self : SkillRegistry, tool_name : String, input : String) -> StepResult {
  for s in self.skills {
    if s.has_tool(tool_name) {
      return execute_builtin_skill_tool(s.name, tool_name, input)
    }
  }
  Failure("Unknown skill tool: " + tool_name)
}

///|
fn execute_builtin_skill_tool(skill_name : String, tool_name : String, input : String) -> StepResult {
  match tool_name {
    "research-search" => Success(research_search(input))
    "research-summarize" => Success(research_summarize(input))
    "review-analyze" => Success(review_analyze(input))
    "review-suggest" => Success(review_suggest(input))
    "docs-generate" => Success(docs_generate(input))
    "docs-explain" => Success(docs_explain(input))
    "test-create" => Success(test_create(input))
    "test-coverage" => Success(test_coverage(input))
    _ => Failure("Skill tool not implemented: " + tool_name + " (skill: " + skill_name + ")")
  }
}

// ============================================================
// Research Assistant skill tools
// ============================================================

///|
fn research_search(query : String) -> String {
  "Here is what I found for '\{query}':\n\n1. Official docs and API references.\n2. Community guides and best practices.\n3. Technical blog posts with examples.\n4. Open source implementations.\n5. Comparison articles.\n\nWant me to summarize the key findings?"
}

///|
fn research_summarize(topic : String) -> String {
  "Summary for '\{topic}':\n\n- Well-established patterns exist in production systems.\n- Common pitfalls: missing error handling, no observability.\n- Recommended: start simple, add tests, then optimize.\n\nNext steps:\n1. Build a minimal prototype.\n2. Write 3-5 acceptance tests.\n3. Document known limitations."
}

///|
fn review_analyze(code_desc : String) -> String {
  "Reviewing '\{code_desc}':\n\n1. Correctness: edge cases covered? Error paths handled?\n2. Readability: names clear? Flow easy to follow?\n3. Design: single responsibility? Right abstraction?\n4. Safety: input validation? Injection risks?\n5. Performance: bottlenecks? Unnecessary allocations?\n\nFocus on correctness first, then readability."
}

///|
fn review_suggest(area : String) -> String {
  "Suggestions for '\{area}':\n\n1. Add input validation at boundaries.\n2. Extract complex logic into named helpers.\n3. Add unit tests for each error path.\n4. Document the 'why' behind non-obvious decisions.\n5. Add structured logging for observability.\n\nPriority: correctness > readability > performance."
}

///|
fn docs_generate(subject : String) -> String {
  "Documentation outline for '\{subject}':\n\n# \{subject}\n\n## Overview\nWhat it does and why.\n\n## Quick Start\nMinimal example.\n\n## API Reference\nTypes, functions, parameters.\n\n## Examples\nCommon use cases.\n\n## Configuration\nOptions and defaults.\n\n## Troubleshooting\nCommon errors and fixes.\n\nWant me to fill in any section?"
}

///|
fn docs_explain(concept : String) -> String {
  "About '\{concept}':\n\nWhat: a clear definition.\nHow: step-by-step mechanism.\nWhen to use: appropriate cases.\nWhen not: anti-patterns and alternatives.\nExample: minimal working code.\n\nWant me to go deeper on any part?"
}

///|
fn test_create(component : String) -> String {
  "Test plan for '\{component}':\n\nUnit tests:\n1. Happy path: normal input, expected output.\n2. Boundary: empty, max length, zero.\n3. Error: invalid input, missing fields.\n\nIntegration tests:\n1. End-to-end with real deps.\n2. Failure injection.\n\nFirst test to write: happy path with most common input."
}

///|
fn test_coverage(scope : String) -> String {
  "Coverage gaps in '\{scope}':\n\n- Error handling paths often untested.\n- Edge cases in parsing and conversion.\n- Race conditions in concurrent code.\n\nRecommended:\n1. One test per error return.\n2. One test per boundary value.\n3. One test per config combo.\n\nTarget: 80% line, 100% public API error paths."
}

///|
pub fn default_skill_registry() -> SkillRegistry {
  let registry = SkillRegistry::new()

  registry.register(Skill::new(
    "research",
    "Research assistant for gathering, analyzing, and synthesizing information.",
    "knowledge",
    "You are a research assistant. When given a topic, search for relevant sources, extract key findings, and synthesize them into actionable summaries. Save validated findings to experience memory. Always cite the type of source (official docs, community guide, paper, etc.).",
    [
      SkillTool::new("research-search", "Search for relevant sources on a topic.", "knowledge", Low),
      SkillTool::new("research-summarize", "Synthesize findings into an actionable summary.", "knowledge", Low),
    ],
    ["research", "investigate", "study", "analyze topic", "find information", "look up"],
  ))

  registry.register(Skill::new(
    "code-review",
    "Code review assistant for analyzing code quality and suggesting improvements.",
    "quality",
    "You are a code review assistant. Analyze code for correctness, readability, design, safety, and performance. Provide specific, actionable suggestions. Prioritize correctness over style. Always explain WHY a change is recommended.",
    [
      SkillTool::new("review-analyze", "Analyze code quality across multiple dimensions.", "quality", Low),
      SkillTool::new("review-suggest", "Suggest specific improvements for an area.", "quality", Low),
    ],
    ["review", "code quality", "refactor", "improve code", "clean code", "code smell"],
  ))

  registry.register(Skill::new(
    "docs",
    "Documentation assistant for generating and explaining technical documentation.",
    "documentation",
    "You are a documentation assistant. Generate clear, structured documentation that serves both beginners and experienced users. Always include examples. Use consistent formatting.",
    [
      SkillTool::new("docs-generate", "Generate a documentation outline for a subject.", "documentation", Low),
      SkillTool::new("docs-explain", "Explain a concept with definition, mechanism, and examples.", "documentation", Low),
    ],
    ["document", "documentation", "write docs", "explain", "README", "API reference", "guide"],
  ))

  registry.register(Skill::new(
    "testing",
    "Testing assistant for creating test plans and analyzing coverage.",
    "quality",
    "You are a testing assistant. Create comprehensive test plans covering unit, integration, and acceptance tests. Prioritize the happy path first, then error paths, then edge cases. Always suggest the most valuable test to write next.",
    [
      SkillTool::new("test-create", "Create a test plan for a component.", "quality", Low),
      SkillTool::new("test-coverage", "Analyze coverage gaps and recommend additions.", "quality", Low),
    ],
    ["test", "testing", "unit test", "coverage", "QA", "quality assurance", "TDD"],
  ))

  registry
}
