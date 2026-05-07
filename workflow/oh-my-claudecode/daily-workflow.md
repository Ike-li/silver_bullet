# 日常开发速查

## 命令选择决策树

```
你的任务是什么？
│
├── 知道要做什么 → /autopilot "任务描述"
│
├── 不确定怎么做 → /deep-interview "想法"
│                    → 明确后 /autopilot
│
├── 需要多 Agent 并行 → /team N:executor "任务"
│
├── 必须完成（不能半途而废）→ /ralph "任务"
│
├── 修 Bug → /ralph "修复 xxx bug 并确保测试通过"
│
├── 咨询其他 AI → /ask codex "review 这段代码"
│                  /ask gemini "优化这个 UI"
│
├── 三 AI 交叉验证 → /ccg "重新设计认证流程"
│
├── QA 验证 → /ultraqa "确保所有测试通过"
│
├── 代码审查 → /simplify（当前会话已改动的代码）
│
└── 全面 QA 循环 → /ultraqa --tests
```

## 核心命令详解

### /autopilot — 全自动开发

从想法到代码的完整流水线：需求分析 → 架构设计 → 拆任务 → 写代码 → QA → 验证。

```
/autopilot "给 Todo 添加标签筛选功能，支持多标签 AND/OR 查询"
```

适用：明确的功能需求，希望一步到位。

### /team — 多 Agent 协作

N 个 Agent 并行执行，各自独立上下文，通过共享任务列表协调。

```
/team 3:executor "重构 Prisma schema，把 Category 改为树形结构"
/team 2:codex "review auth 模块的架构"
/team 2:gemini "重新设计移动端 UI 组件"
```

参数说明：
- `N` — Agent 数量（1-20）
- `agent-type` — executor / debugger / designer / codex / gemini
- `ralph` 修饰符 — 加上后包裹在 Ralph 持久循环中

### /ralph — 持久循环

反复执行 + 验证，直到任务真正完成。适合"必须修好"的场景。

```
/ralph "修复分页查询 page>1 返回空数据的 bug 并确保测试通过"
```

### /deep-interview — 需求访谈

苏格拉底式追问，把模糊想法变成清晰需求。完成后自动保存规格文件，可跳过 autopilot 的需求分析阶段。

```
/deep-interview "我想做一个任务看板视图"
```

### /ask — 跨 AI 咨询

```
/ask codex "review apps/api/src/todo/ 的架构设计"
/ask gemini "提出 UI 优化建议"
```

### /ccg — 三 AI 综合

Claude + Codex + Gemini 各出方案，Claude 综合最优解。

```
/ccg "重新设计认证流程，支持 OAuth2 + 刷新 token"
```

### /ultraqa — QA 循环

```
/ultraqa "验证所有测试通过：pnpm test、pnpm lint、pnpm build"
/ultraqa --tests     # 只跑测试
/ultraqa --build     # 只跑构建
/ultraqa --lint      # 只跑 lint
```

### /simplify — 代码简化

审查当前会话中改动的代码，检查复用性、质量和效率。

```
/simplify
```

## 实用技巧

### 先审计再开发

接手老项目时，先跑审计了解现状：

```
/autopilot "审计项目质量：检查代码完整性、测试覆盖、部署配置、安全问题，输出清单"
```

### 用 /ralph 修完再验证

```
/ralph "修复审计发现的 3 个安全问题"
# 修完后
/ultraqa "验证所有测试通过"
```

### 取消当前模式

```
/cancel
```

### 持久化知识

把本次会话的经验保存为可复用 Skill：

```
/skillify
```

## 完整实战场景

### 场景一：接手老项目，从零到上线

```bash
cd ~/code/legacy-app
claude

# 第一步：理解项目
/deepinit

# 第二步：审计质量
/autopilot "审计项目上线就绪度，输出清单"

# 第三步：修复阻断问题
/ralph "修复所有 HIGH 级别问题"

# 第四步：验证修复
/ultraqa "pnpm test && pnpm lint && pnpm build"

# 第五步：开发新功能
/autopilot "添加用户个人资料页面"
```

### 场景二：多 Agent 并行开发三个功能

```bash
cd ~/code/project

# 终端 1
claude -w feature-auth
→ /autopilot "实现 OAuth2 Google 登录"

# 终端 2
claude -w feature-export
→ /autopilot "实现 Todo 导出为 CSV/PDF"

# 终端 3
claude -w bugfix-search
→ /ralph "修复搜索结果不返回精确匹配的 bug"
```

### 场景三：先访谈再开发

```bash
# 需求模糊时，先访谈
/deep-interview "我想做一个实时协作功能"
# OMC 追问：
#   - 多人同时编辑同一文档？
#   - 冲突怎么解决？
#   - 离线支持吗？
#   - 延迟容忍度？

# 访谈完成后，规格自动保存到 .omc/specs/
# 直接执行，跳过需求分析阶段
/autopilot "实现协作功能"
```

### 场景四：AI 冒烟测试

```bash
# 确保 dev server 已启动
pnpm dev

# 跑冒烟测试
/ai-smoke --model claude-sonnet-4-6 --url http://localhost:8081

# 只测试登录流程
/ai-smoke --scenario auth-flow --no-headless
```
