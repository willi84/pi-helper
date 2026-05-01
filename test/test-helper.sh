#!/bin/bash

assert_equal_multiline() {
  local expected="$1"
  local actual="$2"

  if [ "$expected" != "$actual" ]; then
    echo "❌ Output mismatch:"
    diff -u <(printf '%s' "$expected") <(printf '%s' "$actual")
    return 1
  fi
}

setup_tools_dir_mock() {
  mock_root="$(mktemp -d /tmp/pi-helper-test.XXXXXX)"
  mock_tools_dir_path="$mock_root/lib"

  mkdir -p "$mock_tools_dir_path"
  touch "$mock_root/.project-root"

  get_tools_dir() {
    echo "$mock_tools_dir_path"
  }
}

cleanup_tools_dir_mock() {
  rm -rf "$mock_root"
}
