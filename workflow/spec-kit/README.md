# Spec-Kit Workflow

本文档说明本项目如何使用 Spec-Kit。真正有约束力的项目原则见 `constitution.md`。

## 核心文件

| 文件 | 作用 |
|---|---|
| `.specify/memory/constitution.md` | Spec-Kit 实际读取的项目原则 |
| `workflow/spec-kit/constitution.md` | 仓库内保存的人类可读版本 |

两份文件内容必须保持一致。修改原则时，先改 `workflow/spec-kit/constitution.md`，再同步到 `.specify/memory/constitution.md`。

## 标准流程

| 阶段 | 命令 | 产物 | 审核重点 |
|---|---|---|---|
| 立项原则 | `/speckit.constitution` | constitution | 原则是否少、硬、可执行 |
| 需求规约 | `/speckit.specify` | spec | 是否说明用户目标、边界、非目标 |
| 需求澄清 | `/speckit.clarify` | clarified spec | 是否消除关键歧义 |
| 技术计划 | `/speckit.plan` | plan | 是否遵守 constitution，是否避免过度设计 |
| 任务拆分 | `/speckit.tasks` | tasks | 是否能按任务独立实现和验证 |
| 实现 | `/speckit.implement` | code/tests/docs | 是否通过测试、review 和原则检查 |

## 进入下一阶段的条件

每个阶段结束后必须检查：

1. 当前产物是否解决了本阶段目标
2. 是否违反 `constitution.md`
3. 是否存在未说明的技术假设
4. 是否能被测试或人工验收
5. 是否没有引入无必要的抽象、依赖或流程

不满足以上条件，不进入下一阶段。

## Plan 阶段硬性检查

`/speckit.plan` 产物必须包含：

- 技术方案
- 数据模型或接口变化
- 测试策略
- 风险与回退方案
- 对 constitution 的检查结果

违反 constitution 的地方，必须写入 `Complexity Tracking`：

| 违反项 | 为什么需要 | 为什么更简单方案不行 |
|---|---|---|

没有充分理由的违反项，不能进入实现阶段。

## 实现阶段要求

实现阶段只接受小步提交：

- 每个 commit 只解决一个清晰问题
- commit message 必须和实际变更一致
- 核心数据写入路径必须先有失败测试
- 涉及密钥、权限、删除数据、DB 迁移的变更必须人工 review