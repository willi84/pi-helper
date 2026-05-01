#!/bin/bash

is_valid_repo() {
  local repo="$1"
  printf '%s' "$repo" | grep -Eq '^[^/[:space:]]+/[^/[:space:]]+$'
}

get_plugin_config_dir() {
  printf '%s/.local/share/pi/config/plugins' "$HOME"
}

get_plugin_state_dir() {
  printf '%s/.local/share/pi/state/plugins' "$HOME"
}

get_plugin_state_key() {
  local repo="$1"
  printf '%s' "$repo" | tr '/' '_'
}

get_plugin_env_file() {
  local repo="$1"
  printf '%s/%s.env' "$(get_plugin_state_dir)" "$(get_plugin_state_key "$repo")"
}

get_last_plugin_file() {
  printf '%s/last-plugin' "$(get_plugin_config_dir)"
}

get_installed_plugins_file() {
  printf '%s/installed-plugins' "$(get_plugin_config_dir)"
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

ensure_plugin_dirs() {
  mkdir -p "$(get_plugin_config_dir)" "$(get_plugin_state_dir)"
}

save_last_plugin_repo() {
  local repo="$1"
  ensure_plugin_dirs
  printf '%s\n' "$repo" > "$(get_last_plugin_file)"
}

save_installed_plugin_repo() {
  local repo="$1"
  local installed_plugins_file
  local tmp_file

  installed_plugins_file="$(get_installed_plugins_file)"
  tmp_file="$(mktemp /tmp/pi-plugin-installed.XXXXXX)"
  ensure_plugin_dirs
  touch "$installed_plugins_file"
  grep -Fxv "$repo" "$installed_plugins_file" > "$tmp_file" || true
  printf '%s\n' "$repo" >> "$tmp_file"
  mv "$tmp_file" "$installed_plugins_file"
}

load_last_plugin_repo() {
  local last_plugin_file
  last_plugin_file="$(get_last_plugin_file)"

  [ -f "$last_plugin_file" ] || return 1
  cat "$last_plugin_file"
}

load_installed_plugin_repos() {
  local installed_plugins_file
  local last_repo

  installed_plugins_file="$(get_installed_plugins_file)"
  last_repo="$(load_last_plugin_repo 2>/dev/null || true)"

  python3 - "$installed_plugins_file" "$last_repo" <<'EOF'
import sys

installed_file = sys.argv[1]
last_repo = sys.argv[2]
seen = set()

def emit(repo: str) -> None:
    repo = repo.strip()
    if not repo or repo in seen:
        return
    seen.add(repo)
    print(repo)

try:
    with open(installed_file, "r", encoding="utf-8") as handle:
        for line in handle:
            emit(line)
except FileNotFoundError:
    pass

emit(last_repo)
EOF
}

save_plugin_env_value() {
  local repo="$1"
  local key="$2"
  local value="$3"
  local env_file
  local tmp_file
  local escaped_value

  env_file="$(get_plugin_env_file "$repo")"
  tmp_file="$(mktemp /tmp/pi-plugin-env.XXXXXX)"
  ensure_plugin_dirs
  touch "$env_file"
  grep -v "^${key}=" "$env_file" > "$tmp_file" || true
  printf -v escaped_value '%q' "$value"
  printf '%s=%s\n' "$key" "$escaped_value" >> "$tmp_file"
  mv "$tmp_file" "$env_file"
}

load_plugin_env_value() {
  local repo="$1"
  local key="$2"
  local env_file

  env_file="$(get_plugin_env_file "$repo")"
  [ -f "$env_file" ] || return 1
  (
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
    eval "printf '%s\n' \"\${$key}\""
  )
}

extract_plugin_env_spec() {
  local install_script="$1"

  python3 - "$install_script" <<'EOF'
import re
import sys

install_script = sys.argv[1]
pattern = re.compile(r'\$\{([A-Z][A-Z0-9_]*)(?:(?::-|:=|-|=)(.*?))?\}')
seen = set()

with open(install_script, "r", encoding="utf-8") as handle:
    content = handle.read()

for key, default in pattern.findall(content):
    if key in seen:
        continue
    seen.add(key)
    normalized_default = default.replace("\n", "\\n")
    print(f"{key}|{normalized_default}")
EOF
}

list_plugin_env_entries() {
  local repo="$1"
  local install_script="$2"
  local env_file

  env_file="$(get_plugin_env_file "$repo")"

  python3 - "$install_script" "$env_file" <<'EOF'
import re
import sys

install_script = sys.argv[1]
env_file = sys.argv[2]
pattern = re.compile(r'\$\{([A-Z][A-Z0-9_]*)(?:(?::-|:=|-|=)(.*?))?\}')
entries = []
seen = set()

def emit(key: str, default: str) -> None:
    key = key.strip()
    if not key or key in seen:
        return
    seen.add(key)
    entries.append((key, default.replace("\n", "\\n")))

with open(install_script, "r", encoding="utf-8") as handle:
    content = handle.read()

for key, default in pattern.findall(content):
    emit(key, default)

try:
    with open(env_file, "r", encoding="utf-8") as handle:
        for raw_line in handle:
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key = line.split("=", 1)[0].strip()
            if re.fullmatch(r"[A-Z][A-Z0-9_]*", key):
                emit(key, "")
except FileNotFoundError:
    pass

for key, default in entries:
    print(f"{key}|{default}")
EOF
}

prompt_plugin_env_updates() {
  local repo="$1"
  local install_script="$2"
  local line
  local key
  local default_value
  local current_value
  local next_value

  exec 3<&0

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    key="${line%%|*}"
    default_value="${line#*|}"
    current_value="$(load_plugin_env_value "$repo" "$key" 2>/dev/null || true)"

    if [ -z "$current_value" ]; then
      current_value="$default_value"
    fi

    printf '🔧 %s [%s]: ' "$key" "$current_value" >&2
    read -r next_value <&3

    if [ -z "$next_value" ]; then
      next_value="$current_value"
    fi

    save_plugin_env_value "$repo" "$key" "$next_value"
  done < <(list_plugin_env_entries "$repo" "$install_script")

  exec 3<&-
}

apply_saved_plugin_env() {
  local repo="$1"
  local env_file

  env_file="$(get_plugin_env_file "$repo")"
  [ -f "$env_file" ] || return 0
  set -a
  # shellcheck disable=SC1090
  source "$env_file"
  set +a
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

show_installed_plugins() {
  display_headline "🔌 Installed plugins" >&2
}

prompt_for_installed_plugin_repo() {
  local options=()
  local repos=()
  local line
  local selected_index
  local manual_repo
  local option
  local i

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    repos+=("$line")
    options+=("$line")
  done < <(load_installed_plugin_repos)

  if [ "${#repos[@]}" -eq 0 ]; then
    read -r -p "Repository (org/repo): " manual_repo
    is_valid_repo "$manual_repo" || {
      echo "❌ Invalid repository format: $manual_repo" >&2
      return 1
    }
    printf '%s\n' "$manual_repo"
    return 0
  fi

  options+=("Manual repository")

  while true; do
    show_installed_plugins
    for i in "${!options[@]}"; do
      printf '%s) %s\n' "$((i + 1))" "${options[$i]}" >&2
    done
    printf '#? ' >&2
    read -r option

    [ -n "$option" ] || {
      echo "❌ Invalid selection" >&2
      continue
    }

    case "$option" in
      ''|*[!0-9]*)
        echo "❌ Invalid selection" >&2
        continue
        ;;
    esac

    selected_index=$((option - 1))
    [ "$selected_index" -ge 0 ] || {
      echo "❌ Invalid selection" >&2
      continue
    }

    if [ "$selected_index" -lt "${#repos[@]}" ]; then
      printf '%s\n' "${repos[$selected_index]}"
      return 0
    fi

    if [ "$selected_index" -ne "${#repos[@]}" ]; then
      echo "❌ Invalid selection" >&2
      continue
    fi

    read -r -p "Repository (org/repo): " manual_repo
    is_valid_repo "$manual_repo" || {
      echo "❌ Invalid repository format: $manual_repo" >&2
      return 1
    }
    printf '%s\n' "$manual_repo"
    return 0
  done
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
  apply_saved_plugin_env "$repo"

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

configure_plugin() {
  local repo="$1"
  local tmp_dir
  local install_script

  if [ -z "$repo" ]; then
    repo="$(prompt_for_installed_plugin_repo)"
  fi

  is_valid_repo "$repo" || {
    echo "❌ Invalid repository format: $repo" >&2
    return 1
  }

  tmp_dir="$(mktemp -d /tmp/pi-plugin-update.XXXXXX)"
  trap 'rm -rf "$tmp_dir"' EXIT

  echo "📥 Cloning plugin $repo..."
  clone_plugin_repo "$repo" "$tmp_dir"
  install_script="$tmp_dir/install.sh"

  [ -f "$install_script" ] || {
    echo "❌ install.sh not found for $repo" >&2
    return 1
  }

  prompt_plugin_env_updates "$repo" "$install_script"
  save_installed_plugin_repo "$repo"
  save_last_plugin_repo "$repo"

  trap - EXIT
  rm -rf "$tmp_dir"
  echo "✅ Plugin config saved: $repo"
}

update_plugin() {
  local repo="$1"
  local tmp_dir
  local install_script

  if [ -z "$repo" ]; then
    repo="$(prompt_for_installed_plugin_repo)"
  fi

  is_valid_repo "$repo" || {
    echo "❌ Invalid repository format: $repo" >&2
    return 1
  }

  tmp_dir="$(mktemp -d /tmp/pi-plugin-update.XXXXXX)"
  trap 'rm -rf "$tmp_dir"' EXIT

  echo "📥 Cloning plugin $repo..."
  clone_plugin_repo "$repo" "$tmp_dir"
  install_script="$tmp_dir/install.sh"

  [ -f "$install_script" ] || {
    echo "❌ install.sh not found for $repo" >&2
    return 1
  }

  prompt_plugin_env_updates "$repo" "$install_script"

  echo "🚀 Running install.sh..."
  run_plugin_installer "$tmp_dir" "$repo"
  save_installed_plugin_repo "$repo"
  save_last_plugin_repo "$repo"

  trap - EXIT
  rm -rf "$tmp_dir"
  echo "✅ Plugin updated: $repo"
}
