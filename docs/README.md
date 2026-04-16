# Silver Bullet 文档索引

本文档目录用于沉淀 `silver_bullet` 的方法论、skill 设计规范、评估流程与长期维护约定。

---

## 当前文档

### 1. [`skill-authoring-guidelines.md`](./skill-authoring-guidelines.md)
Skill 编写指南。

说明如何在 `silver_bullet` 中设计和编写一个高质量 skill，包括：

- skill 的推荐目录结构
- `SKILL.md` 的最小结构
- frontmatter 写法规范
- `description` 的触发描述写法
- `references/`、`scripts/`、`examples/`、`assets/` 的职责划分
- 渐进披露（progressive disclosure）设计原则
- 常见反模式与最小检查清单

适用场景：

- 新建 skill
- 重构已有 skill
- 审查 skill 目录结构与内容分层
- 明确 skill 的边界与触发条件

---

### 2. [`skill-evaluation-loop.md`](./skill-evaluation-loop.md)
Skill 评估与迭代方法。

说明如何验证一个 skill 是否真的有效，包括：

- 为什么 skill 不能只写不测
- 如何定义 skill 的目标与成功标准
- 如何设计测试 prompt
- 如何区分质量评估与触发评估
- 如何记录问题并进行下一轮迭代
- 哪些 skill 值得重点评估
- skill 进入稳定可用状态的判断标准

适用场景：

- skill 初版完成后的试跑
- 优化 `description` 触发效果
- 评估 skill 是否真的提升输出质量
- 规划 skill 的下一轮改进

---

## 推荐阅读顺序

1. 先看 [`skill-authoring-guidelines.md`](./skill-authoring-guidelines.md)
   - 用于设计新 skill
   - 用于审查已有 skill 是否写得过胖、过宽、过虚

2. 再看 [`skill-evaluation-loop.md`](./skill-evaluation-loop.md)
   - 用于设计测试 prompt
   - 用于做一轮真实评估与迭代

---

## 推荐配套实践

当前仓库中，建议优先应用这些文档的方法论到以下 skill：

- [`skills/silver-bullet-spec/`](../skills/silver-bullet-spec/)
- [`skills/systematic-debugging-lite/`](../skills/systematic-debugging-lite/)

原因：

- 一个是复杂任务总控 skill
- 一个是执行阶段专项排障 skill
- 二者是当前最值得长期打磨的方法资产

---

## 文档状态

### 已完成
- [`skill-authoring-guidelines.md`](./skill-authoring-guidelines.md)
- [`skill-evaluation-loop.md`](./skill-evaluation-loop.md)

### 待补充
- `skill-review-checklist.md`
- `skill-trigger-writing-guide.md`
- `skill-resource-layering.md`

### 规划中
- `repo-capability-intake.md`
- `third-party-skill-adoption.md`
- `skill-lifecycle.md`

说明：
- **已完成**：已写入仓库并可直接使用。
- **待补充**：主题已明确，适合在现有两份主文档稳定使用后继续拆分。
- **规划中**：暂时只保留方向，不急于扩写，避免 `docs/` 过早膨胀。

---

## 后续可扩展文档

未来可继续补充：

- `skill-review-checklist.md`
- `skill-trigger-writing-guide.md`
- `skill-resource-layering.md`
- `repo-capability-intake.md`

但在当前阶段，优先把“怎么写 skill”和“怎么评估 skill”跑通，比继续扩文档更重要。
