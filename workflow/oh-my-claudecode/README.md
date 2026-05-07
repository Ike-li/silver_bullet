# OMC 老项目接入指南

oh-my-claudecode (OMC) 在已有项目上的使用全流程。

## 文档索引

| 文档 | 内容 | 适合谁 |
|------|------|--------|
| [安装配置](./setup.md) | OMC 安装、初始化、环境检查 | 首次安装 |
| [首次接入](./onboarding.md) | 老项目接入流程 + 完整实战示例 | 接手新项目时 |
| [日常开发](./daily-workflow.md) | 命令决策树 + 4 个完整场景示例 | 每天使用 |
| [代码审计](./audit.md) | 上线审计、安全审计、性能分析 | 发版前 |
| [测试策略](./testing.md) | 测试增强 + AI 视觉冒烟测试 | QA 阶段 |
| [并发开发](./parallel.md) | Worktree、Headless、Teams 并行 | 多功能并行 |
| [自定义 Skill](./custom-skill.md) | 开发自己的 Skill + 完整示例 | 想扩展 OMC |
| [成本控制与 FAQ](./faq.md) | 费用优化 + 常见问题解答 | 遇到问题时 |
| [Vibe Coding 治理](./vibe-coding-governance.md) | 用 OMC 解决生成式开发的系统性问题 | 质量/安全/治理 |
| [架构参考](./architecture.md) | 框架原理、文件布局、工作机制 | 深入理解 |

## 快速开始

```bash
# 1. 安装（只需一次）
npm i -g oh-my-claude-sisyphus@latest
omc setup

# 2. 进入项目
cd your-project
claude

# 3. 让 OMC 理解项目（首次）
/deepinit

# 4. 开始开发
/autopilot "给用户添加个人资料页面"

# 或者先审计再开发
/autopilot "审计项目是否可部署上线"
/ralph "修复发现的问题"
/ultraqa "验证测试全部通过"
```

## 一句话速查

| 想做什么 | 用什么命令 |
|---------|-----------|
| 全自动做功能 | `/autopilot "描述"` |
| 必须修好 | `/ralph "描述"` |
| 多人并行 | `/team 3:executor "描述"` |
| 需求不明确 | `/deep-interview "想法"` |
| 问其他 AI | `/ask codex "问题"` |
| 跑测试验证 | `/ultraqa "pnpm test"` |
| AI 看页面测试 | `/ai-smoke --url http://localhost:3000` |
| 取消当前操作 | `/cancel` |
