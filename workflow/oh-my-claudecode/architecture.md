# OMC 架构参考

## 核心原理

OMC 不是独立程序，是一套"指令注入系统"。通过 markdown 文件编排 Claude Code 的原生能力。

```
用户输入 "/autopilot 做个功能"
         │
         ▼
┌─────────────────────────────────────┐
│  Claude Code Skill 系统             │
│  匹配 SKILL.md → 注入指令到上下文    │
│  ↓                                   │
│  Agent 系统                          │
│  加载 Agent .md → 定义人格/能力/模型  │
│  ↓                                   │
│  Claude Code 原生工具                 │
│  Agent() / TaskCreate / SendMessage  │
│  ↓                                   │
│  子 Agent 在独立上下文中执行           │
└─────────────────────────────────────┘
```

## 四大组成部分

### 1. Agents（19 个）

定义在 `~/.claude/agents/*.md`，每个 Agent 有：

| 字段 | 作用 |
|------|------|
| name | Agent 标识 |
| model | 使用的模型（haiku/sonnet/opus） |
| level | 层级（1-4，越高越复杂） |
| disallowedTools | 禁止使用的工具 |
| Agent_Prompt | 完整的角色定义、约束、成功标准 |

关键设计：Agent 有明确的能力边界。architect 不能写文件，executor 不能做架构决策。

模型路由：
- **haiku** — 快速搜索、轻量查询（explore, writer）
- **sonnet** — 标准开发（executor, debugger, verifier）
- **opus** — 复杂推理（architect, analyst, planner, critic）

### 2. Skills（35+ 个）

定义在 `~/.claude/skills/*/SKILL.md`，每个 Skill 有：

| 字段 | 作用 |
|------|------|
| name | Skill 标识 |
| description | 触发条件（Claude 根据此判断是否使用） |
| argument-hint | 参数提示 |
| SKILL.md body | 完整的执行步骤 |

Skill 只在被触发时加载到上下文，不触发不消耗 token。

### 3. Hooks

配置在 `~/.claude/settings.json` 的 hooks 字段：

```json
{
  "hooks": {
    "UserPromptSubmit": [],
    "SessionStart": [],
    "PreToolUse": [],
    "PostToolUse": [],
    "Stop": []
  }
}
```

OMC 目前 hooks 为空数组，主要靠 statusLine 工作。

### 4. HUD 状态栏

```json
{
  "statusLine": {
    "type": "command",
    "command": "sh ~/.claude/hud/omc-hud-cache.sh ~/.claude/hud/omc-hud.mjs"
  }
}
```

每次渲染执行，显示 token 数、成本、Agent 数等。shell 缓存层避免每次启动 Node。

## Team 模式工作流

```
/team 3:executor "fix TypeScript errors"
    │
    ▼ TeamCreate → 创建团队
    ▼ 探索阶段 → explore/architect 拆解任务
    ▼ TaskCreate × N → 每个子任务
    ▼ Agent × N → 各自在独立上下文执行
    ▼ SendMessage → Agent 间通信协调
    ▼ team lead 汇总结果
```

## 文件布局

```
~/.claude/
├── agents/              # 19 个 Agent 定义
├── skills/              # 35+ 个 Skill 定义
│   ├── autopilot/SKILL.md
│   ├── team/SKILL.md
│   ├── ai-smoke/SKILL.md    # 自定义 Skill
│   │   └── scripts/run_smoke.py
│   └── ...
├── hud/                 # HUD 状态栏
│   ├── omc-hud.mjs
│   └── omc-hud-cache.sh
├── settings.json        # hooks + statusLine
├── .omc-config.json     # OMC 配置
└── .omc-version.json    # 版本信息

项目目录/
├── CLAUDE.md            # 项目说明（Claude Code 自动读取）
├── AGENTS.md            # /deepinit 生成的项目文档
├── apps/api/AGENTS.md   # 子目录文档
├── .omc/                # 运行时状态
│   ├── plans/           # 生成的执行计划
│   ├── specs/           # 需求规格
│   └── sessions/        # 会话记录
└── .ai-smoke/           # AI 冒烟测试（自定义）
    ├── scenarios.yaml
    ├── run_smoke.py
    └── results.json
```

## 自定义 Skill 开发

```
~/.claude/skills/my-skill/
├── SKILL.md             # 指令 + 触发条件（< 150 行）
└── scripts/             # 可选：可执行脚本（按需加载）
    └── my_script.py
```

SKILL.md 结构：
```markdown
---
name: my-skill
description: 做什么 + 什么时候触发（越"pushy"越好）
argument-hint: "[--flag value]"
---

# 标题

简短说明（WHY 比 WHAT 重要）

## Arguments
...

## Workflow
Step 1: ...
Step 2: ...
```

关键原则：
- description 是触发依据，要包含多种触发词
- SKILL.md 控制在 150 行以内，大代码放 scripts/
- 解释 WHY 而不是写死 MUST
- Skill 不是独立程序，是指令注入
