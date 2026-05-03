# [PROJECT_NAME] Constitution — Backend

> **性质**：后端项目原则模板，供 spec-kit `/speckit.constitution` 使用。
> 所有 `[X]` 占位符在项目落地时 MUST 替换为具体值或显式声明"沿用默认"。
> 实例化后存放于 `.specify/memory/constitution.md`。

## Core Principles

### I. 不让用户暴露在系统失败中 (NON-NEGOTIABLE)

用户永远不应看到堆栈、原始错误码或无意义的失败信息。

- 外部依赖 MUST 设置超时（默认 [N]s），超时走降级而非挂起。
- 可恢复错误 MUST 给用户可执行的下一步（重试 / 回退 / 求助）。
- 不可恢复错误 MUST 给出明确失败原因，禁止裸抛异常到用户层。
- 关键路径 MUST 有降级或回退方案，降级行为 MUST 有监控告警。

### II. 敏感数据不落地 (NON-NEGOTIABLE)

密码、token、API key、PII 禁止出现在日志、错误信息、埋点、测试快照中。

- Logger MUST 配置 redactor，redactor MUST 有测试。
- 代码库（含测试）禁止硬编码任何 secret，MUST 通过环境变量或 secret manager 注入。
- 违反一次就是事故，不需要讨论。

### III. 核心数据写入必须有测试守护 (NON-NEGOTIABLE)

核心数据 = 钱、用户身份、权限、数据删除/迁移、状态不可逆变更。

- 这类代码 MUST 先写失败测试，再写实现（TDD）。
- 其他代码（UI、view、查询）可以先发再补测试。

### IV. 简单优先 (NON-NEGOTIABLE)

- 可读优先于聪明，命名 MUST 自解释。
- 三处重复才允许抽象，两处以下复制。
- 不为"未来可能的需求"写抽象层。
- 直接使用框架，不包装它。

## 明确不做

比"必须做"更重要的是明确**不做什么**。以下条目在触发条件满足前禁止引入：

| 禁止 | 直到 |
|:-----|:-----|
| 拆微服务 | >= [N] 个团队需要独立部署节奏 |
| 抽 Repository / DAO 接口 | 有第 2 种数据源 |
| 引第二种 RPC 风格（如 REST + GraphQL 混合） | 有不可调和的技术约束且经 review 确认 |
| 写 abstract base class | 出现第 3 个具体子类 |
| 生产环境同步调外部 API / 发邮件 / 写审计 | 永远不做——一律走异步队列 |
| 引新的状态管理/缓存/队列中间件 | 有"现有方案做不到 X"的具体证据 |

## 阶段化纪律

不同阶段守不同的线，提前加 = 过度治理，该加不加 = 技术债。

| 阶段 | 触发条件 | 加什么 |
|:-----|:---------|:-------|
| **MVP** | < 6 个月 / < 100 用户 | 只守 Core Principles + 明确不做 |
| **PMF** | DAU > 1000 或付费 > 100 | 加：覆盖率 >= [N]% / 性能基线 / 结构化日志 + tracing |
| **规模化** | 团队 > 10 人或多区域部署 | 加：SemVer / 迁移指南 / 多人 review / SLO + error budget |

当前阶段：**[STAGE]**

## AI 协作边界

- AI 可以：写代码、写测试、写文档、提出方案。
- AI 不能单独决定：DB 迁移上生产、密钥与权限变更、对外接口契约变更、删除任何数据。
- AI 生成的测试 MUST 在合并前由人确认它真的会 fail（防恒真测试）。
- AI 写的 commit MUST 由人 review 后合并。

## Governance

- 本 constitution 高于所有其他实践约定；冲突时以本文件为准。
- 修订走 PR，commit message 写清变更理由。
- 每季度复审一次：删掉 90 天内没拦下任何 PR 的条款。
- 加新条款 MUST 附"上次违反它造成的具体损失"（事故、客诉、回滚记录），没有损失证据不进。

**Version**: [CONSTITUTION_VERSION] | **Ratified**: [RATIFICATION_DATE] | **Last Amended**: [LAST_AMENDED_DATE]
