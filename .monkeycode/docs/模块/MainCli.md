# Module: Main CLI

路径：`src/main/`

Main CLI 是 AutoAgent 的演示入口。当前入口使用固定目标运行默认 Agent，并打印最终输出。

## Files

- `main.mbt`：demo 入口。
- `moon.pkg`：声明 main package，并导入核心库。

## Current Behavior

`main.mbt` 执行以下逻辑：

1. 调用 `@autoagent.default_agent()` 创建默认 Agent。
2. 使用固定 goal 字符串。
3. 调用 `agent.run(goal)`。
4. 使用 `println` 输出结果。

## Run Command

```bash
# Run demo CLI
PATH="$HOME/.moon/bin:$PATH" moon run src/main
```

## Evolution Direction

- 支持从命令行参数读取 goal。
- 支持交互式输入。
- 支持选择输出格式。
- 支持导出 run trace。
- 支持生成 Agent 项目脚手架文件。
