///|
pub(all) struct Example {
  title : String
  goal : String
  description : String
  difficulty : String
}

///|
pub fn get_examples() -> Array[Example] {
  [
    {
      title: "Create a Chatbot",
      goal: "build a chatbot that answers FAQ about my product",
      description: "Learn how to create a simple FAQ chatbot for your product or service.",
      difficulty: "beginner",
    },
    {
      title: "Build a Research Assistant",
      goal: "create a research assistant that can plan, call safe tools, and teach the user how to improve prompts",
      description: "Build an agent that helps with research tasks and teaches prompt engineering.",
      difficulty: "beginner",
    },
    {
      title: "Design a REST API",
      goal: "design a REST API for a todo list application with CRUD operations",
      description: "Plan and design a RESTful API with proper endpoints and data models.",
      difficulty: "intermediate",
    },
    {
      title: "Plan a Database Migration",
      goal: "plan a migration from MySQL to PostgreSQL with zero downtime",
      description: "Create a step-by-step migration plan with rollback strategies.",
      difficulty: "advanced",
    },
    {
      title: "Create a CLI Tool",
      goal: "build a command-line tool that processes CSV files and generates reports",
      description: "Design a CLI tool with proper argument parsing and output formatting.",
      difficulty: "intermediate",
    },
    {
      title: "Write Unit Tests",
      goal: "write comprehensive unit tests for a user authentication module",
      description: "Create test cases covering happy paths, edge cases, and error scenarios.",
      difficulty: "intermediate",
    },
    {
      title: "Set Up CI/CD",
      goal: "set up a CI/CD pipeline for a Node.js project with GitHub Actions",
      description: "Configure automated testing, building, and deployment workflows.",
      difficulty: "intermediate",
    },
    {
      title: "Create Documentation",
      goal: "write comprehensive API documentation for a REST API",
      description: "Generate clear, structured documentation with examples and schemas.",
      difficulty: "beginner",
    },
  ]
}

///|
pub fn format_examples() -> String {
  let examples = get_examples()
  let mut out = header("=== Example Goals ===") + "\n"
  out = out + dim_text("Try these examples to get started:") + "\n\n"
  for i, example in examples {
    let num = ansi_cyan() + "\{i + 1}." + ansi_reset()
    let title = bold_text(example.title)
    let diff = match example.difficulty {
      "beginner" => ansi_green() + "[beginner]" + ansi_reset()
      "intermediate" => ansi_yellow() + "[intermediate]" + ansi_reset()
      "advanced" => ansi_red() + "[advanced]" + ansi_reset()
      _ => example.difficulty
    }
    out = out + "  " + num + " " + title + " " + diff + "\n"
    out = out + "     " + dim_text(example.description) + "\n"
    out = out + "     " + ansi_gray() + "Goal: " + example.goal + ansi_reset() + "\n\n"
  }
  out = out + dim_text("Use /run <N> <goal> to try an example, or type your own goal.") + "\n"
  out
}

///|
pub fn get_tutorial() -> Array[String] {
  [
    "Welcome to AutoAgent! This tutorial will guide you through the basics.",
    "",
    "Step 1: What is AutoAgent?",
    "  AutoAgent is a lightweight Agent runtime that helps you build and use AI agents.",
    "  It takes a 'goal' (what you want to accomplish) and creates a plan to achieve it.",
    "",
    "Step 2: How does it work?",
    "  1. You provide a goal (e.g., 'build a chatbot')",
    "  2. AutoAgent creates a plan with steps",
    "  3. Each step uses a tool to generate guidance",
    "  4. You get a complete action plan",
    "",
    "Step 3: Try your first goal!",
    "  Type something like:",
    "    build a todo list app",
    "    create a blog with comments",
    "    design a user authentication system",
    "",
    "Step 4: Understanding the output",
    "  - Goal: What you asked for",
    "  - State: Whether it completed successfully",
    "  - Steps: The tools that were used",
    "  - Each step gives you actionable advice",
    "",
    "Step 5: Customize your experience",
    "  - /config    - See current settings",
    "  - /examples  - Browse example goals",
    "  - /run <N>   - Set max steps (try /run 5)",
    "",
    "Step 6: Advanced features",
    "  - Use --verbose for detailed output",
    "  - Use --max-steps to control plan length",
    "  - Create custom tools for your needs",
    "",
    "Ready to start? Type your first goal below!",
  ]
}

///|
pub fn format_tutorial() -> String {
  let steps = get_tutorial()
  let mut out = header("=== AutoAgent Tutorial ===") + "\n"
  for step in steps {
    if step == "" {
      out = out + "\n"
    } else if step.has_prefix("Step ") {
      out = out + bold_text(step) + "\n"
    } else if step.has_prefix("  ") {
      out = out + dim_text(step) + "\n"
    } else {
      out = out + step + "\n"
    }
  }
  out
}

///|
pub fn suggest_based_on_input(input : String) -> String {
  let suggestions : Array[String] = []

  if input.length() < 5 {
    suggestions.push("Your goal is very short. Try being more specific about what you want to build.")
  }

  if input.has_prefix("how to") || input.has_prefix("how do") {
    suggestions.push("Consider rephrasing as a goal: 'build a ...' or 'create a ...'")
  }

  if input.contains("fix") || input.contains("bug") || input.contains("error") {
    suggestions.push("For debugging tasks, try: 'debug and fix [issue description]'")
  }

  if input.contains("learn") || input.contains("understand") {
    suggestions.push("For learning tasks, try: 'create a tutorial about [topic]'")
  }

  if input.has_prefix("write") && input.contains("test") {
    suggestions.push("For testing tasks, try: 'write unit tests for [module name]'")
  }

  if suggestions.length() == 0 {
    ""
  } else {
    let mut out = header("💡 Suggestions") + "\n"
    for s in suggestions {
      out = out + "  " + info(s) + "\n"
    }
    out
  }
}

///|
pub fn format_beginner_help() -> String {
  let mut out = header("=== Beginner's Guide ===") + "\n"
  out = out + bold_text("What is a goal?") + "\n"
  out = out + "  A goal is what you want to accomplish. Be specific!\n\n"
  out = out + bold_text("Good goals:") + "\n"
  out = out + "  ✓ 'build a chatbot for customer support'\n"
  out = out + "  ✓ 'create a REST API for a todo app'\n"
  out = out + "  ✓ 'write unit tests for the auth module'\n\n"
  out = out + bold_text("Less effective goals:") + "\n"
  out = out + "  ✗ 'help' (too vague)\n"
  out = out + "  ✗ 'fix my code' (no specifics)\n"
  out = out + "  ✗ 'do something' (unclear intent)\n\n"
  out = out + bold_text("Tips for better results:") + "\n"
  out = out + "  1. Be specific about what you want\n"
  out = out + "  2. Include the technology or framework\n"
  out = out + "  3. Mention constraints or requirements\n"
  out = out + "  4. Use action verbs: build, create, design, write\n\n"
  out = out + bold_text("Try these commands:") + "\n"
  out = out + "  /tutorial   - Interactive walkthrough\n"
  out = out + "  /examples   - Browse example goals\n"
  out = out + "  /beginner   - Show this guide\n"
  out
}
