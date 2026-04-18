#!/usr/bin/env bash
#
# install.sh — 将 silver_bullet 的 skill 安装到目标项目中
#
# 用法:
#   ./scripts/install.sh <skill> <tool> <target-dir> [--link]
#   ./scripts/install.sh --update <skill> <tool> <target-dir> [--link]
#   ./scripts/install.sh --uninstall <skill> <tool> <target-dir>
#   ./scripts/install.sh --list
#
# 支持的工具: claude-code, cursor, codex, copilot
#
# 示例:
#   ./scripts/install.sh silver-bullet-spec claude-code ~/code/my-app
#   ./scripts/install.sh silver-bullet-spec claude-code ~/code/my-app --link
#   ./scripts/install.sh --update silver-bullet-spec cursor ~/code/my-app
#   ./scripts/install.sh --uninstall silver-bullet-spec cursor ~/code/my-app

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

# ============================================================================
# 工具函数
# ============================================================================

die() { echo "错误: $*" >&2; exit 1; }

# 从 SKILL.md 提取 frontmatter 中的 description（支持多行 >- 和单行引号两种格式）
extract_description() {
    awk '
    BEGIN { in_fm=0; in_desc=0; desc="" }
    /^---$/ { if (in_fm) { print desc; exit } else { in_fm=1; next } }
    in_fm && /^description:/ {
        sub(/^description: *>?-? */, "")
        gsub(/^"|"$/, "", $0)
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

# 从 SKILL.md 提取正文（去掉 YAML frontmatter）
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

# 列出可用 skill
list_skills() {
    echo "可用 skill:"
    echo ""
    for dir in "$SKILLS_DIR"/*/; do
        [[ -f "$dir/SKILL.md" ]] || continue
        local name
        name="$(basename "$dir")"
        local desc
        desc="$(extract_description "$dir/SKILL.md" | cut -c1-70)"
        printf "  %-30s %s\n" "$name" "$desc"
    done
}

# 跨平台 sed -i
sed_inplace() {
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# ============================================================================
# 安装：Claude Code
# ============================================================================
# 策略：将 skill 目录安装到 .claude/skills/<name>/SKILL.md
# Claude Code 从 .claude/skills/<name>/SKILL.md 发现 skill

install_claude_code() {
    local skill_name="$1" skill_dir="$2" target="$3" use_link="$4"
    local dest_dir="$target/.claude/skills/$skill_name"

    if [[ -e "$dest_dir" ]]; then
        if [[ "$UPDATE" -eq 1 ]]; then
            rm -rf "$dest_dir"
        else
            die "已存在: $dest_dir（使用 --update 更新，或 --uninstall 卸载）"
        fi
    fi

    if [[ "$use_link" -eq 1 ]]; then
        mkdir -p "$target/.claude/skills"
        ln -sf "$skill_dir" "$dest_dir"
        echo "已链接: $dest_dir → $skill_dir"
    else
        mkdir -p "$dest_dir"
        cp "$skill_dir/SKILL.md" "$dest_dir/SKILL.md"
        # 复制 references
        if [[ -d "$skill_dir/references" ]]; then
            cp -r "$skill_dir/references" "$dest_dir/references"
        fi
        echo "已复制到: $dest_dir"
    fi

    echo ""
    echo "Claude Code 已注册 skill: /skills 可见 $skill_name"
}

# ============================================================================
# 安装：Cursor
# ============================================================================
# 策略：生成 .cursor/rules/<skill-name>.mdc 规则文件

install_cursor() {
    local skill_name="$1" skill_dir="$2" target="$3"
    local rules_dir="$target/.cursor/rules"
    local dest="$rules_dir/${skill_name}.mdc"

    mkdir -p "$rules_dir"

    if [[ -f "$dest" ]]; then
        if [[ "$UPDATE" -eq 1 ]]; then
            rm "$dest"
        else
            die "已存在: $dest（使用 --update 更新，或 --uninstall 卸载）"
        fi
    fi

    local description content
    description="$(extract_description "$skill_dir/SKILL.md")"
    content="$(extract_content "$skill_dir/SKILL.md")"

    {
        echo "---"
        echo "description: ${description}"
        echo "globs:"
        echo "alwaysApply: true"
        echo "---"
        echo ""
        echo "$content"
        echo ""
        echo "---"
        echo "> 来源: silver_bullet/skills/$skill_name"
        echo "> 完整参考资料: $skill_dir/references/"
    } > "$dest"

    echo "已写入: $dest"
}

# ============================================================================
# 安装：Codex
# ============================================================================
# 策略：追加到目标项目的 AGENTS.md，用 HTML 注释标记边界便于卸载

install_codex() {
    local skill_name="$1" skill_dir="$2" target="$3"
    local dest="$target/AGENTS.md"
    local marker="<!-- silver_bullet:$skill_name -->"
    local marker_end="<!-- /silver_bullet:$skill_name -->"

    if [[ -f "$dest" ]] && grep -q "$marker" "$dest"; then
        if [[ "$UPDATE" -eq 1 ]]; then
            sed_inplace "/<!-- silver_bullet:$skill_name -->/,/<!-- \/silver_bullet:$skill_name -->/d" "$dest"
        else
            die "已存在: AGENTS.md 中的 $skill_name 段（使用 --update 更新，或 --uninstall 卸载）"
        fi
    fi

    local content
    content="$(extract_content "$skill_dir/SKILL.md")"

    {
        echo ""
        echo "$marker"
        echo "$content"
        echo ""
        echo "> 来源: silver_bullet/skills/$skill_name"
        if [[ -d "$skill_dir/references" ]]; then
            echo "> 完整参考资料: $skill_dir/references/"
        fi
        echo "$marker_end"
    } >> "$dest"

    echo "已追加到: $dest"
}

# ============================================================================
# 安装：Copilot（VSCode / JetBrains）
# ============================================================================
# 策略：追加到 .github/copilot-instructions.md

install_copilot() {
    local skill_name="$1" skill_dir="$2" target="$3"
    local dest="$target/.github/copilot-instructions.md"
    local marker="<!-- silver_bullet:$skill_name -->"
    local marker_end="<!-- /silver_bullet:$skill_name -->"

    mkdir -p "$target/.github"

    if [[ -f "$dest" ]] && grep -q "$marker" "$dest"; then
        if [[ "$UPDATE" -eq 1 ]]; then
            sed_inplace "/<!-- silver_bullet:$skill_name -->/,/<!-- \/silver_bullet:$skill_name -->/d" "$dest"
        else
            die "已存在: copilot-instructions.md 中的 $skill_name 段（使用 --update 更新，或 --uninstall 卸载）"
        fi
    fi

    local content
    content="$(extract_content "$skill_dir/SKILL.md")"

    {
        echo ""
        echo "$marker"
        echo "$content"
        echo ""
        echo "> 来源: silver_bullet/skills/$skill_name"
        if [[ -d "$skill_dir/references" ]]; then
            echo "> 完整参考资料: $skill_dir/references/"
        fi
        echo "$marker_end"
    } >> "$dest"

    echo "已追加到: $dest"
}

# ============================================================================
# 卸载
# ============================================================================

uninstall_skill() {
    local skill_name="$1" tool="$2" target="$3"

    case "$tool" in
        claude-code)
            local dest="$target/.claude/skills/$skill_name"
            if [[ -e "$dest" ]]; then
                rm -rf "$dest"
                echo "已删除: $dest"
            else
                die "未找到: $dest"
            fi
            ;;
        cursor)
            local dest="$target/.cursor/rules/${skill_name}.mdc"
            [[ -f "$dest" ]] || die "未找到: $dest"
            rm "$dest"
            echo "已删除: $dest"
            ;;
        codex)
            local dest="$target/AGENTS.md"
            local marker="<!-- silver_bullet:$skill_name -->"
            [[ -f "$dest" ]] && grep -q "$marker" "$dest" || die "未找到: $dest 中的 $skill_name 段"
            sed_inplace "/<!-- silver_bullet:$skill_name -->/,/<!-- \/silver_bullet:$skill_name -->/d" "$dest"
            echo "已从 $dest 移除 $skill_name 段"
            ;;
        copilot)
            local dest="$target/.github/copilot-instructions.md"
            local marker="<!-- silver_bullet:$skill_name -->"
            [[ -f "$dest" ]] && grep -q "$marker" "$dest" || die "未找到: $dest 中的 $skill_name 段"
            sed_inplace "/<!-- silver_bullet:$skill_name -->/,/<!-- \/silver_bullet:$skill_name -->/d" "$dest"
            echo "已从 $dest 移除 $skill_name 段"
            ;;
        *)
            die "不支持的工具: $tool"
            ;;
    esac
}

# ============================================================================
# 参数解析与主流程
# ============================================================================

UNINSTALL=0
UPDATE=0
USE_LINK=0
POSITIONAL=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --list)      list_skills; exit 0 ;;
        --uninstall) UNINSTALL=1; shift ;;
        --update)    UPDATE=1; shift ;;
        --link)      USE_LINK=1; shift ;;
        -h|--help)   sed -n '3,15s/^# *//p' "$0"; exit 0 ;;
        -*)          die "未知选项: $1" ;;
        *)           POSITIONAL+=("$1"); shift ;;
    esac
done

set -- "${POSITIONAL[@]}"
[[ $# -ge 3 ]] || { sed -n '3,14s/^# *//p' "$0"; exit 1; }

SKILL="$1"
TOOL="$2"
TARGET_ARG="$3"

# 校验 skill
SKILL_DIR="$SKILLS_DIR/$SKILL"
[[ -d "$SKILL_DIR" ]]         || { echo "skill 不存在: $SKILL"; echo ""; list_skills; exit 1; }
[[ -f "$SKILL_DIR/SKILL.md" ]] || die "SKILL.md 不存在: $SKILL_DIR/SKILL.md"

# 校验目标目录
TARGET="$(cd "$TARGET_ARG" 2>/dev/null && pwd)" || die "目标目录不存在: $TARGET_ARG"

# 执行
if [[ $UNINSTALL -eq 1 ]]; then
    uninstall_skill "$SKILL" "$TOOL" "$TARGET"
else
    case "$TOOL" in
        claude-code) install_claude_code "$SKILL" "$SKILL_DIR" "$TARGET" "$USE_LINK" ;;
        cursor)      install_cursor "$SKILL" "$SKILL_DIR" "$TARGET" ;;
        codex)       install_codex "$SKILL" "$SKILL_DIR" "$TARGET" ;;
        copilot)     install_copilot "$SKILL" "$SKILL_DIR" "$TARGET" ;;
        *)           die "不支持的工具: $TOOL（支持: claude-code, cursor, codex, copilot）" ;;
    esac
fi
