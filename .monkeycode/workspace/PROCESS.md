# Project Process Guide

## Process Overview

AutoAgent 的项目推进采用“需求规格、技术设计、实现、验证、文档同步、状态记录”的闭环流程。

## Stage Flow

1. 需求阶段：更新 `.monkeycode/specs/autoagent/requirements.md`，用可验收标准描述能力。
2. 设计阶段：更新 `.monkeycode/specs/autoagent/design.md`，说明架构、数据模型、错误处理和测试策略。
3. 实现阶段：修改 `src/autoagent/` 或 `src/main/`，保持模块职责清晰。
4. 验证阶段：运行 `moon check`、`moon build`、`moon test` 和 `moon run src/main`。
5. 文档阶段：同步 README、Wiki、过程资料和路线图。
6. 状态阶段：追加 `.monkeycode/workspace/STATE_LOG.md`，记录本阶段状态变化。

## Development Checklist

- 明确变更属于需求、架构、接口、测试、示例或文档。
- 修改源码时同步补充测试。
- 修改公开类型或函数时同步更新 `INTERFACES.md`。
- 修改 Agent loop 或模块职责时同步更新 `ARCHITECTURE.md`。
- 修改项目推进方式时同步更新本文件。
- 完成后运行验证命令并记录结果。

## Review Checklist

- 行为是否满足 requirements 中的验收标准。
- 设计是否仍符合小核心、确定性和可测试原则。
- 新工具是否保留 allowlist 边界。
- 测试是否覆盖成功路径、边界路径和失败路径。
- 文档是否与实际代码一致。

## Release Readiness

- `moon check` 通过。
- `moon build` 通过。
- `moon test` 通过。
- `moon run src/main` 输出符合 demo 预期。
- `ROADMAP.md`、`STATE_LOG.md` 和 README 状态一致。
