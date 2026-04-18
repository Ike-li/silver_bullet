#!/usr/bin/env bash
#
# intake-skill.sh — 从第三方来源提取 skill 并生成 silver_bullet 适配版
#
# 用法:
#   ./scripts/intake-skill.sh <source-skill-dir> <new-skill-name>
#   ./scripts/intake-skill.sh ~/Downloads/webapp-testing web-testing
#   ./scripts/intake-skill.sh vendor/superpowers/skills/systematic-debugging my-debugging
#
# 流程:
#   1. 读取源 SKILL.md，提取 frontmatter 和正文
#   2. 在 skills/<new-name>/ 下生成适配后的脚手架
#   3. 生成接入审计清单
#   4. 提示人工完成适配

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

die() { echo "错误: $*" >&2; exit 1; }

usage() {
    sed -n '3,12s/^# *//p' "$0"
    exit "${1:-0}"
}

# ============================================================================
# 工具函数
# ============================================================================

extract_field() {
    local file="$1" field="$2"
    awk -v f="$field" '
    BEGIN { in_fm=0 }
    /^---$/ { if (in_fm) exit; in_fm=1; next }
    in_fm && $0 ~ "^"f":" {
        sub("^"f": *", "")
        gsub(/^ +| +$/, "")
        print
    }
    ' "$file"
}

extract_description() {
    awk '
    BEGIN { in_fm=0; in_desc=0; desc="" }
    /^---$/ { if (in_fm) { print desc; exit } else { in_fm=1; next } }
    in_fm && /^description:/ {
        sub(/^description: *>?-? */, "")
        if ($0 != "") desc = $0
        in_desc = 1; next
    }
    in_fm && in_desc && /^  / {
        sub(/^  +/, "")
        if (desc != "") desc = desc " "
        desc = desc $0; next
    }
    in_fm && in_desc { in_desc = 0 }
    ' "$1"
}

extract_content() {
    awk '
    BEGIN { in_fm=0; started=0 }
    /^---$/ {
        if (!started) { in_fm=1; started=1; next }
        else if (in_fm) { in_fm=0; next }
    }
    !in_fm && started { print }
    ' "$1"
}

# ============================================================================
# 参数检查
# ============================================================================

[[ $# -ge 2 ]] || usage 1
[[ "$1" == "-h" || "$1" == "--help" ]] && usage 0

SOURCE_DIR="$1"
NEW_NAME="$2"

# 校验源
[[ -d "$SOURCE_DIR" ]] || die "源目录不存在: $SOURCE_DIR"
SOURCE_SKILL="$SOURCE_DIR/SKILL.md"
[[ -f "$SOURCE_SKILL" ]] || die "源目录缺少 SKILL.md: $SOURCE_DIR"

# 校验目标名
if ! echo "$NEW_NAME" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
    die "skill 名称必须是小写 kebab-case: $NEW_NAME"
fi

TARGET_DIR="$SKILLS_DIR/$NEW_NAME"
[[ ! -d "$TARGET_DIR" ]] || die "目标 skill 已存在: $TARGET_DIR"

# ============================================================================
# 读取源 skill 信息
# ============================================================================

SRC_NAME="$(extract_field "$SOURCE_SKILL" "name")"
SRC_DESC="$(extract_description "$SOURCE_SKILL")"
SRC_CONTENT="$(extract_content "$SOURCE_SKILL")"
SRC_VERSION="$(extract_field "$SOURCE_SKILL" "version")"
SRC_LINE_COUNT=$(echo "$SRC_CONTENT" | wc -l | tr -d ' ')

echo "源 skill 信息:"
echo "  name:        ${SRC_NAME:-（无）}"
echo "  description: ${SRC_DESC:0:80}..."
echo "  version:     ${SRC_VERSION:-（无）}"
echo "  正文行数:    $SRC_LINE_COUNT"
echo ""

# ============================================================================
# 生成适配版
# ============================================================================

mkdir -p "$TARGET_DIR/references"

# 复制资源目录（如果存在）
for sub in references scripts examples assets reference; do
    if [[ -d "$SOURCE_DIR/$sub" ]]; then
        cp -r "$SOURCE_DIR/$sub" "$TARGET_DIR/"
        echo "已复制: $sub/"
    fi
done

# 生成适配后的 SKILL.md
cat > "$TARGET_DIR/SKILL.md" <<SKILL_EOF
---
name: $NEW_NAME
description: "$SRC_DESC TODO: 补充典型用户触发表达。TODO: 补充不该触发的场景（不用于：...）。"
user-invocable: true
version: 0.1.0
---

$SRC_CONTENT
SKILL_EOF

echo "已生成: $TARGET_DIR/SKILL.md"

# 生成 README.md
cat > "$TARGET_DIR/README.md" <<README_EOF
# $NEW_NAME

基于 \`${SRC_NAME:-unknown}\` 适配的 silver_bullet skill。

## 来源

- 原始 skill: \`$SRC_NAME\`
- 来源路径: \`$SOURCE_DIR\`
- 接入日期: $(date +%Y-%m-%d)

## 适配状态

参见 \`INTAKE.md\` 中的审计清单。

## 相关文件

- 主规则: \`SKILL.md\`
README_EOF

echo "已生成: $TARGET_DIR/README.md"

# 生成接入审计清单
cat > "$TARGET_DIR/INTAKE.md" <<INTAKE_EOF
# $NEW_NAME 接入审计清单

来源: \`${SRC_NAME:-unknown}\` ($(date +%Y-%m-%d))

## 1. 格式适配

- [ ] name 已改为 silver_bullet 命名 ($NEW_NAME)
- [ ] description 已补充中文触发短语
- [ ] description 已补充负面边界（不用于：...）
- [ ] version 已设置

## 2. 内容审计

- [ ] 已通读正文，确认无安全风险（无恶意代码、无隐蔽数据泄露）
- [ ] 已确认正文行数合理（当前 $SRC_LINE_COUNT 行，建议 < 500）
- [ ] 包含"何时使用"或等价章节
- [ ] 包含"不适用场景"或等价说明
- [ ] 核心流程可执行，非纯理念描述

## 3. 资源审计

- [ ] references/ 内容已审查，无冗余或过时文件
- [ ] scripts/ 已审查，无安全风险，依赖已声明
- [ ] 所有引用路径已修正为适配后的路径

## 4. 边界审计

- [ ] 与仓库内现有 skill 无职责重叠
- [ ] 触发条件不会和其他 skill 冲突
- [ ] 若有依赖关系，已在 SKILL.md 中说明

## 5. 验证

- [ ] \`./scripts/validate.sh $NEW_NAME\` 通过
- [ ] 至少用 2-3 个真实 prompt 试跑过
- [ ] 试跑结果符合预期

## 6. 完成

- [ ] INTAKE.md 所有项目已勾选
- [ ] 已从适配状态改为正式启用
INTAKE_EOF

echo "已生成: $TARGET_DIR/INTAKE.md"

echo ""
echo "=== 接入脚手架已生成 ==="
echo ""
echo "  $TARGET_DIR/"
echo "  ├── SKILL.md      ← 需要适配 description 中的 TODO"
echo "  ├── README.md"
echo "  ├── INTAKE.md      ← 接入审计清单，逐项完成"

# 列出复制的资源目录
for sub in references scripts examples assets reference; do
    [[ -d "$TARGET_DIR/$sub" ]] && echo "  ├── $sub/"
done

echo ""
echo "下一步:"
echo "  1. 编辑 SKILL.md 中 description 的 TODO 部分"
echo "  2. 通读正文，按需裁剪或适配"
echo "  3. 逐项完成 INTAKE.md 审计清单"
echo "  4. 运行 ./scripts/validate.sh $NEW_NAME"
echo "  5. 用真实 prompt 试跑"
