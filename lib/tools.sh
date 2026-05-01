#!/bin/bash

# 🎯 get path to the tools directory
get_tools_dir() {
  cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P
}

# 🎯 get path to the root
get_project_root() {
  local dir
  dir="$(get_tools_dir)"

  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.git" ] || [ -f "$dir/package.json" ] || [ -f "$dir/.project-root" ]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done

  echo "❌ Project root nicht gefunden" >&2
  return 1
}

# 🎯 get path to the library
get_lib_dir() {
  local root
  root="$(get_project_root)" || return 1

  local lib_dir="$root/lib"

  if [ ! -d "$lib_dir" ]; then
    echo "❌ lib-Verzeichnis nicht gefunden: $lib_dir" >&2
    return 2
  fi

  echo "$lib_dir"
}

# 🎯 check if a file is executable
is_executable() {
  local file="$1"
  [ -x "$file" ]
}
