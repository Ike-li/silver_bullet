---
name: skill-intake
description: "第三方 skill 接入与适配：从外部来源（GitHub 仓库、vendor 目录、本地路径）引入 skill 并适配为 silver_bullet 格式。当用户给出一个 skill 的路径、URL、GitHub 地址，或说'帮我接入这个 skill''引入这个 skill''把这个 skill 加进来''适配这个 skill'时触发。不用于：从零新建 skill（用 new-skill.sh）、修改已有 skill、安装 skill 到目标项目（用 install.sh）。"
user-invocable: true
version: 0.1.0
---

# Skill Intake（第三方 Skill 接入）

将外部 skill 引入 silver_bullet 并完成适配，使其符合本仓库规范。

## 工作流程

### Phase 1：获取源 skill

根据用户提供的来源获取源 skill：

- **GitHub URL**：克隆或直接读取仓库中的 SKILL.md
- **vendor 目录**：直接读取 `vendor/*/skills/<name>/SKILL.md`
- **本地路径**：直接读取

确认源目录包含 SKILL.md 后，通读正文，理解 skill 的定位和能力。

### Phase 2：生成适配脚手架

运行接入脚本：

```bash
./scripts/intake-skill.sh <源skill目录> <新skill名>
```

脚本会自动：
1. 提取源 SKILL.md 的 frontmatter 和正文
2. 在 `skills/<新名>/` 下生成适配版 SKILL.md、README.md
3. 复制 references/scripts/examples 等资源目录
4. 生成 `INTAKE.md` 接入审计清单

如果源是 GitHub URL 且未在本地，先 clone 到临时目录。

新 skill 名称必须是小写 kebab-case，与用户确认后再执行。

### Phase 3：适配 description

编辑生成的 SKILL.md，完成 description 中的 TODO：

1. **补充中文触发短语**：列出典型的用户表达方式
2. **补充负面边界**：明确写出"不用于：..."
3. **保留原有英文描述**的关键信息，不要丢掉有效触发词

参考本仓库 description 写法规范：`docs/skill-authoring-guidelines.md` 第五节。

> 注意：Claude 倾向于 undertrigger（不够积极地触发 skill），因此 description 应覆盖足够多的触发场景。

### Phase 4：内容审计与裁剪

通读正文，按以下标准审计：

1. **安全性**：无恶意代码、无隐蔽数据泄露、无可疑外部请求
2. **行数**：建议 < 500 行；超过则拆分到 references/
3. **必要章节**：确认有"何时使用"和"不适用场景"（或等价表述）
4. **可执行性**：核心流程是具体的操作步骤，不是空泛理念
5. **路径修正**：所有引用路径改为适配后的路径
6. **边界检查**：与仓库内现有 skill 无职责重叠

按需裁剪不需要的部分，不要原样照搬。

### Phase 5：校验与试跑

1. 运行校验：

```bash
./scripts/validate.sh <新skill名>
```

2. 修复所有错误，尽量消除警告

3. 用 2-3 个真实 prompt 试跑，验证 skill 是否按预期工作

### Phase 6：完成接入

1. 确认 INTAKE.md 审计清单所有项目已勾选
2. 向用户汇报接入结果：skill 名称、核心能力、安装方式

接入完成后，用户可通过 install.sh 将 skill 安装到目标项目：

```bash
./scripts/install.sh <skill名> <工具> <目标项目>
```

## 注意事项

- 不要修改 vendor/ 目录中的原始文件
- 接入不等于启用——INTAKE.md 清单未全部勾选前不算正式可用
- 如果源 skill 过于庞大或职责过宽，只提取需要的部分，不要全盘引入
