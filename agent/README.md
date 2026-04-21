# Agent 管理 (AGENTS.md / CLAUDE.md)

本目录用于管理和初始化**项目级的 AI 助手入口配置**（即 `AGENTS.md`、`CLAUDE.md` 等文件）。

## 核心理念

参考 `vendor/agentsmd/` 仓库，我们认为每个代码项目都应该有一个 `AGENTS.md`，就像人类开发者有 `README.md` 一样。它用于：
- **消除猜测**：指明用哪个包管理器，哪条测试命令。
- **防止破坏性操作**：例如在交互会话中禁止运行生产构建（这可能破坏开发环境的热更新）。
- **统一代码风格**：如必须使用 TypeScript，CSS 必须共置等。
- **路由意图**：指导大模型在特定任务下调用仓库中的其他资源（如 `skills/` 下的能力）。

## 如何初始化一个 AGENTS.md？

可以使用本目录下的 `agent-prompt-template.md`（此 prompt 灵感来自于 GitHub Copilot 生成 `AGENTS.md` 的官方最佳实践指令），让大模型分析当前项目，并自动生成一份高质量的 `AGENTS.md`。

```bash
# 例子：在任何项目中
cat /path/to/silver_bullet/agent/agent-prompt-template.md | pbcopy
# 然后在 Claude Code 中粘贴给大模型执行
```

## 目录结构

- `README.md`：说明文档。
- `agent-prompt-template.md`：用于指导大模型生成 `AGENTS.md` 的规范模板。
