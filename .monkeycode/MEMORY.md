# 用户指令记忆

本文件记录了用户的指令、偏好和教导，用于在未来的交互中提供参考。

## 格式

### 用户指令条目
用户指令条目应遵循以下格式：

[用户指令摘要]
- Date: [YYYY-MM-DD]
- Context: [提及的场景或时间]
- Instructions:
  - [用户教导或指示的内容，逐行描述]

### 项目知识条目
Agent 在任务执行过程中发现的条目应遵循以下格式：

[项目知识摘要]
- Date: [YYYY-MM-DD]
- Context: Agent 在执行 [具体任务描述] 时发现
- Category: [运维部署|构建方法|测试方法|排错调试|工作流协作|环境配置]
- Instructions:
  - [具体的知识点，逐行描述]

## 去重策略

- 添加新条目前，检查是否存在相似或相同的指令
- 若发现重复，跳过新条目或与已有条目合并
- 合并时，更新上下文或日期信息
- 这有助于避免冗余条目，保持记忆文件整洁

## 条目

[MoonBit CLI 已安装到当前环境]
- Date: 2026-05-27
- Context: Agent 在执行 AutoAgent MoonBit 项目 review、依赖安装与验证时发现
- Category: 环境配置
- Instructions:
  - MoonBit toolchain 已通过 `curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash` 安装到 `~/.moon`。
  - 当前工具链版本为 `moonc v0.9.3+b53c2807d`、`moon 0.1.20260522`、`moonrun 0.1.20260522`。
  - 当前 shell 执行 MoonBit 命令时使用 `PATH="$HOME/.moon/bin:$PATH" moon ...`。
  - AutoAgent 项目验证命令为 `moon check`、`moon build`、`moon test` 和 `moon run src/main`。
