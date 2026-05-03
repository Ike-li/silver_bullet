# silver_bullet

`silver_bullet` 是一个用于集中管理 AI 能力资产的私有仓库。

目标不是简单收集别人写的 agent / prompt / skill / mcp，而是对外部能力进行：

- 引入
- 审计
- 适配
- 测试
- 启用
- 追踪更新

从而实现可控、可追溯、可替换、可安全使用。

---

## 仓库结构

```
skills/                  # 自研 skill
vendor/                  # 第三方能力仓库（git submodule，只读）
docs/                    # 方法论文档
agent/  mcp/  prompt/    # 预留目录
scripts/                 # 工具脚本
```

## 当前 Skill

| Skill | 用途 |
|:------|:-----|
| `silver-bullet-spec` | 复杂任务总控：分析 → 计划 → 执行 → 归档 |
| `systematic-debugging-lite` | 执行阶段排障：先根因后修复、先证据后结论 |


## 接入第三方 Skill

## Vendor 管理

第三方能力仓库通过 git submodule 管理：

```bash
# 新增 vendor 仓库
./scripts/add-vendor.sh <repo-url> [自定义目录名]

# 克隆时初始化
git clone --recurse-submodules <repo-url>

# 已克隆的仓库初始化
git submodule update --init

# 更新全部 vendor
git submodule update --remote
```
