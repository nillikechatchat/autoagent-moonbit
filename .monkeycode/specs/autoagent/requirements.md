# Requirements Document

## Introduction

AutoAgent is a lightweight MoonBit Agent runtime and starter kit. The system helps users create an Agent from scratch, understand the Agent loop, and apply safe operating practices while using an Agent.

## Glossary

- **AutoAgent**: The MoonBit runtime and starter kit for building and using lightweight agents.
- **Agent Core**: The component that coordinates planning, tool execution, memory, and final response generation.
- **Planner**: The component that converts a goal into executable steps.
- **Tool**: An allowlisted capability that the Agent Core can call.
- **Memory**: The component that stores messages and tool results during a run.
- **Provider**: The component that generates the final response from goal, memory, and tool results.

## Requirements

### Requirement 1

**User Story:** AS a developer, I want a small MoonBit Agent runtime, so that I can understand and customize the full Agent flow.

#### Acceptance Criteria

1. WHEN a developer reads the project structure, AutoAgent SHALL expose separate modules for Agent Core, Planner, Tool, Memory, Provider, and shared types.
2. WHEN a developer runs the default Agent, AutoAgent SHALL create a plan from a user goal.
3. WHEN a plan contains allowlisted steps, AutoAgent SHALL execute matching tools and record each result.

### Requirement 2

**User Story:** AS a new Agent user, I want guidance for creating an Agent from scratch, so that I can start with a practical and safe baseline.

#### Acceptance Criteria

1. WHEN the user gives a goal, AutoAgent SHALL generate scaffold guidance for a minimal Agent.
2. WHEN the user gives a goal, AutoAgent SHALL generate an operating checklist for safe usage.
3. WHEN the user gives a goal, AutoAgent SHALL generate coaching guidance for improving Agent usage.

### Requirement 3

**User Story:** AS an Agent builder, I want replaceable components, so that I can add real providers and tools later.

#### Acceptance Criteria

1. WHEN a developer adds a new tool, AutoAgent SHALL support registration through the tool list.
2. WHEN a developer customizes planning, AutoAgent SHALL support updating the Planner without changing the Agent Core interface.
3. WHEN a developer replaces the Provider, AutoAgent SHALL keep the Agent Core run flow stable.
