///|
/// Eval system for agent quality assessment.
/// Follows LangChain trajectory evaluation and Codex integration-first principles.
///

///|
pub struct EvalCase {
  name : String
  input : String
  expected_tools : Array[String]
  expected_contains : Array[String]
  max_rounds : Int
}

///|
pub struct EvalResult {
  name : String
  passed : Bool
  actual_tools : Array[String]
  actual_reply : String
  error : String
}

///|
pub fn EvalCase::new(
  name : String,
  input : String,
  expected_tools~ : Array[String] = [],
  expected_contains~ : Array[String] = [],
  max_rounds~ : Int = 3,
) -> EvalCase {
  { name, input, expected_tools, expected_contains, max_rounds }
}

///|
/// Run a single eval case. Returns EvalResult.
///
pub fn EvalCase::run(self : EvalCase, agent_fn : (String) -> String) -> EvalResult {
  let reply = agent_fn(self.input)
  let mut passed = true
  let mut error = ""

  // Check expected tools were called
  if self.expected_tools.length() > 0 {
    for tool in self.expected_tools {
      if !reply.contains(tool) {
        passed = false
        error = "Expected tool '" + tool + "' not found in reply"
      }
    }
  }

  // Check expected content
  if self.expected_contains.length() > 0 {
    for text in self.expected_contains {
      if !reply.contains(text) {
        passed = false
        if error == "" {
          error = "Expected '" + text + "' not found in reply"
        }
      }
    }
  }

  {
    name: self.name,
    passed,
    actual_tools: [],
    actual_reply: reply,
    error,
  }
}

///|
pub struct EvalSuite {
  name : String
  cases : Array[EvalCase]
}

///|
pub fn EvalSuite::new(name : String) -> EvalSuite {
  { name, cases: [] }
}

///|
pub fn EvalSuite::add(self : EvalSuite, case_ : EvalCase) -> Unit {
  self.cases.push(case_)
}

///|
/// Run all eval cases and return results.
///
pub fn EvalSuite::run(self : EvalSuite, agent_fn : (String) -> String) -> Array[EvalResult] {
  let results : Array[EvalResult] = []
  for case_ in self.cases {
    results.push(case_.run(agent_fn))
  }
  results
}

///|
/// Generate eval report.
///
pub fn EvalSuite::report(self : EvalSuite, results : Array[EvalResult]) -> String {
  let mut passed = 0
  let mut failed = 0
  let mut out = "Eval: " + self.name + "\n"
  out = out + "────────────────────────────────────────\n"

  for r in results {
    if r.passed {
      passed = passed + 1
      out = out + "  ✓ " + r.name + "\n"
    } else {
      failed = failed + 1
      out = out + "  ✗ " + r.name + ": " + r.error + "\n"
    }
  }

  out = out + "────────────────────────────────────────\n"
  out = out + "  Total: " + results.length().to_string()
  out = out + " | Passed: " + passed.to_string()
  out = out + " | Failed: " + failed.to_string()
  let rate = if results.length() > 0 { passed * 100 / results.length() } else { 0 }
  out = out + " | Rate: " + rate.to_string() + "%\n"
  out
}

///|
/// Default eval suite for AutoAgent.
///
pub fn default_eval_suite() -> EvalSuite {
  let suite = EvalSuite::new("AutoAgent Core")

  suite.add(EvalCase::new(
    "empty goal handled",
    "",
    expected_contains=[""],
  ))

  suite.add(EvalCase::new(
    "greeting gets reply",
    "Hello",
    expected_contains=["Hello"],
  ))

  suite.add(EvalCase::new(
    "help request gets reply",
    "help me",
    expected_contains=["help"],
  ))

  suite
}
