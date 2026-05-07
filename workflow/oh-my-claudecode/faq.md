# 成本控制与常见问题

## 成本控制

### 模型选择与价格

| 模型 | 价格（输入/输出 per 1M tokens） | 适用 |
|------|------|------|
| Haiku | $0.25 / $1.25 | 搜索、轻量查询 |
| Sonnet | $3 / $15 | 日常开发 |
| Opus | $15 / $75 | 架构设计、复杂推理 |

OMC 自动路由：explore → haiku，executor → sonnet，architect → opus。

### 降低费用的方法

1. **用 `/autopilot` 而不是手动多步** — autopilot 内部自动选便宜模型做简单任务
2. **限制 team 规模** — `/team 2:executor` 比 `/team 5:executor` 便宜
3. **指定场景** — `/ai-smoke --scenario auth-flow` 比跑全量便宜
4. **Headless 模式设预算** — `claude -p "..." --max-budget-usd 2.00`
5. **用 `--bare`** — 跳过 Skill/Plugin 加载，减少 context token

### 查看消耗

每次 Claude Code 会话结束会显示 token 消耗。OMC HUD 状态栏也实时显示。

## 常见问题

### Q: `/deepinit` 要跑多久？

取决于项目大小。小型项目（<100 文件）约 1 分钟，大型项目（>1000 文件）约 3-5 分钟。生成的 AGENTS.md 文件数量 = 项目目录深度 × 目录数。

### Q: AGENTS.md 应该提交到 git 吗？

建议提交。团队共享文档，所有人用 OMC 时都有项目上下文。如果不想提交，加到 `.gitignore`，但其他人需要各自跑 `/deepinit`。

### Q: Skill 不触发怎么办？

1. 检查 description 是否包含用户可能的表述（中英文都要）
2. 任务太简单时 Claude 可能不需要 Skill —— 只有复杂任务才触发
3. 用 `/skill search 关键词` 验证 Skill 是否被识别

### Q: /ralph 和 /autopilot 有什么区别？

| | /autopilot | /ralph |
|---|---|---|
| 流程 | 完整 5 阶段流水线 | 执行 → 验证 → 循环 |
| 适合 | 从零开始的新功能 | 必须修好/必须完成的任务 |
| 验证 | 最后一步验证 | 每次迭代都验证 |
| 规划 | 自动生成 PRD | 复用已有任务描述 |

### Q: 多个 Agent 会不会互相冲突？

Worktree 方式不会，每个 Agent 在独立分支。Team 模式通过共享任务列表协调，不会同时编辑同一文件。

### Q: 如何取消正在运行的 OMC 模式？

```
/cancel
```

### Q: omc doctor 报错怎么修？

```bash
omc doctor
```

常见问题：
- Node.js 版本太低 → `brew install node`
- Skills 目录不存在 → `omc setup` 重新初始化
- Hooks 配置损坏 → 删除 `~/.claude/settings.json` 中的 hooks 字段，重跑 `omc setup`

### Q: 与 Open Island 配合使用？

Open Island 是 macOS 刘海区的 AI Agent 监控面板。安装后：
1. 打开 Open Island → Settings → Claude Code → Install Hooks
2. 之后 OMC 的会话状态会自动出现在 Open Island 的刘海区面板中

### Q: CLIProxyAPI 配合使用？

如果通过 CLIProxyAPI 代理 Claude API：
1. 在 `~/.claude/settings.json` 设置 `ANTHROPIC_BASE_URL` 指向代理地址
2. OMC 正常使用，不受影响

## 诊断命令速查

```bash
# OMC 健康检查
omc doctor

# 查看 OMC 版本
omc --version

# 检查 Skill 是否加载
# 在 Claude Code 中：
/skill list

# 检查 Agent 是否就绪
ls ~/.claude/agents/

# 检查 HUD 是否工作
ls ~/.claude/hud/

# 重装 OMC
omc setup
```
