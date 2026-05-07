# OMC 安装配置

## 前置条件

- Node.js 18+
- Claude Code CLI 已安装
- tmux（可选，`omc team` 和 `omc wait` 需要）

## 安装

```bash
# 方式一：npm 全局安装（推荐）
npm i -g oh-my-claude-sisyphus@latest

# 方式二：Claude Code 插件市场
/plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode
/plugin install oh-my-claudecode
```

## 初始化

```bash
# 在任意目录运行
omc setup
```

安装完成后输出：
- 19 个 Agent 定义 → `~/.claude/agents/`
- 35 个 Skills → `~/.claude/skills/`
- HUD 状态栏 → `~/.claude/hud/`
- Hooks 配置 → `~/.claude/settings.json`

## 验证

```bash
omc --version           # 应输出版本号
omc doctor              # 诊断安装问题
```

在 Claude Code 中输入 `/skill list` 查看所有可用 Skills。

## 更新

```bash
# npm 方式
npm i -g oh-my-claude-sisyphus@latest

# 插件方式
/plugin marketplace update omc
/setup
```

## 可选：启用 Agent Teams

在 `~/.claude/settings.json` 中添加：

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

## 可选：安装 tmux

```bash
brew install tmux
```

用于 `omc team`（tmux 分屏多 Agent）和 `omc wait`（限速等待守护进程）。
