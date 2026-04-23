---
name: frontend-e2e-bootstrap
description: >-
  从零设计前端端到端测试体系：用于在业务前端已存在但仓库还没有成型的 E2E/Playwright
  测试基座时，建立测试目录、helpers、页面分层、mocked E2E、live smoke、命令入口与交付标准。
  当用户说“给这个前端项目搭一套 E2E”“从零设计前端测试流程”“建立 Playwright
  测试体系”“补前端 smoke 和回归基座”时触发。若仓库已存在 e2e/helpers/smoke/config，
  先识别并沿用既有 workflow，再补缺失部分，不直接推翻原结构。不用于单纯执行现有回归、
  纯后端 API 测试、视觉稿评审或只写组件单测。
user-invocable: true
version: 0.1.0
---

# frontend-e2e-bootstrap

先判断仓库有没有现成测试资产；没有就从零搭测试基座，有就沿用已有 workflow 补齐缺口。

## 何时使用

- 用户要求“给这个前端项目搭一套 E2E / Playwright 测试”
- 用户要求“从零设计前端测试流程”“建立前端 smoke 和回归体系”
- 用户要求“把页面测试方法固化成统一 helpers / monitor / auth / mock 结构”
- 仓库还没有 `e2e/`、`playwright.config.*`、共享 helpers，或这些资产零散失序
- 仓库已经有局部测试资产，但需要梳理成统一 workflow，而不是继续零散增长

## 不适用场景

- 只想执行一次现有前端回归，不需要建体系
- 纯后端接口测试、性能测试、压测
- 视觉设计评审、截图对比、品牌走查
- 只写组件单测、Hook 单测，不涉及页面级流程

## 核心原则

1. **先识别现状，再决定搭法**：先看前端目录、路由、API 层、登录方式、现有测试资产，再决定“复用模式”还是“bootstrap 模式”。
2. **检测到现有资产就沿用 workflow**：已有 `e2e/`、`helpers`、`playwright.config.*`、`smoke.spec.*` 时，优先复用命名、目录、登录方式和 helper 约定，不重做平行体系。
3. **helper 先于 spec**：先抽登录、monitor、mock-api、页面公共动作，再扩页面用例；没有 shared helpers，spec 很快会腐化。
4. **分层测试，而不是一锅煮**：默认把体系拆成 `type-check → mocked E2E → live smoke` 三层，每层目标和失败含义不同。
5. **契约优先，避免假绿**：mocked E2E 的 request/response 必须对齐真实契约，不允许凭想象写字段。
6. **monitor 统一收口**：所有页面测试统一监听 `console error`、`pageerror`、HTTP `>= 400`，结束时集中断言。
7. **从第一天开始做覆盖统计**：已覆盖页面、未覆盖页面、mocked E2E 覆盖面、live smoke 覆盖面都要明确。

## 决策门

先做一次判断，再进入后续阶段：

- 若仓库已存在稳定的 `e2e/`、`helpers`、`playwright.config.*`、`smoke.spec.*` 和命令入口：
  走“复用模式”，只补缺失 helper、缺页、缺命令、缺 monitor，不重做结构。
- 若仓库只有零散测试文件，缺少共享 helper、分层规则和命令入口：
  走“整理后增强”模式，保留已有可用文件，补统一骨架。
- 若仓库基本没有页面级测试资产：
  走“bootstrap 模式”，从零搭最小可持续基座。

只有在现有资产明显失效、命名混乱到无法维护、或与主框架严重冲突时，才允许重排结构。

## 禁止事项

- 不要在 live smoke 里注入假登录态
- 不要用错误字段名或随意删字段的 mock 制造假绿
- 不要依赖大量 `waitForTimeout()` 维持稳定性
- 不要同时新建第二套平行 `e2e/` 目录
- 不要在未明确契约来源时伪造“看起来合理”的 response
- 不要只给出测试方案而不落最小可执行骨架

## 工作流程

### Phase 1：识别仓库现状

**目标**：判断当前仓库是“复用模式”还是“bootstrap 模式”。

**动作**：

1. 读取前端目录下的 `package.json`、`playwright.config.*`、`e2e/`、`tests/`、路由、API service 层、鉴权逻辑。
2. 检查是否已有这些资产：
   - `e2e/` 或 `tests/e2e/`
   - `playwright.config.*`
   - `helpers.ts`、`fixtures`、`auth`、`mock`、`smoke.spec.*`
   - CI 中的 E2E 命令
3. 若已有成熟资产，记录“沿用哪些、补哪些”；若没有，就进入从零搭建。
4. 读取 `references/bootstrap-layout.md`，确定最小目录结构和 helper 切分。

**产出**：

- 当前仓库模式：复用 / bootstrap
- 可复用测试资产清单
- 待补齐的测试基座清单

### Phase 2：定义测试范围与分层策略

**目标**：先决定要测哪些页面、哪些走 mocked E2E、哪些必须走 live smoke。

**动作**：

1. 梳理页面与核心链路，至少覆盖：
   - 登录页
   - 首页 / Dashboard
   - Layout / 主导航
   - 一个典型 CRUD 页面
   - 一个关键动作触发页
   - 一个历史 / 报告页
   - live smoke 最小链路
2. 把验证目标分层：
   - `type-check`：静态类型回归
   - mocked E2E：页面渲染、表单、按钮、弹窗、跳转、payload、response 契约
   - live smoke：真实登录、主导航穿越、关键 API 健康
3. 如果现有仓库已经有页面拆分方式，保留原命名并补缺页；不要把成熟结构强改成另一套名字。

**产出**：

- 页面覆盖地图
- mocked E2E / live smoke 边界
- 第一批优先落地页面

### Phase 3：建立测试骨架

**目标**：搭出最小可持续的测试目录和执行入口。

**动作**：

1. 在没有现成资产时，建立最小结构，见 `references/bootstrap-layout.md`。
2. 明确命令入口：
   - `npm run type-check`
   - `npm run test:e2e`
   - `npm run test:e2e:smoke` 或等价命令
3. 若项目还没有 `playwright.config.*`，先补最小配置：`baseURL`、reporter、trace、浏览器、testDir。
4. 若项目已有配置，只增补缺失项，不重写整套配置。

**产出**：

- 目录结构
- 执行命令
- Playwright 基础配置
- CI 可接入的命令入口

### Phase 4：先设计共享 helpers

**目标**：在写页面 spec 前，先把公共能力稳定下来。

**动作**：

1. 设计 `auth` helper：
   - mocked E2E：优先注入 localStorage / token / storageState
   - live smoke：走真实登录，不走假登录
2. 设计 `monitor` helper：
   - 收集 `console error`
   - 收集 `pageerror`
   - 收集 HTTP `status >= 400`
   - 提供统一 `expectCleanPage()` 之类的断言出口
3. 设计 `mock-api` helper：
   - 成功响应 builder
   - 错误响应 builder
   - request payload 捕获
   - 未显式覆盖请求时的失败策略
4. 设计 `page-helpers`：
   - 等待 loading 消失
   - 弹窗确认 / 取消
   - 通用表单交互

**产出**：

- helper 切分方案
- monitor 规则
- auth 与 mock 策略

### Phase 5：先打通第一批 mocked E2E

**目标**：先证明这套测试骨架能稳定测真实页面与真实契约。

**动作**：

1. 优先落 3 到 5 个页面：
   - 登录页
   - Layout / 导航
   - 一个典型 CRUD 页
   - 一个关键动作页
2. 每个 spec 至少验证：
   - 页面正常渲染
   - 表单字段存在
   - 按钮点击触发正确行为
   - 弹窗 / 抽屉字段存在
   - 页面跳转正确
   - payload 与真实后端契约一致
3. 契约来源优先级：
   - OpenAPI / 后端 schema / 接口文档
   - typed client / DTO / service 层
   - 已验证真实响应
   - 现有稳定 mock
4. 接口字段变化时，同步改 mock、前端断言和解析逻辑；不允许保留旧字段制造假绿。

**产出**：

- 第一批 mocked E2E 页面
- 契约断言模式
- 可复用 spec 样板

### Phase 6：补 live smoke

**目标**：在 mocked E2E 稳定后，再加真实链路健康检查。

**动作**：

1. 只保最小真实链路：
   - 登录
   - 主导航穿越
   - 核心弹窗 / 表单字段存在
   - 关键 API 无 `4xx/5xx`
   - 无 `console error` / `pageerror`
2. 对允许噪音的接口建立白名单并注明原因。
3. 真实链路失败时，优先区分代码问题、后端问题、环境问题，不要一概归到前端。

**产出**：

- live smoke 基线
- 环境噪音白名单
- 真实链路失败的分流规则

### Phase 7：覆盖与结果输出

**目标**：把测试体系做成可扩、可复盘、可交接的资产。

**动作**：

1. 每轮输出：
   - 已覆盖页面
   - 未覆盖页面
   - mocked E2E 覆盖范围
   - live smoke 覆盖范围
   - 通过 / 失败 / 风险 / 下一步
2. 失败至少分为：
   - 前端渲染问题
   - 页面运行时异常
   - 后端接口异常
   - 契约不一致
   - 环境问题
**产出**：

- 覆盖地图
- 失败分类口径
- 后续扩展优先级

## 完成标准

达到下面标准，才算这套前端测试基座可进入生产使用：

1. 仓库内存在明确的页面级测试目录与 Playwright 配置
2. 已有可执行的类型检查命令、mocked E2E 命令、live smoke 命令，或明确等价入口
3. 已有共享 `auth / monitor / mock-api / page-helpers` 设计，至少前三者已落地
4. 第一批关键页面已打通 mocked E2E，且 monitor 生效
5. 已有最小 live smoke，覆盖真实登录和主导航主链路
6. 已明确契约来源，不再依赖拍脑袋写 mock
7. 已能输出已覆盖页面、未覆盖页面、失败分类、风险和下一步

需要逐项核对时，读取 `references/production-readiness-checklist.md`。

## 推荐输出格式

1. **现状**：当前是复用模式还是 bootstrap 模式，已发现哪些测试资产
2. **交付物**：新增或调整了哪些目录、配置、helpers、命令
3. **通过**：已打通的命令、页面和链路
4. **风险**：缺失契约、环境依赖、未覆盖页面、噪音接口
5. **下一步**：先补 helper、先落 mocked E2E、还是先补 live smoke

补充固定信息：

- **已覆盖页面**
- **未覆盖页面**
- **命令入口**
- **契约来源**

## 附加资源

- 最小目录结构与 helper 切分：`references/bootstrap-layout.md`
- 生产就绪检查清单：`references/production-readiness-checklist.md`
