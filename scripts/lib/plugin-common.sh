#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf 'This file is a shared library and must be sourced, not executed.\n' >&2
  exit 1
fi

declare -ag MP_TMP_PATHS=()


mp_log() {
  printf '[update-plugins] %s\n' "$*"
}

mp_warn() {
  printf '[update-plugins] WARN: %s\n' "$*" >&2
}

mp_err() {
  printf '[update-plugins] ERROR: %s\n' "$*" >&2
  exit 1
}

mp_enable_strict_mode() {
  set -euo pipefail
}

mp_require_cmd() {
  local cmd

  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || mp_err "required command not found: $cmd"
  done
}

mp_init_repo_context() {
  local lib_dir

  lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  SCRIPT_DIR="$(cd "$lib_dir/.." && pwd)"
  REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  PLUGINS_DIR="$REPO_ROOT/plugins"
  TMP_DIR="$REPO_ROOT/.tmp"

  mkdir -p "$PLUGINS_DIR" "$TMP_DIR"
  cd "$REPO_ROOT"
}

_mp_register_cleanup() {
  MP_TMP_PATHS+=("$1")
}

_mp_cleanup() {
  local idx
  local path

  for ((idx=${#MP_TMP_PATHS[@]} - 1; idx >= 0; idx--)); do
    path="${MP_TMP_PATHS[$idx]}"
    if [[ -n "$path" && -e "$path" ]]; then
      rm -rf "$path"
    fi
  done
}

mp_setup_cleanup_trap() {
  trap _mp_cleanup EXIT
}

_mp_prepare_plugin_dir() {
  local plugin_name="$1"
  local plugin_dir="$PLUGINS_DIR/$plugin_name"

  rm -rf "$plugin_dir"
  mkdir -p "$plugin_dir"

  printf '%s\n' "$plugin_dir"
}

_mp_make_temp_path() {
  local name="$1"
  local path="$TMP_DIR/$name"

  mkdir -p "$(dirname "$path")"
  rm -rf "$path"
  _mp_register_cleanup "$path"

  TMPDIR="$path"
}

_mp_clone_repo() {
  local repo="$1"
  local branch="$2"
  local dest="$3"
  local output

  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"

  mp_log "Cloning $(basename "$repo" .git)..."

  if output=$(git clone -q -b "$branch" --single-branch "$repo" "$dest" 2>&1); then
    mp_log "Clone completed."
  else
    mp_err "Failed to clone repository.\n$output"
  fi
}

mp_assert_exists() {
  local path="$1"

  [[ -e "$path" ]] || mp_err "expected path not found: $path"
}

mp_ensure_dir() {
  mkdir -p "$1"
}

mp_copy_path() {
  local source_path="$1"
  local dest_path="$2"

  mp_assert_exists "$source_path"
  mkdir -p "$(dirname "$dest_path")"
  cp -a "$source_path" "$dest_path"
}

mp_move_path() {
  local source_path="$1"
  local dest_path="$2"

  mp_assert_exists "$source_path"
  mkdir -p "$(dirname "$dest_path")"
  mv "$source_path" "$dest_path"
}

mp_remove_paths() {
  local base_dir="$1"
  shift

  local relative_path
  local matches
  shopt -s nullglob

  for relative_path in "$@"; do
    matches=( "$base_dir"/$relative_path )
    rm -rf "${matches[@]}"
  done

  shopt -u nullglob
}

mp_replace_in_file() {
  local file_path="$1"
  local old_text="$2"
  local new_text="$3"

  mp_assert_exists "$file_path"
  sed -i "s/${old_text}/${new_text}/g" "$file_path"
}

get_repo_version() {
    local url="$1"
    local repo version

    # 提取 owner/repo
    repo="${url#https://github.com/}"
    repo="${repo%.git}"

    # Latest Release
    version=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null |
        sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p')

    # Latest Tag
    if [[ -z "$version" ]]; then
        version=$(git ls-remote --tags --sort=-version:refname "$url" |
            awk '!/\^\{\}$/ {sub("refs/tags/", "", $2); print $2; exit}')
    fi

    # 去掉前导 v/V
    version="${version#[vV]}"

    # 默认使用 HEAD 的短 Commit SHA
    if [[ -z "$version" ]]; then
        version=$(git ls-remote "$url" HEAD | awk '{print substr($1,1,7)}')
    fi

    printf '%s\n' "$version"
}

_mp_require_plugin_metadata() {
  : "${PLUGIN_NAME:?PLUGIN_NAME is required}"
  : "${PLUGIN_DESCRIPTION:?PLUGIN_DESCRIPTION is required}"
  : "${PLUGIN_VERSION:?PLUGIN_VERSION is required}"
  : "${PLUGIN_AUTHOR_NAME:?PLUGIN_AUTHOR_NAME is required}"
  : "${PLUGIN_HOMEPAGE:?PLUGIN_HOMEPAGE is required}"
  : "${PLUGIN_REPOSITORY:?PLUGIN_REPOSITORY is required}"
  : "${PLUGIN_LICENSE:?PLUGIN_LICENSE is required}"

  if [[ ${#PLUGIN_KEYWORDS[@]} -eq 0 ]]; then
    mp_err "PLUGIN_KEYWORDS must contain at least one keyword"
  fi
}

_mp_render_marketplace_plugin_json() {
  local template_path="$1"
  local target_path="$2"
  local renderer_script="$SCRIPT_DIR/lib/write_json.py"

  mp_assert_exists "$template_path"
  mp_assert_exists "$renderer_script"
  mkdir -p "$(dirname "$target_path")"

  PLUGIN_NAME="$PLUGIN_NAME" \
  PLUGIN_DESCRIPTION="$PLUGIN_DESCRIPTION" \
  PLUGIN_VERSION="$PLUGIN_VERSION" \
  PLUGIN_AUTHOR_NAME="$PLUGIN_AUTHOR_NAME" \
  PLUGIN_HOMEPAGE="$PLUGIN_HOMEPAGE" \
  PLUGIN_REPOSITORY="$PLUGIN_REPOSITORY" \
  PLUGIN_LICENSE="$PLUGIN_LICENSE" \
  python3 "$renderer_script" "$template_path" "$target_path" "${PLUGIN_KEYWORDS[@]}"
}

# Restores the marketplace metadata files
mp_restore_marketplace_metadata() {
  local source_dir="$1"
  local target_dir="$2"

  mp_require_cmd python3 curl sed awk
  _mp_require_plugin_metadata

  mp_assert_exists "$source_dir/.claude-plugin/plugin.json"
  mp_assert_exists "$source_dir/.gitignore"

  _mp_render_marketplace_plugin_json \
    "$source_dir/.claude-plugin/plugin.json" \
    "$target_dir/.claude-plugin/plugin.json"

  mp_copy_path "$target_dir/.claude-plugin/plugin.json" "$target_dir/.codex-plugin/plugin.json"
  mp_copy_path "$target_dir/.claude-plugin/plugin.json" "$target_dir/.github/plugin/plugin.json"

  # mkdir -p "$target_dir/.codex-plugin"
  # ln -sfn ../.claude-plugin/plugin.json "$target_dir/.codex-plugin/plugin.json"

  # mkdir -p "$target_dir/.github/plugin"
  # ln -sfn ../../.claude-plugin/plugin.json "$target_dir/.github/plugin/plugin.json"

  cp -a "$source_dir/.gitignore" "$target_dir/.gitignore"

  mp_log "Restored marketplace metadata files to $target_dir"
}

# Updates a plugin by cloning the source repository,
# applying a transformation function, and restoring marketplace metadata.
mp_update_via_direct_clone() {
  local plugin_name="$1"
  local src_repo="$2"
  local src_branch="$3"
  local transform_fn="$4"
  local plugin_dir
  local template_dir="$REPO_ROOT/template"

  plugin_dir="$(_mp_prepare_plugin_dir "$plugin_name")"

  mp_log "Updating $plugin_name from $src_repo"
  _mp_clone_repo "$src_repo" "$src_branch" "$plugin_dir"
  "$transform_fn" "$plugin_dir"
  mp_restore_marketplace_metadata "$template_dir" "$plugin_dir"
  mp_log "Finished $plugin_name"
}

# Updates a plugin by selectively copying files from the source repository,
# applying an import function, and restoring marketplace metadata.
mp_update_via_selective_copy() {
  local plugin_name="$1"
  local src_repo="$2"
  local src_branch="$3"
  local import_fn="$4"
  local plugin_dir
  local source_checkout
  local template_dir="$REPO_ROOT/template"

  plugin_dir="$(_mp_prepare_plugin_dir "$plugin_name")"
  _mp_make_temp_path "$plugin_name/source"
  source_checkout="$TMPDIR"

  mp_log "Updating $plugin_name from $src_repo"
  _mp_clone_repo "$src_repo" "$src_branch" "$source_checkout"
  "$import_fn" "$source_checkout" "$plugin_dir"
  mp_restore_marketplace_metadata "$template_dir" "$plugin_dir"
  mp_log "Finished $plugin_name"
}
