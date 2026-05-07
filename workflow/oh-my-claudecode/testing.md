# 测试策略

## 现有测试增强

用 OMC 补充测试覆盖：

```
# 补单元测试
/autopilot "为 apps/api/src/todos/todos.service.ts 补充单元测试，覆盖边界情况"

# 补 E2E 测试
/autopilot "为认证流程写 E2E 测试：注册、登录、token 过期、权限不足"

# 补移动端测试
/autopilot "为 TodoItem 组件补充测试：渲染、点击、长按、滑动删除"
```

## QA 循环验证

开发完成后用 `/ultraqa` 循环验证直到全部通过：

```
/ultraqa "运行 pnpm test、pnpm lint、pnpm build，确保全部通过"
```

如果失败，OMC 自动：诊断原因 → 修复 → 重跑，最多 5 轮。

## AI 视觉冒烟测试（/ai-smoke）

纯靠视觉模型"看"页面做冒烟测试，不依赖 CSS 选择器。

### 原理

```
截图 → Claude Vision 看图 → 判断下一步操作 → 点击/输入 → 再截图 → 循环
```

### 使用

```
# 在项目目录下
/ai-smoke --model claude-sonnet-4-6 --url http://localhost:8081

# 只跑特定场景
/ai-smoke --scenario auth-flow,todo-crud

# 显示浏览器看 AI 操作
/ai-smoke --no-headless
```

### 工作流程

1. 读 CLAUDE.md + AGENTS.md 理解项目
2. 自动生成 `.ai-smoke/scenarios.yaml`（冒烟场景）
3. 安装 Browser Use 依赖（uv 自动管理）
4. 运行测试，AI 像人一样操作页面
5. 输出结果 + 截图到 `.ai-smoke/`

### 与传统 E2E 测试的关系

| 维度 | Playwright E2E | AI 冒烟测试 |
|------|---------------|-------------|
| 定位方式 | CSS 选择器（精确） | 视觉理解（像人） |
| 速度 | 快（毫秒级操作） | 慢（每步需 AI 推理） |
| 维护成本 | UI 改动需更新选择器 | 自动适应 UI 变化 |
| 适用场景 | 回归测试（精确、可重复） | 冒烟巡检（快速验证基本功能） |
| 断言方式 | 代码断言 | AI 视觉判断 |

两者互补，不冲突。

### 自定义 Skill

`/ai-smoke` 是一个自定义 OMC Skill，定义在 `~/.claude/skills/ai-smoke/`。可以修改 `scripts/run_smoke.py` 来定制行为。

## 测试层次建议

```
Layer 1: 单元测试（Jest/Vitest）  ← 快，CI 必跑
Layer 2: 集成测试（supertest/httpx） ← 测 API 真实行为
Layer 3: E2E 回归测试（Playwright） ← 精确 UI 回归
Layer 4: AI 冒烟测试（Browser Use） ← 像人一样巡检
```
