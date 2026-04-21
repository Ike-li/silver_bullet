请分析当前代码库，在项目根目录生成一个新的 `AGENTS.md`（或 `CLAUDE.md`）文件，用于指导 AI 编程助手（如 Claude Code, Cursor, Copilot, Codex, Windsurf, Gemini 等）进行工作。

重点发现能帮助 AI 助手在这个代码库中**立刻具备生产力**的核心知识。请考虑以下方面：
- 需要阅读多个文件才能理解的“宏观”架构——主要组件、服务边界、数据流，以及架构决策背后的“为什么”
- 关键的开发者工作流（构建、测试、调试），尤其是那些无法仅通过检查文件就能明显看出的命令
- 与常见实践不同的、项目专属的约定和模式
- 集成点、外部依赖，以及跨组件通信模式

请从现有的 AI 约定文件中提取灵感，执行**一次** glob 搜索：
`**/{.github/copilot-instructions.md,AGENT.md,AGENTS.md,CLAUDE.md,GEMINI.md,.cursorrules,.windsurfrules,.clinerules,.cursor/rules/**,.windsurf/rules/**,.clinerules/**,README.md}`

指导原则（详见 https://agents.md/）：
- 使用 Markdown 结构编写简明扼要、可操作的指令（约 20-50 行）
- 描述模式时，包含代码库中的具体示例
- 避免泛泛而谈（如“编写测试”、“处理错误”）——专注于**本项目**的具体方法
- 只记录**可发现的真实模式**，而不是空谈的“理想实践”
- 引用体现重要模式的关键文件/目录

请首先生成 `AGENTS.md`。生成完毕后，向用户总结其中包含的内容，以便用户了解文档的实质。
