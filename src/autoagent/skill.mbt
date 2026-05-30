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
    "security-scan" => Success(security_scan(input))
    "security-fix" => Success(security_fix(input))
    "perf-analyze" => Success(perf_analyze(input))
    "perf-optimize" => Success(perf_optimize(input))
    "arch-design" => Success(arch_design(input))
    "arch-review" => Success(arch_review(input))
    _ => Failure("Skill tool not implemented: " + tool_name + " (skill: " + skill_name + ")")
  }
}

// ============================================================
// Research Assistant skill tools
// ============================================================

///|
fn research_search(query : String) -> String {
  "Research brief for '\{query}':\n\nSources to prioritize:\n1. Official documentation and API references.\n2. Release notes and migration guides.\n3. Maintainer examples and source repository samples.\n4. Production case studies and benchmark reports.\n5. Community guides after official sources are checked.\n\nOutput format:\n- Key facts with source type.\n- Risks and unknowns.\n- Recommended next action."
}

///|
fn research_summarize(topic : String) -> String {
  "Research summary for '\{topic}':\n\nFindings:\n- Stable production patterns usually combine simple interfaces, explicit error handling, and observability.\n- Risk concentrates around implicit assumptions, hidden state, and untested failure paths.\n- The most reliable rollout path is prototype, tests, documentation, then optimization.\n\nAction plan:\n1. Build a minimal prototype.\n2. Write 3-5 acceptance tests.\n3. Record assumptions and known limitations."
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
  "Documentation draft for '\{subject}':\n\n# \{subject}\n\n## Overview\nPurpose, scope, and primary users.\n\n## Quick Start\nMinimal working example and expected output.\n\n## API Reference\nTypes, functions, parameters, return values, and errors.\n\n## Examples\nCommon workflows with copyable commands or code.\n\n## Configuration\nOptions, defaults, and environment variables.\n\n## Troubleshooting\nSymptoms, causes, and fixes."
}

///|
fn docs_explain(concept : String) -> String {
  "Concept explanation for '\{concept}':\n\nDefinition: concise description of the concept.\nMechanism: step-by-step explanation of how it works.\nUse cases: situations where it creates value.\nAlternatives: related patterns and trade-offs.\nExample: minimal working code or command."
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
  "Implementation plan for '\{spec}':\n\n1. Define data model types with clear ownership and validation rules.\n2. Write function signatures with explicit inputs and outputs.\n3. Implement core logic with boundary checks and error handling.\n4. Add tests for happy path, error path, and edge cases.\n5. Run the project quality gate.\n\nTDD order:\n- Write a failing happy-path test.\n- Implement the minimal code to pass.\n- Add error-path tests.\n- Refactor after behavior is covered."
}

///|
fn codegen_scaffold(project : String) -> String {
  "Scaffold plan for '\{project}':\n\nDirectory structure:\n  src/\n    main.mbt         # Entry point\n    moon.pkg         # Package config\n  test/\n    main_test.mbt    # Tests\n  README.md\n  moon.mod\n\nBoilerplate checklist:\n1. moon.mod with name, version, and dependencies.\n2. moon.pkg with imports and exports.\n3. main.mbt with entry point and argument handling.\n4. Basic test file with one passing test.\n5. README with build, test, and run commands."
}

// ============================================================
// Debugging skill tools (5-step methodology)
// ============================================================

///|
fn debug_diagnose(issue : String) -> String {
  "Diagnosis worksheet for '\{issue}':\n\nStep 1 - Reproduce:\n- Record the exact input, command, and environment.\n- Capture expected behavior and actual behavior.\n- Reduce the case to the smallest failing path.\n\nStep 2 - Isolate:\n- Identify the component boundary where behavior changes.\n- Compare recent changes with the last known good state.\n- Check logs, return values, and persisted data.\n\nStep 3 - Root cause:\n- Classify the defect as logic, type, runtime, integration, or environment.\n- Identify the violated invariant.\n- Write a regression test that fails for the current behavior."
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
  "Extract refactoring plan for '\{code_desc}':\n\n1. Identify logic blocks with a single intent and multiple statements.\n2. Name each block after the domain behavior it represents.\n3. Extract into a function with explicit inputs and outputs.\n4. Replace inline code with the function call.\n5. Run tests to verify behavior preservation.\n\nRules:\n- Each extracted function has one responsibility.\n- Function names describe intent.\n- Inputs and outputs stay explicit.\n- Side effects stay visible at call sites."
}

///|
fn refactor_simplify(code_desc : String) -> String {
  "Simplify refactoring plan for '\{code_desc}':\n\nCommon patterns:\n1. Deep nesting -> guard clauses or smaller functions.\n2. Long conditionals -> pattern matching or named predicates.\n3. Magic numbers -> named constants.\n4. Repeated patterns -> focused helpers.\n5. Complex expressions -> intermediate variables with domain names.\n\nSafety checklist:\n- [ ] Baseline tests pass before editing.\n- [ ] Each change preserves behavior.\n- [ ] Tests run after each logical change.\n- [ ] Public interfaces stay stable unless the task requires an API change."
}

// ============================================================
// Security skill tools
// ============================================================

///|
fn security_scan(code_desc : String) -> String {
  "Security scan for '\{code_desc}':\n\nOWASP Top 10 checklist:\n1. Injection: SQL, command, LDAP injection risks?\n2. Broken Auth: weak passwords, session fixation?\n3. Sensitive Data: hardcoded secrets, unencrypted data?\n4. XML External Entities: XXE vulnerabilities?\n5. Broken Access Control: missing authorization checks?\n6. Security Misconfiguration: default credentials, debug mode?\n7. XSS: unescaped user input in output?\n8. Insecure Deserialization: untrusted data deserialization?\n9. Known Vulnerabilities: outdated dependencies?\n10. Insufficient Logging: missing audit trails?\n\nPriority: fix injection and auth issues first."
}

///|
fn security_fix(vulnerability : String) -> String {
  "Security fix for '\{vulnerability}':\n\nCommon fixes:\n- SQL Injection: Use parameterized queries.\n- XSS: Escape all user input in output.\n- CSRF: Add anti-CSRF tokens.\n- Path Traversal: Validate and sanitize file paths.\n- Command Injection: Use allowlists, not blocklists.\n- Hardcoded Secrets: Use environment variables.\n- Weak Auth: Implement rate limiting, MFA.\n\nAlways:\n1. Validate input at boundaries.\n2. Escape output at render time.\n3. Use least privilege principle.\n4. Log security events."
}

// ============================================================
// Performance skill tools
// ============================================================

///|
fn perf_analyze(code_desc : String) -> String {
  "Performance analysis for '\{code_desc}':\n\nCommon bottlenecks:\n1. Algorithmic: O(n²) loops, unnecessary iterations.\n2. Memory: excessive allocations, memory leaks.\n3. I/O: blocking calls, N+1 queries.\n4. Network: unnecessary requests, large payloads.\n5. Caching: missing cache, cache invalidation.\n\nMeasurement:\n- Profile before optimizing.\n- Measure latency (p50, p95, p99).\n- Monitor memory usage.\n- Track throughput.\n\nRule: Don't optimize what you haven't measured."
}

///|
fn perf_optimize(bottleneck : String) -> String {
  "Optimization for '\{bottleneck}':\n\nStrategies:\n- Algorithmic: Use appropriate data structures.\n- Memory: Pool allocations, use slices.\n- I/O: Batch operations, use async.\n- Network: Compress, cache, paginate.\n- Caching: LRU cache, memoization.\n\nAlways:\n1. Measure before and after.\n2. Verify correctness preserved.\n3. Document the optimization.\n4. Add performance tests."
}

// ============================================================
// Architecture skill tools
// ============================================================

///|
fn arch_design(requirements : String) -> String {
  "Architecture design for '\{requirements}':\n\nDesign process:\n1. Identify components and responsibilities.\n2. Define interfaces and contracts.\n3. Choose communication patterns.\n4. Plan data flow and storage.\n5. Consider scalability and reliability.\n\nPrinciples:\n- Single Responsibility: one reason to change.\n- Open/Closed: extend, don't modify.\n- Dependency Inversion: depend on abstractions.\n- Interface Segregation: small, focused interfaces.\n\nDocument: component diagram, sequence diagram, data model."
}

///|
fn arch_review(design : String) -> String {
  "Architecture review for '\{design}':\n\nReview checklist:\n- [ ] Clear component boundaries?\n- [ ] Appropriate abstraction levels?\n- [ ] Testable in isolation?\n- [ ] Scalable horizontally?\n- [ ] Failure modes handled?\n- [ ] Data consistency maintained?\n- [ ] Security boundaries defined?\n- [ ] Observability built in?\n\nTrade-offs:\n- Consistency vs Availability.\n- Simplicity vs Flexibility.\n- Performance vs Maintainability."
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

  registry.register(Skill::new(
    "security",
    "Security assistant for identifying and fixing security vulnerabilities.",
    "quality",
    "You are a security assistant. Analyze code for common vulnerabilities: SQL injection, XSS, CSRF, path traversal, command injection, hardcoded secrets, insecure defaults. Follow OWASP Top 10. Always provide specific fix suggestions with code examples.",
    [
      SkillTool::new("security-scan", "Scan code for security vulnerabilities.", "quality", Low),
      SkillTool::new("security-fix", "Suggest security fixes with code examples.", "quality", Low),
    ],
    ["security", "vulnerability", "injection", "XSS", "CSRF", "authentication", "authorization", "encryption"],
  ))

  registry.register(Skill::new(
    "performance",
    "Performance assistant for identifying and fixing performance issues.",
    "quality",
    "You are a performance assistant. Analyze code for performance bottlenecks: unnecessary allocations, O(n²) loops, missing caching, N+1 queries, memory leaks. Suggest measurable optimizations. Always measure before optimizing.",
    [
      SkillTool::new("perf-analyze", "Analyze code for performance bottlenecks.", "quality", Low),
      SkillTool::new("perf-optimize", "Suggest performance optimizations.", "quality", Low),
    ],
    ["performance", "optimize", "slow", "fast", "cache", "memory", "CPU", "latency", "throughput"],
  ))

  registry.register(Skill::new(
    "architecture",
    "Architecture assistant for system design and architectural decisions.",
    "development",
    "You are an architecture assistant. Help with system design, component decomposition, API design, data modeling, and architectural decisions. Follow SOLID principles. Consider scalability, maintainability, and testability. Always explain trade-offs.",
    [
      SkillTool::new("arch-design", "Design system architecture.", "development", Low),
      SkillTool::new("arch-review", "Review architectural decisions.", "development", Low),
    ],
    ["architecture", "design", "system design", "API design", "component", "module", "microservice", "monolith"],
  ))

  registry
}
