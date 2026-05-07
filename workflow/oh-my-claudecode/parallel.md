# 并发开发

## 方式一：Git Worktree 并行（最推荐）

每个功能在独立 worktree 中开发，文件零冲突：

```bash
cd your-project

# 终端 1：开发认证功能
claude -w feature-auth
# → /autopilot "实现 OAuth2 认证"

# 终端 2：开发标签功能
claude -w feature-tags
# → /autopilot "实现标签管理 CRUD"

# 终端 3：修 Bug
claude -w bugfix-pagination
# → /ralph "修复分页 bug"
```

每个 worktree 是独立的 git 分支，互不影响。完成后分别合并。

## 方式二：Headless 批量执行

用脚本并行跑多个任务：

```bash
#!/bin/bash
# batch-tasks.sh

claude -p "为 src/auth 写单元测试" \
  --bare --allowedTools "Bash,Read,Edit" \
  --output-format json > result-auth.json &

claude -p "为 src/todos 写单元测试" \
  --bare --allowedTools "Bash,Read,Edit" \
  --output-format json > result-todos.json &

claude -p "为 src/tags 写单元测试" \
  --bare --allowedTools "Bash,Read,Edit" \
  --output-format json > result-tags.json &

wait
echo "All tasks complete"
```

关键参数：
- `--bare` — 跳过 hooks/skills/plugins，启动更快
- `--allowedTools` — 自动批准工具，无需人工确认
- `--output-format json` — 结构化输出，含 session_id 和成本
- `--max-turns N` — 限制最大轮数
- `--max-budget-usd 5.00` — 硬性预算限制

## 方式三：Agent Teams（OMC）

OMC 的 `/team` 命令，在 Claude Code 内部启动多个 Agent：

```
/team 3:executor "重构 auth 模块，添加 OAuth2 支持"
```

3 个 executor Agent 各自分到子任务，并行执行，通过共享任务列表协调。

支持 tmux 分屏模式（需安装 tmux）：
```
omc team 2:codex "review auth module"
omc team 2:gemini "redesign UI components"
```

## 方式四：Subagents（自动）

Claude Code 自动判断是否需要启动子 Agent。你不需要手动管理，OMC 的 Skills 内部会自动调用。

## 选择建议

| 场景 | 推荐方式 |
|------|---------|
| 不同功能并行开发 | Worktree (`-w`) |
| CI/批量测试 | Headless (`-p &`) |
| 单个复杂任务拆分 | `/team` |
| 日常单任务 | 直接用 `/autopilot` 或 `/ralph` |

## 注意事项

- Worktree 方式需要 `.claude/worktrees/` 加入 `.gitignore`
- Headless 模式需要设置 API Key 环境变量
- Agent Teams 需要在 settings.json 中启用 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`
- 并行任务各自消耗独立的 token 配额
