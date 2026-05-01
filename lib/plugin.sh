#!/bin/bash

is_valid_repo() {
  local repo="$1"
  printf '%s' "$repo" | grep -Eq '^[^/[:space:]]+/[^/[:space:]]+$'
}

build_github_repo_path() {
  local repo="$1"
  printf 'github.com/%s' "$repo"
}

build_github_repo_url() {
  local repo="$1"
  printf 'https://%s' "$(build_github_repo_path "$repo")"
}

build_github_repo_git_url() {
  local repo="$1"
  printf '%s.git' "$(build_github_repo_url "$repo")"
}

build_github_raw_base_url() {
  local repo="$1"
  printf 'https://raw.githubusercontent.com/%s/main' "$repo"
}

read_plugin_config() {
  local config_file="$1"

  [ -f "$config_file" ] || return 0

  python3 - "$config_file" <<'EOF'
import json
import sys

config_file = sys.argv[1]

with open(config_file, "r", encoding="utf-8") as handle:
    data = json.load(handle)

for entry in data.get("plugins", []):
    name = entry.get("name", "")
    repo = entry.get("repo", "")
    description = entry.get("description", "")
    if name and repo:
        print(f"{name}|{repo}|{description}")
EOF
}

clone_plugin_repo() {
  local repo="$1"
  local target_dir="$2"

  git clone --depth=1 "$(build_github_repo_git_url "$repo")" "$target_dir"
}

run_plugin_installer() {
  local plugin_dir="$1"
  local repo="$2"
  local repo_path
  local repo_url
  local repo_git_url
  local repo_raw_base_url

  [ -f "$plugin_dir/install.sh" ] || {
    echo "❌ install.sh not found for $repo" >&2
    return 1
  }

  repo_path="$(build_github_repo_path "$repo")"
  repo_url="$(build_github_repo_url "$repo")"
  repo_git_url="$(build_github_repo_git_url "$repo")"
  repo_raw_base_url="$(build_github_raw_base_url "$repo")"

  PLUGIN_REPO="$repo" \
  PLUGIN_REPO_SLUG="$repo" \
  PLUGIN_REPO_PATH="$repo_path" \
  PLUGIN_REPO_URL="$repo_url" \
  PLUGIN_REPO_GIT_URL="$repo_git_url" \
  PLUGIN_REPO_RAW_BASE_URL="$repo_raw_base_url" \
  REPO="$repo" \
  REPO_PATH="$repo_path" \
  REPO_URL="$repo_url" \
  bash "$plugin_dir/install.sh"
}
