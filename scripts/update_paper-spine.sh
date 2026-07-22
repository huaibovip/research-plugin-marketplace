#!/usr/bin/env bash

PLUGIN_NAME="paper-spine"
PLUGIN_DESCRIPTION="Contribution-first, reviewer-aware academic paper and report writing system for Claude Code."
PLUGIN_AUTHOR_NAME="WUBING2023"
PLUGIN_HOMEPAGE="https://github.com/WUBING2023/PaperSpine"
PLUGIN_REPOSITORY="https://github.com/WUBING2023/PaperSpine"
PLUGIN_LICENSE="MIT"
PLUGIN_KEYWORDS=(
  academic-writing
  paper-writing
  latex
  research
  reports
  competition-writing
)

SRC_REPO="https://github.com/WUBING2023/PaperSpine.git"
SRC_BRANCH="main"

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/plugin-common.sh"

plugin_import_layout() {
  local source_dir="$1"
  local plugin_dir="$2"

  mp_move_path "$source_dir/dist/claude" "$plugin_dir/claude"
  mp_move_path "$source_dir/dist/codex" "$plugin_dir/codex"
  mp_move_path "$source_dir/README.md" "$plugin_dir/README.md"
  mp_move_path "$source_dir/README.en.md" "$plugin_dir/README.en.md"
  mp_move_path "$source_dir/LICENSE" "$plugin_dir/LICENSE"
  mp_move_path "$source_dir/.gitignore" "$plugin_dir/.gitignore"

  # rm -rf "$plugin_dir/codex/skills"
  # ln -s ../claude/skills "$plugin_dir/codex/skills"
}

post_update() {
  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  PLUGIN_DIR="$REPO_ROOT/plugins/$PLUGIN_NAME"

  cp -rL "$PLUGIN_DIR/.codex-plugin" "$PLUGIN_DIR/codex"
  rm -rf "$PLUGIN_DIR/.codex-plugin"
  mp_move_path "$PLUGIN_DIR/.claude-plugin" "$PLUGIN_DIR/claude/.claude-plugin"
  mp_move_path "$PLUGIN_DIR/.github" "$PLUGIN_DIR/claude/.github"
}

main() {
  mp_enable_strict_mode
  mp_setup_cleanup_trap
  mp_require_cmd git
  mp_init_repo_context

  PLUGIN_VERSION="$(get_repo_version "$SRC_REPO")"

  mp_update_via_selective_copy \
    "$PLUGIN_NAME" \
    "$SRC_REPO" \
    "$SRC_BRANCH" \
    plugin_import_layout

  post_update
}

main "$@"
