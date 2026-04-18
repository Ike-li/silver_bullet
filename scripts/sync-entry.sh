#!/usr/bin/env bash
#
# sync-entry.sh — 同步各工具的入口文件
#
# CLAUDE.md 是单一源。
# - AGENTS.md、.github/copilot-instructions.md → symlink 到 CLAUDE.md
#   （任何工具编辑任何入口文件，实际都在改同一个文件）
# - .cursor/rules/silver-bullet.mdc → 生成（Cursor 需要特殊 frontmatter）
#
# 用法:
#   ./scripts/sync-entry.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE="$REPO_ROOT/CLAUDE.md"

[[ -f "$SOURCE" ]] || { echo "错误: CLAUDE.md 不存在"; exit 1; }

# ============================================================================
# AGENTS.md (Codex) — symlink
# ============================================================================

TARGET="$REPO_ROOT/AGENTS.md"
if [[ -L "$TARGET" ]]; then
    echo "已存在 symlink: AGENTS.md → $(readlink "$TARGET")"
elif [[ -f "$TARGET" ]]; then
    rm "$TARGET"
    ln -s CLAUDE.md "$TARGET"
    echo "已替换为 symlink: AGENTS.md → CLAUDE.md"
else
    ln -s CLAUDE.md "$TARGET"
    echo "已创建 symlink: AGENTS.md → CLAUDE.md"
fi

# ============================================================================
# .github/copilot-instructions.md (Copilot) — symlink
# ============================================================================

mkdir -p "$REPO_ROOT/.github"
TARGET="$REPO_ROOT/.github/copilot-instructions.md"
if [[ -L "$TARGET" ]]; then
    echo "已存在 symlink: .github/copilot-instructions.md → $(readlink "$TARGET")"
elif [[ -f "$TARGET" ]]; then
    rm "$TARGET"
    ln -s ../CLAUDE.md "$TARGET"
    echo "已替换为 symlink: .github/copilot-instructions.md → CLAUDE.md"
else
    ln -s ../CLAUDE.md "$TARGET"
    echo "已创建 symlink: .github/copilot-instructions.md → CLAUDE.md"
fi

# ============================================================================
# .cursor/rules/silver-bullet.mdc (Cursor) — 生成
# Cursor 需要特殊 frontmatter，无法用 symlink
# ============================================================================

mkdir -p "$REPO_ROOT/.cursor/rules"
TARGET="$REPO_ROOT/.cursor/rules/silver-bullet.mdc"

CONTENT="$(cat "$SOURCE")"

cat > "$TARGET" <<EOF
---
description: silver_bullet 仓库工作指引：任务路由、skill 格式规范、关键约定。
globs:
alwaysApply: true
---

<!-- 自动生成，请勿直接编辑。源文件: CLAUDE.md —— 运行 ./scripts/sync-entry.sh 同步 -->

$CONTENT
EOF

echo "已生成: .cursor/rules/silver-bullet.mdc"

# ============================================================================

echo ""
echo "同步完成。"
echo "  symlink: AGENTS.md, .github/copilot-instructions.md → CLAUDE.md"
echo "  生成:    .cursor/rules/silver-bullet.mdc"
echo ""
echo "任何工具编辑 AGENTS.md 或 copilot-instructions.md 都等于编辑 CLAUDE.md。"
echo "编辑 CLAUDE.md 后运行此脚本更新 .cursor/rules/silver-bullet.mdc。"
