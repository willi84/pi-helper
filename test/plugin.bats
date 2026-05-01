#!/bin bats

setup() {
  source "$BATS_TEST_DIRNAME/../lib/plugin.sh"
  home_dir="$(mktemp -d /tmp/pi-helper-plugin-home.XXXXXX)"
  repo_root="$home_dir/repo"
  src_bin_dir="$repo_root/bin"
  src_lib_dir="$repo_root/lib"
  src_config_dir="$repo_root/config"
  fake_bin_dir="$home_dir/fake-bin"
  install_log="$home_dir/install.log"

  mkdir -p "$src_bin_dir" "$src_lib_dir" "$src_config_dir" "$fake_bin_dir"
  cp "$BATS_TEST_DIRNAME/../bin/plugin" "$src_bin_dir/plugin"
  cp "$BATS_TEST_DIRNAME/../lib/index.sh" "$src_lib_dir/index.sh"
  cp "$BATS_TEST_DIRNAME/../lib/tools.sh" "$src_lib_dir/tools.sh"
  cp "$BATS_TEST_DIRNAME/../lib/show.sh" "$src_lib_dir/show.sh"
  cp "$BATS_TEST_DIRNAME/../lib/extract.sh" "$src_lib_dir/extract.sh"
  cp "$BATS_TEST_DIRNAME/../lib/plugin.sh" "$src_lib_dir/plugin.sh"
  touch "$repo_root/.project-root"

  cat <<'EOF' > "$fake_bin_dir/git"
#!/bin/bash
target_dir="${@: -1}"
mkdir -p "$target_dir"
cat <<'EOS' > "$target_dir/install.sh"
#!/bin/bash
cat <<EOT > "$HOME/install.log"
PLUGIN_REPO=${PLUGIN_REPO:-missing}
PLUGIN_REPO_PATH=${PLUGIN_REPO_PATH:-missing}
PLUGIN_REPO_URL=${PLUGIN_REPO_URL:-missing}
PLUGIN_REPO_GIT_URL=${PLUGIN_REPO_GIT_URL:-missing}
PLUGIN_REPO_RAW_BASE_URL=${PLUGIN_REPO_RAW_BASE_URL:-missing}
REPO=${REPO:-missing}
REPO_PATH=${REPO_PATH:-missing}
REPO_URL=${REPO_URL:-missing}
EOT
EOS
chmod +x "$target_dir/install.sh"
exit 0
EOF

  chmod +x "$src_bin_dir/plugin" "$fake_bin_dir/git"
}

teardown() {
  rm -rf "$home_dir"
}

@test "🧪 is_valid_repo accepts org repo format" {
  run is_valid_repo "user/project"

  [ "$status" -eq 0 ]
}

@test "🧪 plugin installs repo from parameter" {
  run env HOME="$home_dir" PATH="$fake_bin_dir:$PATH" PLUGIN_REPO="user/project" bash "$src_bin_dir/plugin" "user/project"

  [ "$status" -eq 0 ]
  [ -f "$install_log" ]
  run cat "$install_log"
  [ "$status" -eq 0 ]
  [[ "$output" == *"PLUGIN_REPO=user/project"* ]]
  [[ "$output" == *"PLUGIN_REPO_PATH=github.com/user/project"* ]]
  [[ "$output" == *"PLUGIN_REPO_URL=https://github.com/user/project"* ]]
  [[ "$output" == *"PLUGIN_REPO_GIT_URL=https://github.com/user/project.git"* ]]
  [[ "$output" == *"PLUGIN_REPO_RAW_BASE_URL=https://raw.githubusercontent.com/user/project/main"* ]]
  [[ "$output" == *"REPO=user/project"* ]]
  [[ "$output" == *"REPO_PATH=github.com/user/project"* ]]
  [[ "$output" == *"REPO_URL=https://github.com/user/project"* ]]
}

@test "🧪 plugin installs repo from template dialog" {
  cat <<'EOF' > "$src_config_dir/plugins.json"
{
  "plugins": [
    {
      "name": "Kiosk setup",
      "repo": "willi84/kiosk-pi",
      "description": "Kiosk setup"
    },
    {
      "name": "Test setup",
      "repo": "willi84/test-pi",
      "description": "Test setup"
    }
  ]
}
EOF

  run bash -c "printf '2\n' | env HOME='$home_dir' PATH='$fake_bin_dir:$PATH' PLUGIN_REPO='willi84/test-pi' bash '$src_bin_dir/plugin'"

  [ "$status" -eq 0 ]
  run cat "$install_log"
  [ "$status" -eq 0 ]
  [[ "$output" == *"PLUGIN_REPO=willi84/test-pi"* ]]
  [[ "$output" == *"PLUGIN_REPO_PATH=github.com/willi84/test-pi"* ]]
}

@test "🧪 prompt_for_plugin_repo returns only repo value" {
  cat <<'EOF' > "$src_config_dir/plugins.json"
{
  "plugins": [
    {
      "name": "Kiosk setup",
      "repo": "willi84/kiosk-pi",
      "description": "Kiosk setup"
    },
    {
      "name": "Test setup",
      "repo": "willi84/test-pi",
      "description": "Test setup"
    }
  ]
}
EOF

  dialog_stderr="$home_dir/dialog.stderr"
  run bash -c "source '$src_bin_dir/plugin'; CONFIG_FILE='$src_config_dir/plugins.json'; printf '2\n' | prompt_for_plugin_repo 2>'$dialog_stderr'"

  [ "$status" -eq 0 ]
  [ "$output" = "willi84/test-pi" ]
}

@test "🧪 plugin installs repo from manual dialog input" {
  cat <<'EOF' > "$src_config_dir/plugins.json"
{
  "plugins": [
    {
      "name": "Kiosk setup",
      "repo": "willi84/kiosk-pi",
      "description": "Kiosk setup"
    }
  ]
}
EOF

  run bash -c "printf '2\ncustom/pi-project\n' | env HOME='$home_dir' PATH='$fake_bin_dir:$PATH' PLUGIN_REPO='custom/pi-project' bash '$src_bin_dir/plugin'"

  [ "$status" -eq 0 ]
  run cat "$install_log"
  [ "$status" -eq 0 ]
  [[ "$output" == *"PLUGIN_REPO=custom/pi-project"* ]]
  [[ "$output" == *"PLUGIN_REPO_PATH=github.com/custom/pi-project"* ]]
}
