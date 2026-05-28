///|
pub fn check_soft_phrases(text : String) -> Array[String] {
  let phrases = ["建议", "可以考虑", "根据情况", "灵活把握", "视情况而定"]
  let found : Array[String] = []
  for phrase in phrases {
    if text.contains(phrase) {
      found.push(phrase)
    }
  }
  found
}

///|
pub fn check_failure_branching(text : String) -> Bool {
  (text.contains("if") || text.contains("when") || text.contains("如果")) &&
  (text.contains("else") || text.contains("otherwise") || text.contains("否则"))
}

///|
pub fn get_anti_patterns() -> Array[String] {
  [
    "Same AI reviews and modifies (SkillLens: 46.4% accuracy)",
    "git reset --hard instead of git revert",
    "Adding redundant content to inflate scores",
    "Scoring without real test prompts",
    "Modifying multiple dimensions at once",
    "Dry-run exceeds 30% of runs",
    "Silently skipping anomalies",
    "Ignoring dimension correlation clusters",
  ]
}

///|
pub fn render_anti_patterns() -> String {
  let patterns = get_anti_patterns()
  let mut out = header("=== Anti-Pattern Blacklist ===") + "\n"
  out = out + dim_text("From Darwin 2.0 + SkillLens paper (arXiv 2605.23899)") + "\n\n"
  for i, pattern in patterns {
    out = out + "  " + ansi_red() + "\{i + 1}." + ansi_reset() + " " + pattern + "\n"
  }
  out
}
