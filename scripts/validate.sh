#!/usr/bin/env bash
#
# validate.sh — 校验 silver_bullet 中 skill 的结构与内容质量
#
# 用法:
#   ./scripts/validate.sh                    # 校验所有 skill
#   ./scripts/validate.sh <skill-name>       # 校验指定 skill
#
# 退出码: 0 全部通过, 1 存在错误

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

ERRORS=0
WARNINGS=0

error() { echo "  ✗ $1"; ERRORS=$((ERRORS + 1)); }
warn()  { echo "  ⚠ $1"; WARNINGS=$((WARNINGS + 1)); }
pass()  { echo "  ✓ $1"; }

# ============================================================================
# 从 frontmatter 提取字段值
# ============================================================================

# 提取单行字段 (name, version)
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

# 提取 description（可能是多行 >- 格式）
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

# ============================================================================
# 校验单个 skill
# ============================================================================

validate_skill() {
    local skill_dir="$1"
    local skill_name
    skill_name="$(basename "$skill_dir")"
    local skill_md="$skill_dir/SKILL.md"

    echo ""
    echo "[$skill_name]"

    # --- 结构检查 ---

    if [[ ! -f "$skill_md" ]]; then
        error "SKILL.md 不存在"
        return
    fi
    pass "SKILL.md 存在"

    # frontmatter 存在
    local fm_count
    fm_count=$(grep -c '^---$' "$skill_md" || true)
    if [[ "$fm_count" -lt 2 ]]; then
        error "frontmatter 不完整（需要 --- 开头和结尾）"
        return
    fi
    pass "frontmatter 格式正确"

    # name 与目录名一致
    local fm_name
    fm_name="$(extract_field "$skill_md" "name")"
    if [[ -z "$fm_name" ]]; then
        error "frontmatter 缺少 name 字段"
    elif [[ "$fm_name" != "$skill_name" ]]; then
        error "name 字段 \"$fm_name\" 与目录名 \"$skill_name\" 不一致"
    else
        pass "name 与目录名一致"
    fi

    # name 格式：小写 kebab-case
    if [[ -n "$fm_name" ]] && ! echo "$fm_name" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
        error "name \"$fm_name\" 不符合小写 kebab-case 格式"
    fi

    # version 存在
    local fm_version
    fm_version="$(extract_field "$skill_md" "version")"
    if [[ -z "$fm_version" ]]; then
        warn "frontmatter 缺少 version 字段"
    else
        pass "version: $fm_version"
    fi

    # description 质量
    local desc
    desc="$(extract_description "$skill_md")"
    local desc_len=${#desc}

    if [[ -z "$desc" ]]; then
        error "frontmatter 缺少 description 字段"
    elif [[ $desc_len -lt 50 ]]; then
        error "description 太短（${desc_len} 字符，建议 >= 50）：可能缺少触发语义"
    elif [[ $desc_len -lt 80 ]]; then
        warn "description 偏短（${desc_len} 字符），建议补充触发词或边界条件"
    else
        pass "description 长度充足（${desc_len} 字符）"
    fi

    # description 触发质量：检查是否包含"不用于"或边界描述
    if [[ -n "$desc" ]]; then
        if echo "$desc" | grep -qE '不用于|不适用|不该|排除'; then
            pass "description 包含负面边界"
        else
            warn "description 缺少负面边界（建议写明不该触发的场景）"
        fi
    fi

    # --- 内容检查 ---

    local content
    content="$(extract_content "$skill_md")"

    # 必要章节
    if echo "$content" | grep -qE '何时使用|适用.*任务|适用.*场景'; then
        pass "包含适用场景说明"
    else
        error "缺少适用场景说明（\"何时使用\"或\"适用任务\"）"
    fi

    if echo "$content" | grep -qE '不适用|不用于'; then
        pass "包含不适用场景说明"
    else
        warn "缺少\"不适用场景\"章节"
    fi

    # --- 引用检查 ---

    # 检查 SKILL.md 中引用的 references/ 文件是否存在
    local refs
    refs=$(grep -oE 'references/[a-zA-Z0-9/_-]+\.md' "$skill_md" 2>/dev/null || true)
    if [[ -n "$refs" ]]; then
        while IFS= read -r ref; do
            if [[ -f "$skill_dir/$ref" ]]; then
                pass "引用文件存在: $ref"
            else
                error "引用文件不存在: $ref"
            fi
        done <<< "$refs"
    fi

    # 检查 references/ 目录下的文件是否有被引用
    if [[ -d "$skill_dir/references" ]]; then
        for ref_file in "$skill_dir/references"/*.md; do
            [[ -f "$ref_file" ]] || continue
            local ref_basename
            ref_basename="$(basename "$ref_file")"
            local ref_relative="references/$ref_basename"
            # 在 SKILL.md 和 README.md 中查找引用
            local found=0
            grep -q "$ref_relative" "$skill_md" 2>/dev/null && found=1
            [[ -f "$skill_dir/README.md" ]] && grep -q "$ref_relative" "$skill_dir/README.md" 2>/dev/null && found=1
            if [[ $found -eq 0 ]]; then
                warn "references/$ref_basename 未被 SKILL.md 或 README.md 引用"
            fi
        done
    fi
}

# 从 SKILL.md 提取正文（和 install.sh 共用逻辑）
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
# 主流程
# ============================================================================

echo "silver_bullet skill 校验"
echo "========================"

if [[ $# -ge 1 ]]; then
    # 校验指定 skill
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        sed -n '3,8s/^# *//p' "$0"
        exit 0
    fi
    target="$SKILLS_DIR/$1"
    [[ -d "$target" ]] || { echo "skill 不存在: $1"; exit 1; }
    validate_skill "$target"
else
    # 校验所有 skill
    for dir in "$SKILLS_DIR"/*/; do
        [[ -d "$dir" ]] || continue
        validate_skill "$dir"
    done
fi

echo ""
echo "------------------------"
echo "结果: $ERRORS 个错误, $WARNINGS 个警告"

if [[ $ERRORS -gt 0 ]]; then
    exit 1
else
    exit 0
fi
