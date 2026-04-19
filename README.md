# silver_bullet

`silver_bullet` 是一个用于集中管理 AI 能力资产的私有仓库。

目标不是简单收集别人写的 agent / prompt / skill / mcp，而是对外部能力进行：

- 引入
- 审计
- 适配
- 测试
- 启用
- 追踪更新

从而实现可控、可追溯、可替换、可安全使用。

---

## 仓库结构

```
skills/                  # 自研 skill
vendor/                  # 第三方能力仓库（git submodule，只读）
docs/                    # 方法论文档
agent/  mcp/  prompt/    # 预留目录
scripts/                 # 工具脚本
```

## 当前 Skill

| Skill | 用途 |
|:------|:-----|
| `silver-bullet-spec` | 复杂任务总控：分析 → 计划 → 执行 → 归档 |
| `systematic-debugging-lite` | 执行阶段排障：先根因后修复、先证据后结论 |
| `skill-intake` | 第三方 skill 接入与适配 |

## 安装 Skill 到项目

```bash
# 查看可用 skill
./scripts/install.sh --list

# Claude Code（推荐 --link 保持同步）
./scripts/install.sh silver-bullet-spec claude-code ~/code/my-app --link

# Cursor
./scripts/install.sh silver-bullet-spec cursor ~/code/my-app

# Codex
./scripts/install.sh silver-bullet-spec codex ~/code/my-app

# Copilot（VSCode / JetBrains）
./scripts/install.sh silver-bullet-spec copilot ~/code/my-app

# 更新已安装的 skill
./scripts/install.sh --update silver-bullet-spec cursor ~/code/my-app

# 卸载
./scripts/install.sh --uninstall silver-bullet-spec claude-code ~/code/my-app
```

各工具的安装产物：

| 工具 | 产物位置 |
|:-----|:---------|
| Claude Code | `.claude/skills/<name>.md`（复制或 symlink） |
| Cursor | `.cursor/rules/<name>.mdc` |
| Codex | `AGENTS.md` |
| Copilot | `.github/copilot-instructions.md` |

## 接入第三方 Skill

```bash
# 从第三方来源提取并生成适配版脚手架
./scripts/intake-skill.sh <源skill目录> <新skill名>

# 示例：从 vendor/superpowers 接入
./scripts/intake-skill.sh vendor/superpowers/skills/systematic-debugging my-debugging
```

接入后按 `INTAKE.md` 审计清单逐项完成适配。

## 开发工具

```bash
# 创建新 skill 脚手架
./scripts/new-skill.sh <skill-name>

# 校验 skill 质量
./scripts/validate.sh              # 校验全部
./scripts/validate.sh <skill-name> # 校验指定
```

## Vendor 管理

第三方能力仓库通过 git submodule 管理：

```bash
# 新增 vendor 仓库
./scripts/add-vendor.sh <repo-url> [自定义目录名]

# 克隆时初始化
git clone --recurse-submodules <repo-url>

# 已克隆的仓库初始化
git submodule update --init

# 更新全部 vendor
git submodule update --remote
```

## 文档

- [Skill 编写指南](docs/skill-authoring-guidelines.md)
- [Skill 评估与迭代](docs/skill-evaluation-loop.md)
