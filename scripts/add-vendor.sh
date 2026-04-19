#!/usr/bin/env bash
#
# add-vendor.sh — 将第三方 skill 仓库作为 git submodule 添加到 vendor/ 目录
#
# 用法:
#   ./scripts/add-vendor.sh <repo-url> [vendor-name]
#
# 示例:
#   ./scripts/add-vendor.sh https://github.com/foo/foo-skills.git
#   ./scripts/add-vendor.sh https://github.com/foo/foo-skills.git my-foo-skills

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VENDOR_DIR="$REPO_ROOT/vendor"

die() { echo "错误: $*" >&2; exit 1; }

usage() {
    sed -n '3,8s/^# *//p' "$0"
    exit "${1:-0}"
}

[[ $# -ge 1 ]] || usage 1
[[ "$1" == "-h" || "$1" == "--help" ]] && usage 0

REPO_URL="$1"

# 提取或使用传入的 vendor 名称
if [[ $# -ge 2 ]]; then
    VENDOR_NAME="$2"
else
    # 从 URL 提取仓库名，如 https://github.com/foo/bar.git -> bar
    VENDOR_NAME="$(basename "$REPO_URL" .git)"
fi

TARGET_PATH="vendor/$VENDOR_NAME"
ABS_TARGET_PATH="$REPO_ROOT/$TARGET_PATH"

if [[ -d "$ABS_TARGET_PATH" ]]; then
    die "目标目录已存在: $TARGET_PATH"
fi

echo "正在添加 submodule: $REPO_URL -> $TARGET_PATH"

cd "$REPO_ROOT"

# 添加 submodule
git submodule add "$REPO_URL" "$TARGET_PATH"

# 提交变更
git commit -m "vendor: add $VENDOR_NAME

Source: $REPO_URL"

echo ""
echo "=== 已成功添加 vendor ==="
echo "路径: $TARGET_PATH"
echo "变更已提交到当前分支。"
echo ""
echo "下一步:"
echo "使用 ./scripts/intake-skill.sh 从该 vendor 接入具体的 skill。"
