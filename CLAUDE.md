# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

`silver_bullet` 是一个 AI 能力资产管理仓库，用于集中管理 agent、prompt、skill、MCP 等 AI 能力资源。核心目标是对外部能力进行引入、审计、适配、测试、启用和追踪更新，实现可控、可追溯、可替换、可安全使用。

这不是一个传统的软件工程项目——没有构建系统、没有应用代码。仓库内容主要是 Markdown 文档和 skill 定义。

## 仓库结构

- `skills/` — 自研 skill，每个 skill 一个子目录，入口为 `SKILL.md`
- `vendor/` — 引入的第三方能力仓库（minimax-ai、spec_driven_develop、superpowers），只读参考，不要修改
- `docs/` — 方法论文档（skill 编写指南、评估流程）
- `agent/`、`mcp/`、`prompt/` — 预留目录，当前为空

## Skill 体系

### 当前 skill

- `silver-bullet-spec` — 复杂任务总控 skill（分析→计划→执行→归档的完整工作流）
- `systematic-debugging-lite` — 执行阶段排障 skill（先根因后修复、先证据后结论）

### Skill 目录结构规范

```
skills/<skill-name>/
├── SKILL.md              # 必需：入口文件，含 YAML frontmatter
├── references/           # 可选：按需读取的参考文档
├── scripts/              # 可选：可重复执行的脚本
├── examples/             # 可选：参考示例
└── assets/               # 可选：不常驻上下文的资源
```

### SKILL.md frontmatter 格式

```yaml
---
name: skill-name          # 必须与目录名一致，小写 kebab-case
description: >-           # 触发契约：做什么 + 何时触发 + 典型用户表达 + 不该触发的场景
  ...
version: 0.1.0
---
```

### 关键设计原则

- `description` 是触发契约，不是简介——必须包含具体任务类型、典型用户表达、边界条件
- 遵循渐进披露：元数据（常驻）→ SKILL.md（触发时加载）→ references/scripts/等（按需读取）
- SKILL.md 只放必须经常读的内容，详细资料移入 references/
- 新增 skill 优先新增"专项执行能力"，不要膨胀总控 skill

## silver-bullet-spec 工作流

该 skill 定义了 8 个阶段的工作流：

0. 快速捕获意图
1. 深度项目分析（产出 `docs/analysis/`）
2. 意图细化与确认
3. 任务拆解（产出 `docs/plan/`）
4. 进度跟踪（产出 `docs/progress/MASTER.md`）
5. 任务专属执行技能（产出 `skills/<task-slug>/SKILL.md`）
6. 交接与汇总
7. 归档（移入 `docs/archives/<项目名>/`）

关键规则：若存在 `docs/progress/MASTER.md`，必须先读取再继续；不得跳过阶段；阶段边界须取得用户确认。

## vendor/ 使用约定

- `vendor/spec_driven_develop/` — silver-bullet-spec 的上游参考，只读
- `vendor/minimax-ai/` 和 `vendor/superpowers/` — 第三方能力仓库，只读参考
- 这些目录作为 git 子目录管理，不要直接修改其中内容

## 语言

仓库文档和 skill 内容以中文为主。
