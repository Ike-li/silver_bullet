# [PROJECT_NAME] Constitution — Frontend

> **性质**：前端项目原则模板，供 spec-kit `/speckit.constitution` 使用。
> 所有 `[X]` 占位符在项目落地时 MUST 替换为具体值或显式声明"沿用默认"。
> 实例化后存放于 `.specify/memory/constitution.md`。

## Core Principles

### I. 用户感知即真相 (NON-NEGOTIABLE)

用户不关心技术细节，只关心"能不能用"和"快不快"。

- 首屏可交互时间（TTI）MUST < [N]ms，超出 MUST 在计划中说明理由和优化方案。
- 操作反馈 MUST < 100ms 给出视觉响应（loading、skeleton、optimistic update）。
- 网络失败、接口超时 MUST 给用户可理解的提示和可执行的下一步（重试 / 离线提示），禁止白屏或静默吞错。
- 空状态、边界状态（无数据、无权限、404）MUST 有明确设计，不允许展示裸技术信息。

### II. 视觉一致性是底线 (NON-NEGOTIABLE)

不一致的 UI 比丑的 UI 更伤信任。

- 颜色、字号、间距、圆角、阴影 MUST 走 design token / CSS 变量，禁止硬编码魔法值。
- 同一语义的交互组件（按钮、表单、弹窗）MUST 复用同一组件，禁止同功能多实现。
- 新页面 MUST 先确认能复用已有组件，不能复用时 MUST 说明理由。

### III. 可访问性不是可选项 (NON-NEGOTIABLE)

- MUST 达到 WCAG [AA/AAA] 标准（对比度、键盘导航、屏幕阅读器）。
- 交互元素 MUST 有语义化标签（`button` 不用 `div`，`a` 不用 `span`）。
- 表单 MUST 有关联的 label，错误提示 MUST 关联到对应字段。
- 图片 MUST 有 alt text，装饰性图片 MUST 标记 `aria-hidden`。

### IV. 状态管理越简单越好 (NON-NEGOTIABLE)

- 能用组件本地状态解决的，不提升到全局。
- 能用 URL/路由参数表达的状态，不放到 store。
- 服务端数据用数据获取层（[SWR/React Query/等]）管理，不手动塞全局 store。
- 全局 store 只放真正的跨页面共享状态（用户身份、主题、权限）。

## 明确不做

| 禁止 | 直到 |
|:-----|:-----|
| 引第二套组件库 | 现有组件库明确无法满足且经 review 确认 |
| 自建路由/状态管理/请求库 | 框架自带方案被证明不可用 |
| CSS-in-JS 和 utility-first 混用 | 全量迁移其中一种 |
| 在组件内直接调 fetch/axios | 统一走数据获取层 |
| 为"将来可能换框架"写适配层 | 永远不做 |
| 引 SSR/SSG | 有明确的 SEO 或首屏性能证据 |
| 自建 icon 系统 / 自建图表库 | 现有方案被证明不可用 |

## 性能预算

以真实用户设备和网络为基准，不以开发机为基准。

| 指标 | 预算 | 测量方式 |
|:-----|:-----|:---------|
| JS bundle（首屏） | < [N] KB (gzip) | 构建产物分析 |
| LCP | < [N] ms | Lighthouse / RUM |
| CLS | < [N] | Lighthouse / RUM |
| INP | < [N] ms | Lighthouse / RUM |

超出预算的变更 MUST 在 PR 中说明理由和优化计划。

## 阶段化纪律

| 阶段 | 触发条件 | 加什么 |
|:-----|:---------|:-------|
| **MVP** | < 6 个月 / < 100 用户 | 只守 Core Principles + 明确不做 |
| **PMF** | DAU > 1000 或付费 > 100 | 加：性能预算守护 / E2E 覆盖核心链路 / 错误监控（Sentry 等） |
| **规模化** | 团队 > 10 人或多端适配 | 加：design system 版本化 / 视觉回归测试 / bundle 分析 CI 门禁 |

当前阶段：**[STAGE]**

## AI 协作边界

- AI 可以：写组件、写测试、写样式、提出方案。
- AI 不能单独决定：design token 变更、路由结构调整、引入新依赖、删除公共组件。
- AI 生成的 UI 变更 MUST 在浏览器中验证，截图或录屏确认后再合并。
- AI 生成的测试 MUST 由人确认它真的会 fail（防恒真测试）。

## Governance

- 本 constitution 高于所有其他实践约定；冲突时以本文件为准。
- 修订走 PR，commit message 写清变更理由。
- 每季度复审一次：删掉 90 天内没拦下任何 PR 的条款。
- 加新条款 MUST 附"上次违反它造成的具体损失"，没有损失证据不进。

**Version**: [CONSTITUTION_VERSION] | **Ratified**: [RATIFICATION_DATE] | **Last Amended**: [LAST_AMENDED_DATE]
