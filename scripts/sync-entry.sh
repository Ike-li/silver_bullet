#!/usr/bin/env bash
#
# sync-entry.sh — 从 CLAUDE.md 同步生成各工具的入口文件
#
# CLAUDE.md 是单一源。运行此脚本后，AGENTS.md、
# .cursor/rules/silver-bullet.mdc、.github/copilot-instructions.md
# 会自动更新，保持与 CLAUDE.md 一致。
#
# 用法:
#   ./scripts/sync-entry.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE="$REPO_ROOT/CLAUDE.md"

[[ -f "$SOURCE" ]] || { echo "错误: CLAUDE.md 不存在"; exit 1; }

CONTENT="$(cat "$SOURCE")"
MARKER="<!-- 自动生成，请勿直接编辑。源文件: CLAUDE.md —— 运行 ./scripts/sync-entry.sh 同步 -->"

# ============================================================================
# AGENTS.md (Codex) — 格式与 CLAUDE.md 相同，直接复制
# ============================================================================

cat > "$REPO_ROOT/AGENTS.md" <<EOF
$MARKER

$CONTENT
EOF

echo "已同步: AGENTS.md"

# ============================================================================
# .github/copilot-instructions.md (Copilot) — 格式也是纯 markdown
# ============================================================================

mkdir -p "$REPO_ROOT/.github"

cat > "$REPO_ROOT/.github/copilot-instructions.md" <<EOF
$MARKER

$CONTENT
EOF

echo "已同步: .github/copilot-instructions.md"

# ============================================================================
# .cursor/rules/silver-bullet.mdc (Cursor) — 需要 Cursor 特有的 frontmatter
# ============================================================================

mkdir -p "$REPO_ROOT/.cursor/rules"

# 提取 CLAUDE.md 中"项目概述"段作为 Cursor rule 的 description
DESCRIPTION="silver_bullet 仓库工作指引：任务路由、skill 格式规范、关键约定。"

cat > "$REPO_ROOT/.cursor/rules/silver-bullet.mdc" <<EOF
---
description: $DESCRIPTION
globs:
alwaysApply: true
---

$MARKER

$CONTENT
EOF

echo "已同步: .cursor/rules/silver-bullet.mdc"

echo ""
echo "全部同步完成。入口文件基于 CLAUDE.md 生成。"
echo "修改内容请编辑 CLAUDE.md，然后重新运行此脚本。"
