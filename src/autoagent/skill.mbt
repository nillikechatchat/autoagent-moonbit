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
    "codegen-implement" => Success(codegen_implement(input))
    "codegen-scaffold" => Success(codegen_scaffold(input))
    "debug-diagnose" => Success(debug_diagnose(input))
    "debug-fix" => Success(debug_fix(input))
    "refactor-extract" => Success(refactor_extract(input))
    "refactor-simplify" => Success(refactor_simplify(input))
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

// ============================================================
// Code Generation skill tools
// ============================================================

///|
fn codegen_implement(spec : String) -> String {
  "Implementation plan for '\{spec}':\n\n1. Define types (struct/enum) for data model.\n2. Write function signatures with clear inputs/outputs.\n3. Implement core logic with error handling.\n4. Add input validation at boundaries.\n5. Write unit tests (happy path, error, edge).\n\nTDD order:\n- Write failing test for happy path.\n- Implement minimal code to pass.\n- Add error path tests.\n- Refactor if needed.\n\nShall I generate the code?"
}

///|
fn codegen_scaffold(project : String) -> String {
  "Scaffolding for '\{project}':\n\nDirectory structure:\n  src/\n    main.mbt       # Entry point\n    moon.pkg         # Package config\n  test/\n    main_test.mbt    # Tests\n  README.md\n  moon.mod\n\nBoilerplate:\n1. moon.mod with name, version, deps.\n2. moon.pkg with imports.\n3. main.mbt with entry point.\n4. Basic test file.\n\nShall I create these files?"
}

// ============================================================
// Debugging skill tools (5-step methodology)
// ============================================================

///|
fn debug_diagnose(issue : String) -> String {
  "Diagnosing '\{issue}':\n\nStep 1 - Reproduce:\n- What input triggers the issue?\n- Is it consistent or intermittent?\n- Minimal reproduction case?\n\nStep 2 - Isolate:\n- Which component is responsible?\n- What changed recently?\n- Check logs and error messages.\n\nStep 3 - Root cause:\n- Is it a logic error, type error, or runtime error?\n- Is it in input handling, core logic, or output?\n- Does it affect all inputs or specific cases?\n\nShall I help narrow down the root cause?"
}

///|
fn debug_fix(diagnosis : String) -> String {
  "Fix strategy for '\{diagnosis}':\n\nStep 4 - Fix:\n- Write a failing test that reproduces the bug.\n- Make the minimal change to fix it.\n- Verify the test passes.\n- Verify no regressions.\n\nStep 5 - Prevent:\n- Add regression test.\n- Add input validation if missing.\n- Document the root cause.\n- Consider if similar bugs exist elsewhere.\n\nPriority: fix the root cause, not the symptom."
}

// ============================================================
// Refactoring skill tools (safe incremental changes)
// ============================================================

///|
fn refactor_extract(code_desc : String) -> String {
  "Extract refactoring for '\{code_desc}':\n\n1. Identify complex logic blocks (>10 lines).\n2. Name the block after its intent.\n3. Extract into a new function.\n4. Replace inline code with function call.\n5. Run tests to verify no behavior change.\n\nRules:\n- Each extracted function does ONE thing.\n- Function name describes WHAT, not HOW.\n- Keep inputs/outputs explicit.\n- No hidden side effects.\n\nShall I identify extraction candidates?"
}

///|
fn refactor_simplify(code_desc : String) -> String {
  "Simplify refactoring for '\{code_desc}':\n\nCommon patterns:\n1. Deep nesting -> early returns.\n2. Long conditionals -> pattern matching.\n3. Magic numbers -> named constants.\n4. Repeated patterns -> helper functions.\n5. Complex expressions -> intermediate variables.\n\nSafety checklist:\n- [ ] All tests pass before starting.\n- [ ] Each change is a single commit.\n- [ ] Run tests after each change.\n- [ ] No behavior change.\n\nShall I suggest specific simplifications?"
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

  registry.register(Skill::new(
    "code-gen",
    "Code generation assistant for creating implementations from specifications.",
    "development",
    "You are a code generation assistant. Generate clean, well-structured code from specifications. Follow TDD: write tests first, then implement. Always include error handling, input validation, and clear naming. Use the project's existing patterns and libraries.",
    [
      SkillTool::new("codegen-implement", "Generate implementation from a specification.", "development", Low),
      SkillTool::new("codegen-scaffold", "Generate project scaffolding and boilerplate.", "development", Low),
    ],
    ["generate", "implement", "create code", "build", "scaffold", "boilerplate", "code generation"],
  ))

  registry.register(Skill::new(
    "debug",
    "Debugging assistant for systematic problem diagnosis and resolution.",
    "quality",
    "You are a debugging assistant. Follow the 5-step debugging methodology: 1) Reproduce the issue, 2) Isolate the root cause, 3) Simplify the reproduction, 4) Fix the bug, 5) Add regression prevention. Always start with the smallest possible reproduction. Never fix symptoms - find root causes.",
    [
      SkillTool::new("debug-diagnose", "Diagnose a bug using systematic analysis.", "quality", Low),
      SkillTool::new("debug-fix", "Suggest a fix with regression prevention.", "quality", Low),
    ],
    ["debug", "bug", "error", "fix", "diagnose", "troubleshoot", "issue", "problem"],
  ))

  registry.register(Skill::new(
    "refactor",
    "Refactoring assistant for safe, incremental code improvements.",
    "quality",
    "You are a refactoring assistant. Make small, safe, incremental changes. Each change must pass all existing tests. Follow the boy scout rule: leave code cleaner than you found it. Prioritize: 1) Extract complex logic, 2) Remove duplication, 3) Improve naming, 4) Simplify control flow. Never refactor and add features at the same time.",
    [
      SkillTool::new("refactor-extract", "Extract complex logic into named functions.", "quality", Low),
      SkillTool::new("refactor-simplify", "Simplify code while preserving behavior.", "quality", Low),
    ],
    ["refactor", "clean up", "simplify", "extract", "rename", "restructure", "improve code"],
  ))

  registry
}
