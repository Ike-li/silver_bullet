<!-- 自动生成，请勿直接编辑。源文件: CLAUDE.md —— 运行 ./scripts/sync-entry.sh 同步 -->

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

`silver_bullet` 是一个 AI 能力资产管理仓库，集中管理 skill、agent、prompt、MCP 等 AI 能力资源。核心目标：对外部能力进行引入、审计、适配、测试、启用和追踪更新。

这不是传统软件工程项目——没有构建系统、没有应用代码。仓库内容主要是 Markdown 文档和 skill 定义。

## 任务路由

根据用户意图选择对应的工作流：

| 用户意图 | 做什么 |
|:---------|:-------|
| 接入第三方 skill（给出 URL/路径） | 读取 `skills/skill-intake/SKILL.md` 并执行接入流程 |
| 从零新建 skill | 运行 `./scripts/new-skill.sh <name>`，然后按 `docs/skill-authoring-guidelines.md` 编写 |
| 执行复杂任务（重构/迁移/架构改造） | 读取 `skills/silver-bullet-spec/SKILL.md` 并执行 |
| 排查 bug / 定位根因 | 读取 `skills/systematic-debugging-lite/SKILL.md` 并执行 |
| 安装 skill 到目标项目 | 运行 `./scripts/install.sh <skill> <tool> <target>` |
| 校验 skill 质量 | 运行 `./scripts/validate.sh [skill-name]` |

## 仓库结构

```
skills/           # skill 目录，每个 skill 一个子目录，入口为 SKILL.md
vendor/           # 第三方能力仓库（git submodule，只读，不要修改）
docs/             # 方法论文档（编写指南、评估流程）
scripts/          # 工具脚本（install/validate/new-skill/intake-skill）
agent/ mcp/ prompt/  # 预留目录
```

## 当前 skill

| Skill | 定位 |
|:------|:-----|
| `silver-bullet-spec` | 复杂任务总控：分析 → 计划 → 执行 → 归档 |
| `systematic-debugging-lite` | 执行阶段排障：先根因后修复 |
| `skill-intake` | 第三方 skill 接入与适配 |

## Skill 格式规范

```
skills/<skill-name>/
├── SKILL.md              # 必需：入口文件，含 YAML frontmatter
├── references/           # 可选：按需读取的参考文档
├── scripts/              # 可选：可重复执行的脚本
├── examples/             # 可选：参考示例
└── assets/               # 可选：不常驻上下文的资源
```

SKILL.md frontmatter 必须包含 `name`（与目录名一致，小写 kebab-case）和 `description`（触发契约），推荐包含 `version`。

详细编写规范见 `docs/skill-authoring-guidelines.md`。

## 关键约定

- `vendor/` 目录只读，不要修改
- 新增 skill 优先新增"专项执行能力"，不要膨胀总控 skill
- `description` 是触发契约——必须包含具体任务类型、典型用户表达、不该触发的场景
- 仓库文档和 skill 内容以中文为主
- **入口文件同步**：CLAUDE.md 是单一源，`AGENTS.md`、`.cursor/rules/silver-bullet.mdc`、`.github/copilot-instructions.md` 由 `./scripts/sync-entry.sh` 自动生成。修改内容只改 CLAUDE.md，然后运行同步脚本
