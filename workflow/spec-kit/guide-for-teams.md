# Spec-Kit 团队使用指南

面向中大型团队的 spec-kit 实战指南。假设你已经通过 `specify init` 初始化了项目。

## 一句话理解 Spec-Kit

**先写规范，再写代码。** 用 6 个命令把"从需求到代码"的过程结构化：

```
constitution → specify → clarify → plan → tasks → implement
   项目原则     需求规范    消歧     技术方案    任务拆解    实施
```

每一步都会生成 Markdown 文档，存在 `.specify/` 和 `specs/` 目录下，跟代码一起版本管理。

## 核心命令速查

| 命令 | 做什么 | 输入 | 产出 |
|:-----|:-------|:-----|:-----|
| `/speckit.constitution` | 定义项目不可违反的原则 | 团队的工程原则 | `.specify/memory/constitution.md` |
| `/speckit.specify` | 把需求描述转成结构化规范 | 一句话需求描述 | `specs/<分支名>/spec.md` |
| `/speckit.clarify` | 对规范做消歧问答（最多 5 个问题） | 已有 spec.md | spec.md 更新 + 消歧记录 |
| `/speckit.plan` | 生成技术方案 + 数据模型 + 接口契约 | spec.md | plan.md, data-model.md, contracts/, research.md |
| `/speckit.tasks` | 按用户故事拆解可执行任务 | plan.md + spec.md | tasks.md |
| `/speckit.implement` | 按 tasks.md 逐阶段实施 | tasks.md | 代码 + 测试 |

## 目录结构

初始化后项目会多出这些：

```
.specify/
├── memory/
│   └── constitution.md         # 项目宪法（原则）
├── templates/                  # 所有模板（一般不改）
│   ├── constitution-template.md
│   ├── spec-template.md
│   ├── plan-template.md
│   ├── tasks-template.md
│   └── commands/               # 命令定义
└── scripts/                    # 辅助脚本

specs/                          # 每个功能一个目录
└── 001-user-auth/              # 分支名 = 目录名
    ├── spec.md                 # 需求规范
    ├── plan.md                 # 技术方案
    ├── data-model.md           # 数据模型
    ├── research.md             # 技术调研
    ├── contracts/              # 接口契约
    ├── quickstart.md           # 关键验证场景
    └── tasks.md                # 任务清单
```

## 实际工作流程

### 第零步：建立项目宪法（只做一次）

宪法定义了整个项目的工程底线。所有后续命令都会检查是否违反宪法。

```
/speckit.constitution 我们的项目是一个电商后端，技术栈 Go + PostgreSQL + Redis。
核心原则：1）核心数据写入必须 TDD 2）不让用户看到系统错误 3）敏感数据不进日志
```

产出 `.specify/memory/constitution.md`，团队 review 后合并到主分支。

**关键**：宪法要少、硬、能拦 PR。3-5 条足够，多了就稀释。

### 第一步：写需求规范

接到需求后，不要直接写代码，先用一句话描述要做什么：

```
/speckit.specify 用户注册和登录系统，支持邮箱密码注册、手机验证码登录、JWT token 鉴权
```

AI 会自动：
1. 创建功能分支 `001-user-auth`
2. 生成 `specs/001-user-auth/spec.md`
3. 按模板填充用户故事、验收条件、功能需求

产出的 spec.md 会包含 `[NEEDS CLARIFICATION]` 标记，标识出需求中不明确的地方。

### 第二步：消歧（可选但推荐）

```
/speckit.clarify
```

AI 会根据 spec.md 中的模糊点，**逐个**问你最多 5 个问题。每个问题要么选择题，要么 5 个字以内回答。回答后自动更新 spec.md。

问题示例：
- "密码强度策略？A) 至少 8 位 + 大小写 B) 至少 6 位 C) 无限制"
- "JWT 过期时间？建议：24 小时。接受或提供你的值。"

**可以跳过**：如果需求已经足够清晰，或只是做原型探索，可以直接进入 plan。

### 第三步：生成技术方案

```
/speckit.plan 使用 Go + Gin 框架，PostgreSQL 存储用户数据，Redis 存验证码
```

AI 会：
1. 检查方案是否违反 constitution（宪法检查）
2. 生成 plan.md（技术方案总览）
3. 生成 data-model.md（User、Session 等实体定义）
4. 生成 contracts/（API 接口契约）
5. 生成 research.md（技术选型依据）
6. 生成 quickstart.md（关键验证场景）

如果方案违反宪法，会记录在 plan.md 的 **Complexity Tracking** 表中，必须给出理由。

### 第四步：拆解任务

```
/speckit.tasks
```

AI 读取 plan.md + spec.md + data-model.md + contracts/，自动生成按用户故事组织的任务清单：

```markdown
## Phase 1: Setup
- [ ] T001 初始化 Go 项目，配置 Gin + GORM 依赖
- [ ] T002 [P] 配置 PostgreSQL 连接和 migration 框架
- [ ] T003 [P] 配置 Redis 连接

## Phase 2: Foundational（阻塞所有用户故事）
- [ ] T004 实现 JWT 生成和验证中间件 src/middleware/auth.go
- [ ] T005 [P] 实现统一错误处理 src/middleware/error.go

## Phase 3: 用户注册（P1 - MVP）
- [ ] T006 [US1] 创建 User model src/models/user.go
- [ ] T007 [US1] 实现注册 service src/services/auth.go
- [ ] T008 [US1] 实现 POST /api/v1/register 接口
- [ ] T009 [US1] 添加邮箱格式和密码强度校验

## Phase 4: 验证码登录（P2）
- [ ] T010 [US2] 实现验证码生成和 Redis 存储 src/services/sms.go
- [ ] T011 [US2] 实现 POST /api/v1/sms/send 接口
- [ ] T012 [US2] 实现 POST /api/v1/login/sms 接口
```

标记含义：
- `[P]` — 可并行执行（不依赖其他未完成任务）
- `[US1]` — 属于用户故事 1（方便按故事独立交付）
- Phase 2 必须全部完成后，才能开始 Phase 3+

### 第五步：实施

```
/speckit.implement
```

按 tasks.md 逐阶段写代码。每完成一个 task 勾选 checkbox。

## 三个完整场景

### 场景 1：电商——添加优惠券系统

```bash
# 1. 写规范
/speckit.specify 优惠券系统：后台创建优惠券（满减/折扣/固定金额），用户领取、下单时使用，支持限量和有效期

# 2. 消歧——AI 可能会问：
#    - 每人限领几张？
#    - 优惠券能否叠加？
#    - 过期优惠券是否自动回收？
/speckit.clarify

# 3. 技术方案
/speckit.plan 使用现有的 Spring Boot + MySQL 技术栈，优惠券扣减走 Redis + Lua 保证原子性

# 4. 拆任务
/speckit.tasks

# 5. 实施
/speckit.implement
```

spec.md 中会出现这样的用户故事：

```markdown
### User Story 1 - 后台创建优惠券 (Priority: P1)
运营人员在后台创建一张满 200 减 30 的优惠券，限量 1000 张，有效期 7 天。

**Acceptance Scenarios**:
1. Given 运营登录后台, When 填写优惠券参数并提交, Then 系统创建优惠券并返回券码
2. Given 优惠券已创建, When 运营查看列表, Then 能看到状态为"未开始/进行中/已结束"
```

plan.md 中会做宪法检查：

```markdown
## Constitution Check
- [x] 核心数据写入必须 TDD — 优惠券扣减涉及金额，MUST 先写测试
- [x] 不让用户看到系统错误 — 库存不足返回"优惠券已领完"而非 500
- [x] 敏感数据不进日志 — 用户 ID 脱敏处理
```

### 场景 2：SaaS——多租户权限系统

```bash
# 1. 写规范
/speckit.specify 多租户 RBAC 权限系统：租户管理员可以创建角色、分配权限，普通用户继承角色权限，支持资源级细粒度控制

# 2. 这个需求歧义多，clarify 很重要
/speckit.clarify
# AI 可能问：
# - 权限继承是否支持跨租户？→ 不支持
# - 角色层级（admin > editor > viewer）还是平级？→ 层级
# - 资源级权限粒度：行级还是字段级？→ 行级

# 3. 技术方案
/speckit.plan Node.js + TypeScript + Prisma，用 CASL 做权限引擎

# 4-5. 拆任务 + 实施
/speckit.tasks
/speckit.implement
```

tasks.md 中的 Phase 2（Foundational）会比较重的：

```markdown
## Phase 2: Foundational
- [ ] T004 设计 Tenant / Role / Permission / RolePermission 四张表 migration
- [ ] T005 实现租户上下文中间件（从 JWT 提取 tenant_id）
- [ ] T006 实现 CASL ability factory src/auth/ability.factory.ts
- [ ] T007 [P] 实现权限守卫装饰器 src/auth/permission.guard.ts
```

### 场景 3：前端——Dashboard 重构

```bash
# 1. 写规范
/speckit.specify 将现有 Dashboard 页面从 jQuery 重构为 React，保持功能不变，优化首屏加载速度，支持暗色模式

# 2. clarify
/speckit.clarify
# AI 可能问：
# - 是否需要 SSR？→ 不需要，SPA 即可
# - 图表库保留 ECharts 还是换？→ 保留
# - 暗色模式跟随系统还是手动切换？→ 手动切换 + 记住偏好

# 3. 方案
/speckit.plan React 18 + Vite + TailwindCSS，保留现有 REST API 不变

# 4-5. 拆任务 + 实施
/speckit.tasks
/speckit.implement
```

因为是重构，tasks.md 的组织方式会不同——按页面区域而非全新功能：

```markdown
## Phase 3: 主布局框架（P1 - MVP）
- [ ] T006 [US1] 实现 Layout 组件（侧边栏 + 顶栏 + 主内容区）
- [ ] T007 [US1] 实现暗色模式 ThemeProvider + toggle
- [ ] T008 [US1] 实现路由配置 src/router/index.tsx

## Phase 4: 数据面板（P2）
- [ ] T009 [US2] 迁移 KPI 卡片组件
- [ ] T010 [US2] 迁移 ECharts 图表（保留配置，替换 DOM 操作为 React ref）
- [ ] T011 [US2] 实现数据获取层 src/hooks/useDashboardData.ts
```

## 团队协作要点

### 分支策略

spec-kit 会为每个功能自动创建分支（如 `001-user-auth`）。推荐：

- `specs/` 目录下的文档和代码在同一个分支上
- spec.md 和 plan.md 先 review 合并，再开始写代码
- 这样其他人可以基于同一份规范并行开发

### 多人并行

tasks.md 中标记了 `[P]` 的任务和不同 User Story（`[US1]` vs `[US2]`）可以分配给不同人：

```
开发 A → Phase 3 (US1): 用户注册
开发 B → Phase 4 (US2): 验证码登录
开发 C → Phase 5 (US3): 密码重置
```

前提：Phase 2 (Foundational) 必须先完成。

### Review 节点

| 什么时候 Review | 谁 Review | 关注什么 |
|:----------------|:----------|:---------|
| constitution 定稿后 | 全团队 | 原则是否少、硬、可拦 PR |
| spec.md 完成后 | PM + 技术负责人 | 需求是否完整、验收条件是否可测 |
| plan.md 完成后 | 架构师 + 高级开发 | 方案是否违反 constitution、是否过度设计 |
| tasks.md 完成后 | 执行者本人 | 任务拆分是否合理、依赖是否正确 |

### 什么时候可以跳步

| 场景 | 可以跳过 |
|:-----|:---------|
| 原型 / spike | clarify + tasks，直接从 specify → plan → 写代码 |
| hotfix | 全部跳过，事后补 spec |
| 明确的小需求（< 半天工作量） | tasks，直接从 plan → 写代码 |
| constitution 已经有了 | constitution 只做一次，后续只在季度复审时改 |

## 用好这个框架的关键认知

### 它是流程纪律，不是仪式

框架的价值不在于 6 个命令，而在于强制你在写代码前把想法结构化。该跳步就跳步——hotfix 不需要走 constitution 检查，原型不需要 tasks.md。但核心需求如果跳了 clarify 和 plan，返工成本会很高。

判断标准很简单：**如果这个需求做错了需要返工超过 2 天，就走完整流程；否则酌情精简。**

### 宪法是最值钱的部分

大多数团队的问题不是"不知道该做什么"，而是"每个人对底线的理解不一样"。一份 3-5 条原则的 constitution，比后面所有命令加起来都重要。

写好它，然后让 plan 阶段的 Constitution Check 真的拦住违反的方案——不是走过场打勾，而是真的有人看 Complexity Tracking 表并质疑。

### spec 和 plan 必须分开 review

- **spec review**：PM + 技术负责人确认"做的是不是对的事"——用户故事对不对、验收条件可不可测、优先级排序对不对
- **plan review**：架构师 + 高级开发确认"方案是不是合理的"——技术选型、数据模型、接口设计、是否违反宪法

把两个 review 混在一起，两个都会做得很粗。分开 review 的另一个好处是：spec 通过后多人可以并行出 plan 方案做对比。

### 不要追求模板 100% 填满

模板是约束 AI 输出质量的工具，不是表格填空。`[NEEDS CLARIFICATION]` 标记比编造一个答案有价值得多。

强行填满会导致两个问题：
1. AI 编造看似合理但未经验证的假设，下游所有产出都建立在错误前提上
2. 团队以为需求已经明确，跳过了本该进行的讨论

### clarify 是性价比最高的一步

5 个问题花 5 分钟，但这 5 分钟消除的歧义可能省掉几天返工。特别是涉及：
- 业务规则边界（能不能叠加、要不要限频、过期怎么处理）
- 用户角色区分（admin vs 普通用户的权限边界）
- 数据生命周期（保留多久、怎么删除、怎么迁移）

如果 AI 说"No critical ambiguities detected"，大概率是你的 spec 写得足够好，可以放心进入 plan。

### tasks 的粒度决定了并行效率

一个 task 太粗（"实现用户模块"），没法分配给多人；太细（"给 User struct 加 Email 字段"），管理成本高于执行成本。

**经验法则**：一个 task = 一个人半天到一天能完成的工作，产出一个可验证的结果。

tasks.md 中的 `[P]` 标记和 `[US1/US2]` 分组是给团队并行用的——如果你是一个人开发，按顺序做就行，不需要刻意并行。

## 常见误区

1. **把 constitution 写成百科全书** — 条款越多越没人看。3-5 条不可妥协的 + 一张"明确不做"的表就够了
2. **spec.md 写太细变成技术文档** — spec 只说 WHAT 和 WHY，不说 HOW。技术细节在 plan.md 里
3. **跳过 clarify 直接 plan** — 歧义不会消失，只会变成返工。5 个问题花 5 分钟，能省几天
4. **tasks 太粗或太细** — 一个 task 应该是"一个人半天到一天能完成的"粒度
5. **不做宪法检查就合并 plan** — plan.md 里的 Constitution Check 不是装饰，是门禁

## Brownfield：改已有功能时的 spec 版本演进

spec-kit 的 specify 命令每次会创建新的 `specs/<分支名>/` 目录，但没有显式机制把新 spec 和旧 spec 关联起来。

半年后你的 specs/ 目录可能长这样：

```
specs/
├── 001-user-auth/
├── 002-coupon-system/
├── 003-coupon-stackable/      # 修改了 002 的叠加规则
├── 007-user-auth-sso/         # 给 001 加了 SSO
└── 012-coupon-expiry-refund/  # 又改了 002 的过期逻辑
```

如果不建立关联，没人知道"优惠券系统当前的完整规范"散落在 002、003、012 三个目录里。

**团队约定建议**：

1. 在新 spec 的 Assumptions 里引用旧 spec 路径：
   ```markdown
   ## Assumptions
   - 基于 specs/002-coupon-system/spec.md 的现有优惠券系统
   - 修改范围：叠加规则（原 spec FR-003 不允许叠加，本次改为允许同类叠加）
   ```

2. 功能复杂到一定程度后，考虑维护一份 `specs/README.md` 索引，标注每个功能的"当前有效 spec 链"

3. 旧 spec 不要删——它是决策历史。新 spec 覆盖旧 spec 的行为定义，但旧 spec 里的 Why 和被否决的方案仍然有参考价值

## 流程腐化的信号

框架用久了会形成惯性，以下信号说明流程本身需要反思，而不是继续机械执行：

| 信号 | 说明 | 该怎么办 |
|:-----|:-----|:---------|
| spec review 变成橡皮图章 | 没人真看就通过了 | review 改为同步会议讨论，或缩小 reviewer 范围到真正关心的人 |
| constitution 条款从没拦住过任何 PR | 要么条款太泛拦不住，要么团队已经内化了这些原则 | 季度复审时删掉 90 天内没拦住 PR 的条款，保留真正起作用的 |
| tasks.md 生成后立刻被大幅手动改 | plan 的质量不够，AI 产出的任务拆解不贴合实际 | 回头检查 plan.md 是否足够具体，或 spec 是否有遗漏导致 plan 偏差 |
| clarify 每次都"No critical ambiguities" | 要么 spec 确实写得好，要么 AI 的消歧能力不足 | 抽查几次：人工看 spec 是否真的没歧义。如果人能找到 AI 没找到的盲区，说明 clarify 需要更好的 prompt 或模板 |
| 团队开始绕过流程直接写代码 | 流程成本高于感知收益 | 正视这个信号——检查是不是流程太重了，适当精简。强制全员走完整流程不如让流程轻到大家愿意用 |

**最后一条最重要**：如果团队开始绕过流程，不要加更多检查来堵，而是问"流程的哪一步成本收益比最差"，然后砍掉它。好的流程是大家主动想用的，不是被迫遵守的。
