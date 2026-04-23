# 前端 E2E Bootstrap 最小结构

如果仓库里还没有成型的前端测试基座，建议先落最小结构，再逐步扩展。

## 推荐目录

```text
frontend/
  e2e/
    helpers/
      auth.ts
      monitor.ts
      mock-api.ts
      page-helpers.ts
    login.spec.ts
    dashboard.spec.ts
    layout.spec.ts
    smoke.spec.ts
```

如果项目已经有 `tests/e2e/`、`playwright/` 或别的目录约定，沿用现有结构，不要平行创建第二套目录。

## helper 分工

### `auth.ts`

- mocked E2E 注入已登录态
- live smoke 走真实登录
- 不要把假登录逻辑混进 smoke

### `monitor.ts`

- 监听 `console error`
- 监听 `pageerror`
- 监听 HTTP `status >= 400`
- 提供统一断言出口，例如 `expectCleanPage()`

### `mock-api.ts`

- `fulfillOk()`、`fulfillError()` 之类的响应构造
- request payload 捕获
- 未覆盖请求时显式失败，避免静默漏测

### `page-helpers.ts`

- 等待 loading 消失
- 弹窗确认 / 取消
- 表单通用操作
- 常见页面稳定化逻辑

## 第一批页面建议

先从下面几类页面开局，不要一上来全覆盖：

- 登录页
- Layout / 主导航
- 首页 / Dashboard
- 一个典型 CRUD 页面
- 一个关键动作页
- smoke 最小链路

## 命令建议

- `npm run type-check`
- `npm run test:e2e`
- `npm run test:e2e:smoke`

若项目已有既定命令，沿用原命令，只保证这三类能力存在。
