#!/usr/bin/env bash
#
# new-skill.sh — 创建新 skill 的脚手架
#
# 用法:
#   ./scripts/new-skill.sh <skill-name>
#
# 示例:
#   ./scripts/new-skill.sh api-migration-helper

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

die() { echo "错误: $*" >&2; exit 1; }

# 参数检查
if [[ $# -lt 1 || "$1" == "-h" || "$1" == "--help" ]]; then
    sed -n '3,8s/^# *//p' "$0"
    exit 0
fi

SKILL_NAME="$1"

# 格式校验：小写 kebab-case
if ! echo "$SKILL_NAME" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
    die "skill 名称必须是小写 kebab-case 格式（如 api-migration-helper），当前: $SKILL_NAME"
fi

SKILL_DIR="$SKILLS_DIR/$SKILL_NAME"

# 检查是否已存在
if [[ -d "$SKILL_DIR" ]]; then
    die "skill 目录已存在: $SKILL_DIR"
fi

# 创建目录结构
mkdir -p "$SKILL_DIR/references"

# 生成 SKILL.md
cat > "$SKILL_DIR/SKILL.md" <<'TEMPLATE'
---
name: SKILL_NAME_PLACEHOLDER
description: "TODO: 说明这个 skill 做什么。写明什么时候应该触发，包含典型用户表达。写明不该触发的场景。"
user-invocable: true
version: 0.1.0
---

# SKILL_NAME_PLACEHOLDER

TODO: 一句话说明这个 skill 的核心价值。

## 何时使用

- TODO: 列出典型使用场景

## 不适用场景

- TODO: 列出不该使用的场景

## 核心原则

1. TODO

## 工作流程

### Phase 1：TODO

**目标**：
**动作**：
**产出**：

## 推荐输出格式

TODO: 定义每轮输出的结构化格式
TEMPLATE

# 替换占位符
if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/SKILL_NAME_PLACEHOLDER/$SKILL_NAME/g" "$SKILL_DIR/SKILL.md"
else
    sed -i "s/SKILL_NAME_PLACEHOLDER/$SKILL_NAME/g" "$SKILL_DIR/SKILL.md"
fi

# 生成 README.md
cat > "$SKILL_DIR/README.md" <<EOF
# $SKILL_NAME

TODO: 简要说明这个 skill 的定位和用途。

## 相关文件

- 主规则：\`SKILL.md\`
EOF

echo "已创建 skill 脚手架:"
echo ""
echo "  $SKILL_DIR/"
echo "  ├── SKILL.md"
echo "  ├── README.md"
echo "  └── references/"
echo ""
echo "下一步:"
echo "  1. 编辑 $SKILL_DIR/SKILL.md 填写 TODO 部分"
echo "  2. 运行 ./scripts/validate.sh $SKILL_NAME 检查质量"
echo "  3. 用真实任务试跑并迭代"
