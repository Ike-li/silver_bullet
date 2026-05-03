# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

`silver_bullet` 是一个 AI 能力资产管理仓库，用于集中引入、审计、适配、测试和启用 AI agent skill。不是简单收集，而是对外部能力进行可控管理。

## 仓库结构

- `skills/` — 自研 skill（每个 skill 一个目录，含 `SKILL.md` + `references/`）
- `vendor/` — 第三方能力仓库（git submodule，只读，不可修改）
- `scripts/` — 工具脚本（skill 管理、安装、校验）
- `prompt/` — 独立 prompt 模板
- `mcp/` — MCP 相关（预留）
- `workflow/` — 工作流模板（constitution、fridge_magnet 等项目原则模板）
- `docs/` — 方法论文档（预留）

## 常用命令

```bash
# 校验所有 skill 结构与内容质量
./scripts/validate.sh
./scripts/validate.sh <skill-name>     # 校验单个 skill

# 安装 skill 到目标项目（支持 claude-code, cursor, codex, copilot）
./scripts/install.sh <skill> <tool> <target-dir> [--link]
./scripts/install.sh --update <skill> <tool> <target-dir>
./scripts/install.sh --uninstall <skill> <tool> <target-dir>
./scripts/install.sh --list            # 列出可用 skill

# 新增第三方 vendor 仓库
./scripts/add-vendor.sh <repo-url> [vendor-name]

# vendor submodule 管理
git submodule update --init            # 初始化
git submodule update --remote          # 更新全部 vendor

# 同步入口文件（CLAUDE.md → AGENTS.md/copilot-instructions/cursor rules）
./scripts/sync-entry.sh
```

## 创建新 Skill

创建自研 skill 使用 `vendor/anthropic-agent-skills` 中的 skill-creator：

1. 先更新 vendor：`git submodule update --remote vendor/anthropic-agent-skills`
2. 参考 `vendor/anthropic-agent-skills/skills/skill-creator/` 中的 skill 来创建
3. 规范见 `vendor/anthropic-agent-skills/spec/agent-skills-spec.md`，模板见 `vendor/anthropic-agent-skills/template/SKILL.md`

## 入口文件同步机制

CLAUDE.md 是单一源（Single Source of Truth）：
- `AGENTS.md` — symlink 到 CLAUDE.md
- `.github/copilot-instructions.md` — symlink 到 CLAUDE.md
- `.cursor/rules/silver-bullet.mdc` — 由 `sync-entry.sh` 生成（Cursor 需要特殊 frontmatter）

## 当前自研 Skill

| Skill | 用途 |
|:------|:-----|
| `silver-bullet-spec` | 复杂任务总控：分析 → 计划 → 执行 → 归档（规范驱动工作流） |
| `systematic-debugging-lite` | 执行阶段排障：先根因后修复、先证据后结论 |
| `frontend-e2e-bootstrap` | 从零设计前端 E2E 测试体系（Playwright） |

## 当前 Vendor（git submodule）

| 目录 | 来源 |
|:-----|:-----|
| `vendor/anthropic-agent-skills` | anthropics/skills |
| `vendor/superpowers` | obra/superpowers |
| `vendor/spec_driven_develop` | zhu1090093659/spec_driven_develop |
| `vendor/minimax-ai` | MiniMax-AI/skills |
| `vendor/agentsmd` | agentsmd/agents.md |
| `vendor/spec-kit` | github/spec-kit |
| `vendor/Trellis` | mindfold-ai/Trellis |

## 关键约定

- vendor 目录是只读的，不可修改第三方代码
- 新 skill 名称必须是小写 kebab-case 格式
- `install.sh` 支持 `--link` 模式（symlink 而非复制，方便开发时同步）
- `silver-bullet-spec` 的上游参考在 `vendor/spec_driven_develop/`，仅作对照
- `workflow/spec-kit/` 包含项目原则模板（constitution、fridge_magnet），用于在目标项目中实例化
