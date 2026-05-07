# Vibe Coding 治理：用 OMC 解决生成式开发的系统性问题

Vibe coding 的核心矛盾不是"AI 会不会写代码"，而是"如何把生成速度转化为可验证、可维护、可协作的交付能力"。OMC 框架已经覆盖了大部分治理需求，关键是用对。

## 问题到能力的映射

| 问题 | OMC 已有能力 | 覆盖度 | 补充动作 |
|------|-------------|--------|---------|
| 语义漂移（需求→实现偏差） | ralplan + deep-interview + ralph PRD | 完整 | 非 trivial 任务一律从 ralplan 开始 |
| 架构退化 | autopilot Phase 4 多视角验证 + ai-slop-cleaner | 大部分 | `.claude/rules/` 加架构约束 |
| 代码质量退化 | pre-tool-enforcer slop 检测 + karpathy-guidelines + simplify | 完整 | 复制规则模板到项目 |
| 审查信任破裂 | writer/reviewer 分离 + 验证分层 + --critic | 完整 | 高风险用 `--critic=architect` |
| 测试验证滞后 | ultraqa 循环 + autopilot Phase 3 | 完整 | 配置 `--tests --build --lint` |
| 安全漏洞 | security-reviewer + security rules + 自动升级 | 大部分 | 加供应链规则 |
| 依赖幻觉/供应链 | 无内置 | 缺口 | rules/ 加验证规则 |
| 权限过大 | permission 模式 + worktree 隔离 | 部分 | 高敏项目用 plan 模式 |
| 知识断层 | wiki + project-memory + remember 标签 | 大部分 | 主动用 wiki 记录决策 |
| 成本失控 | 三级模型路由 + session 统计 | 部分 | 聚合 session JSON |

## 核心工作流：从 Vibe 到 Production

```
需求进来（模糊的想法）
│
├─ 模糊度高 → /deep-interview "想法"
│              数学评分 < 20% 才放行
│
├─ 需要方案共识 → /ralplan "任务描述"
│                  Planner + Architect + Critic 循环
│
├─ 明确可执行 → /ralph --critic=architect "任务"
│                PRD 驱动 + 外部审查 + 并行生成
│                内含 ultrawork + ai-slop-cleaner + 回归验证
│
├─ 安全敏感 → /security-review
│
├─ QA 收尾 → /ultraqa --tests --build --lint
│
└─ 确认无误 → commit
```

关键原则：**不要跳过 ralplan 直接 vibe**。ralplan 就是 spec-first 的实操形态。

## 按风险等级选择执行模式

| 风险等级 | 特征 | 推荐模式 | 审查配置 |
|---------|------|---------|---------|
| 低 | UI 微调、文案、样式 | 直接改 / ultrawork | LIGHT 验证 |
| 中 | 新功能、重构、API 变更 | ralph | STANDARD 验证 |
| 高 | 认证、支付、数据处理、权限 | ralph --critic=architect | THOROUGH 验证（自动 opus） |
| 极高 | 生产部署、数据迁移、密钥轮换 | 人工主导 + AI 辅助 | 手动确认每步 |

OMC 的验证分层会自动识别安全相关文件（auth/credentials/tokens/.env）并升级到 THOROUGH。

## 防御语义漂移

### 问题

AI 生成的代码"看起来对"但偏离了真实意图。开发者不断修正而非一次性明确需求。

### OMC 解法

```
# 第一道门：模糊度门控
/deep-interview "我想做实时协作"
# OMC 追问直到 clarity score > 80%

# 第二道门：多视角共识
/ralplan "实现 WebSocket 实时协作"
# Planner 出方案 → Architect 审架构 → Critic 找漏洞 → 循环直到共识

# 第三道门：PRD 锁定验收标准
# ralph 自动生成 prd.json，每个 story 有可测试的 acceptance criteria
# 不满足 criteria 就不算完成
```

### 关键习惯

- 任何超过 30 分钟的任务，先 ralplan
- 验收标准必须是可自动验证的（能跑测试、能 curl、能截图对比）
- 不要接受 ralph 生成的"通用 criteria"，替换成项目特定的

## 防御架构退化

### 问题

AI 不天然维护长期架构一致性，容易把过时模式复制到更多位置。

### OMC 解法

1. **规则注入**：在 `.claude/rules/architecture-decisions.md` 写入架构约束，每次会话自动加载

```markdown
# Architecture Decisions

## 数据层
- ORM 统一用 Prisma，不引入其他 ORM
- 数据库迁移必须通过 prisma migrate，不手写 SQL DDL
- Repository pattern：所有数据访问通过 src/repositories/

## API 层
- REST 风格，路由定义在 src/routes/
- 认证统一用 middleware，不在 handler 里重复
- 错误处理统一用 AppError 类

## 前端
- 状态管理用 Zustand，不引入 Redux
- 组件目录结构：components/[Feature]/[Component].tsx
- 样式用 Tailwind，不写自定义 CSS 文件
```

2. **跨会话记忆**：用 wiki 记录架构决策的 why

```
/wiki "记录：选择 Prisma 而非 TypeORM 的原因是..."
```

3. **autopilot Phase 4**：architect agent 会检查功能完整性和架构一致性

## 防御安全漏洞与供应链风险

### 问题

包幻觉（19.7% 的生成包名是虚构的）、密钥泄露、提示注入、过度授权。

### OMC 已有防线

- `security-reviewer` agent 做漏洞分析
- `templates/rules/security.md` 有 pre-commit 安全检查清单
- 验证分层自动升级安全相关文件到 THOROUGH（opus 审查）
- team 模式用 worktree 隔离

### 补充：供应链规则

在 `.claude/rules/supply-chain.md` 加入：

```markdown
# Supply Chain Safety

添加新依赖时必须：
1. 先验证包存在：npm info <pkg> 或 pip show <pkg>
2. 检查周下载量 > 1000（npm）或月下载量 > 500（PyPI）
3. 检查最近发布时间 < 12 个月
4. 使用精确版本号，不用 ^ 或 ~
5. 添加后运行 license 检查

禁止：
- 不验证就安装 AI 建议的包
- 使用 alpha/beta/rc 版本进入生产依赖
- 从非官方 registry 安装
```

### 安全审查流程

```
# 开发完成后，发版前
/security-review

# 如果涉及认证/支付/权限
/ralph --critic=architect "确保 auth 模块无 OWASP Top 10 漏洞"
```

## 防御审查信任破裂

### 问题

AI 代码量大，reviewer 不能默认作者理解自己提交的代码。

### OMC 解法

OMC 的执行协议强制 writer/reviewer 分离：

```
# 写代码的 agent 和审查的 agent 是不同的
# ralph 内置：executor 写 → critic/architect 审 → slop-cleaner 清理 → 回归验证

# 手动触发独立审查
/simplify          # 审查当前改动的质量
/security-review   # 安全专项审查
```

### 关键配置

```
# 高风险改动用 opus 级别外部审查
/ralph --critic=architect "实现支付回调处理"

# 三 AI 交叉验证关键设计
/ccg "review 这个认证流程的安全性"
```

## 防御知识断层

### 问题

AI 代写比例上升，团队更快产出"可运行代码"，却更慢建立"可解释知识"。

### OMC 解法

```
# 1. 项目初始化时生成知识文档
/deepinit

# 2. 重要决策后记录到 wiki
/wiki "记录：为什么选择 event sourcing 而非 CRUD"
/wiki "记录：rate limiter 用 sliding window 算法的原因"

# 3. 用 remember 标签保存跨会话上下文
# 在对话中说：
# "记住：这个项目的部署流程是 GitHub Actions → ECR → ECS"
# OMC 的 project-memory hook 会自动持久化

# 4. 把经验转化为可复用 skill
/skillify
# 把本次会话的工作流固化为 skill，下次直接调用
```

## 防御成本失控

### 问题

返工、安全修复、误审与错误依赖会吞掉交付红利。

### OMC 已有机制

- **三级模型路由**：haiku（快速查询）→ sonnet（标准）→ opus（深度分析）
- 自动按任务复杂度选模型，不会所有事都用 opus
- session 统计写入 `.omc/sessions/*.json`

### 成本优化实践

```
# 低风险任务不需要 opus
# OMC 自动路由，但你可以显式控制：

# 简单查询 → 直接问（haiku 处理）
"这个函数的参数是什么？"

# 标准开发 → ralph（sonnet 为主）
/ralph "添加分页功能"

# 架构决策 → ralplan（opus 参与）
/ralplan "重新设计数据模型"

# 避免浪费的关键：
# - 先 ralplan 再 ralph，避免方向错误导致返工
# - 用 ultraqa 尽早发现问题，避免后期大规模修复
# - 用 ai-slop-cleaner 控制代码膨胀
```

## 项目配置模板

### 最小配置（立即生效）

```bash
# 复制 OMC 规则模板到项目
mkdir -p .claude/rules
cp /opt/homebrew/lib/node_modules/oh-my-claude-sisyphus/templates/rules/*.md .claude/rules/
```

### 推荐配置

```
项目根目录/
├── .claude/
│   ├── CLAUDE.md                          ← 项目级指令
│   └── rules/
│       ├── coding-style.md                ← OMC 模板
│       ├── testing.md                     ← OMC 模板
│       ├── security.md                    ← OMC 模板
│       ├── git-workflow.md                ← OMC 模板
│       ├── karpathy-guidelines.md         ← OMC 模板
│       ├── architecture-decisions.md      ← 项目特定
│       ├── supply-chain.md                ← 项目特定
│       └── compliance.md                  ← 项目特定（如需）
├── .omc/
│   ├── wiki/                              ← 跨会话知识库
│   └── sessions/                          ← 会话统计
└── specs/                                 ← silver-bullet-spec 产出
```

### 合规规则示例（如需）

`.claude/rules/compliance.md`：

```markdown
# Compliance

面向中国市场的产品：
- 不在前端暴露用户手机号完整明文
- 日志中个人信息必须脱敏
- 数据存储不出境（使用国内 region）
- 生成式 AI 功能需标识 AI 生成内容

面向所有市场：
- 用户数据删除请求必须在 30 天内完成
- 密码存储用 bcrypt/argon2，不用 MD5/SHA
- API 必须有 rate limiting
```

## 常见反模式与纠正

| 反模式 | 问题 | 正确做法 |
|--------|------|---------|
| 直接 `/autopilot` 做复杂功能 | 需求模糊导致返工 | 先 `/ralplan` 或 `/deep-interview` |
| 跳过 `/security-review` | 安全漏洞进入主干 | 发版前必跑 |
| 不用 `--critic` | 自审自批，质量不可靠 | 高风险用 `--critic=architect` |
| 不记录架构决策 | 下次会话重复犯错 | 用 `/wiki` 或 rules/ 固化 |
| 所有任务都用 opus | 成本爆炸 | 信任 OMC 的自动路由 |
| AI 建议的包直接装 | 依赖幻觉风险 | rules/ 加供应链验证规则 |
| 大段代码一次提交 | 审查不可能、回滚困难 | 小批量 + feature flag |
| 只看测试通过就算完 | 功能正确 ≠ 用户价值 | ultraqa + 手动验证关键路径 |

## 与 silver-bullet-spec 的配合

silver-bullet-spec 是"规范驱动工作流"，OMC 是"执行与验证引擎"。两者配合：

```
1. silver-bullet-spec 产出规范文档（specs/）
2. OMC 的 ralplan/deep-interview 确保规范完整
3. OMC 的 ralph 按规范执行
4. OMC 的 ultraqa + security-review 验证交付
5. OMC 的 wiki 记录过程知识
```

这条链路把"自由 vibe"约束成了"受控 production"。
