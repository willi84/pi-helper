#!/bin/bash

is_valid_repo() {
  local repo="$1"
  printf '%s\n' "$repo" | grep -Eq '^[^/[:space:]]+/[^/[:space:]]+$'
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

  git clone --depth=1 "https://github.com/$repo.git" "$target_dir"
}

run_plugin_installer() {
  local plugin_dir="$1"
  local repo="$2"

  [ -f "$plugin_dir/install.sh" ] || {
    echo "❌ install.sh not found for $repo" >&2
    return 1
  }

  bash "$plugin_dir/install.sh"
}
