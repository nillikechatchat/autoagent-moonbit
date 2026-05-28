# Project Work Directory

`.monkeycode/workspace/` 是 AutoAgent 的过程资料工作目录。它承载项目推进中的规约、流程指引、测试资料、示例、参考材料和阶段状态记录。

## Purpose

项目过程资料需要同时回答两个问题：

- 当前团队按照什么规约和流程推进项目。
- 项目从时间维度经历了哪些阶段、状态和决策变化。

## Directory Map

```txt
.monkeycode/workspace/
├── README.md
├── CONVENTIONS.md
├── PROCESS.md
├── TESTING.md
├── EXAMPLES.md
├── REFERENCES.md
└── STATE_LOG.md
```

## Document Roles

- `CONVENTIONS.md`：项目规约，包括代码、文档、接口、工具安全和变更记录要求。
- `PROCESS.md`：流程指引，包括需求、设计、实现、测试、文档和发布节奏。
- `TESTING.md`：测试资料，包括验证矩阵、命令、覆盖范围和后续测试缺口。
- `EXAMPLES.md`：示例资料，包括 demo 输出、扩展工具示例和 trace 示例。
- `REFERENCES.md`：参考资料，包括相关框架、语言工具链和内部文档入口。
- `STATE_LOG.md`：阶段状态记录，按时间记录项目状态、完成项、验证结果和下一步。

## Update Rule

每次出现需求、设计、实现、测试、文档或阶段状态变化时，同步更新对应过程资料。`STATE_LOG.md` 记录时间维度变化，其他文件记录当前有效规则。
