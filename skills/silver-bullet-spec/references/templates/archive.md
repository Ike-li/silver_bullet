# 归档模板

阶段 7（归档）。索引与目录布局位于 `docs/archives/`。

---

## docs/archives/README.md（归档索引）

```markdown
# 项目归档

本目录存放已完成的 **silver-bullet-spec** 工作流产物。每个子目录对应一次已完成的工作，保留分析、计划、进度历史与任务执行 skill，便于追溯。

| 项目 | 说明 | 周期 | 进度 |
|:-----|:-----|:-----|:-----|
| [<项目名>](./<项目名>/progress/MASTER.md) | 一句话描述 | YYYY-MM-DD — YYYY-MM-DD | 已完成 |
```

更新本文件时在表格中**追加**新行，勿删除已有条目。

---

## 归档目录结构

```
docs/archives/<项目名>/
├── analysis/
│   ├── project-overview.md
│   ├── module-inventory.md
│   └── risk-assessment.md
├── plan/
│   ├── task-breakdown.md
│   ├── dependency-graph.md
│   └── milestones.md
├── progress/
│   ├── MASTER.md
│   ├── phase-1-<短名>.md
│   └── ...
└── skill/
    └── SKILL.md
```

`skill/SKILL.md` 为归档时仓库根目录下 `skills/<task-slug>/SKILL.md` 的副本（见主工作流说明）。
