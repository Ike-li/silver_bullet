# silver-bullet-spec

面向复杂变更的**仓库内助手技能**：大规模修改前先分析与规划；进度持久化在 `docs/progress/`；可选在 `skills/<task-slug>/` 下放任务级执行技能；完成后归档至 `docs/archives/`。

## 在新会话中如何启用

让助手加载 **`skills/silver-bullet-spec/SKILL.md`**（或使用你编辑器中的技能、规则等挂载方式）。若已有进行中的工作且存在 `docs/progress/MASTER.md`，请打开或引用它，以便从正确阶段续做。

## 与 `vendor/spec_driven_develop` 的关系

`vendor/spec_driven_develop/` 是上游插件/skill 源的**只读快照**。本包**不会**自动替换或与 vendor 同步；仅选择性复用方法论与模板，**不包含**安装脚本、平台命令或全局路径。迭代 **silver-bullet-spec** 时请勿改 vendor。

## 任务 slug（`<task-slug>`）命名

使用 **小写 ASCII + 连字符**，在 `skills/` 下稳定且唯一（例如 `postgres-cutover-q2`、`stripe-webhook-adapter`）。避免空格与大写，保证路径可移植。

## 可选后续

- 若希望分析产物仅保留在本地，可补充简短的 `docs/` 说明或 `.gitignore` 片段。
- 真实项目跑通一轮后，可把本 README 中的示例改成团队常用说法。
