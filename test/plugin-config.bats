#!/bin bats

setup() {
  home_dir="$(mktemp -d /tmp/pi-helper-plugin-config-home.XXXXXX)"
  repo_root="$home_dir/repo"
  src_bin_dir="$repo_root/bin"
  src_lib_dir="$repo_root/lib"
  fake_bin_dir="$home_dir/fake-bin"
  plugin_config_dir="$home_dir/.local/share/pi/config/plugins"
  plugin_state_dir="$home_dir/.local/share/pi/state/plugins"

  mkdir -p "$src_bin_dir" "$src_lib_dir" "$fake_bin_dir" "$plugin_config_dir" "$plugin_state_dir"
  cp "$BATS_TEST_DIRNAME/../bin/plugin-config" "$src_bin_dir/plugin-config"
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
APP_PORT="${APP_PORT:-3000}"
APP_HOST="${APP_HOST:-localhost}"
EOS
chmod +x "$target_dir/install.sh"
exit 0
EOF

  chmod +x "$src_bin_dir/plugin-config" "$fake_bin_dir/git"
}

teardown() {
  rm -rf "$home_dir"
}

@test "🧪 plugin-config lets user change saved values for selected plugin" {
  cat <<'EOF' > "$plugin_config_dir/installed-plugins"
willi84/first-pi
willi84/test-pi
EOF
  cat <<'EOF' > "$plugin_state_dir/willi84_test-pi.env"
APP_PORT=8080
APP_HOST=old-host
EOF

  run bash -c "printf '2\n\nexample.local\n' | env HOME='$home_dir' PATH='$fake_bin_dir:$PATH' bash '$src_bin_dir/plugin-config'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Plugin config saved: willi84/test-pi"* ]]
  run cat "$plugin_state_dir/willi84_test-pi.env"
  [ "$status" -eq 0 ]
  [[ "$output" == *"APP_PORT=8080"* ]]
  [[ "$output" == *"APP_HOST=example.local"* ]]
}

@test "🧪 plugin-config shows saved env keys when install script has no defaults" {
  cat <<'EOF' > "$plugin_config_dir/installed-plugins"
willi84/test-pi
EOF
  cat <<'EOF' > "$plugin_state_dir/willi84_test-pi.env"
APP_PORT=8080
APP_HOST=old-host
EOF
  cat <<'EOF' > "$fake_bin_dir/git"
#!/bin/bash
target_dir="${@: -1}"
mkdir -p "$target_dir"
cat <<'EOS' > "$target_dir/install.sh"
#!/bin/bash
echo "${APP_PORT}"
echo "${APP_HOST}"
EOS
chmod +x "$target_dir/install.sh"
exit 0
EOF
  chmod +x "$fake_bin_dir/git"

  run bash -c "printf '1\n9090\n\n' | env HOME='$home_dir' PATH='$fake_bin_dir:$PATH' bash '$src_bin_dir/plugin-config'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Plugin config saved: willi84/test-pi"* ]]
  run cat "$plugin_state_dir/willi84_test-pi.env"
  [ "$status" -eq 0 ]
  [[ "$output" == *"APP_PORT=9090"* ]]
  [[ "$output" == *"APP_HOST=old-host"* ]]
}
