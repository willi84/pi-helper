#!/bin bats

setup() {
  home_dir="$(mktemp -d /tmp/pi-helper-plugin-update-home.XXXXXX)"
  repo_root="$home_dir/repo"
  src_bin_dir="$repo_root/bin"
  src_lib_dir="$repo_root/lib"
  fake_bin_dir="$home_dir/fake-bin"
  install_log="$home_dir/install.log"
  plugin_config_dir="$home_dir/.local/share/pi/config/plugins"
  plugin_state_dir="$home_dir/.local/share/pi/state/plugins"

  mkdir -p "$src_bin_dir" "$src_lib_dir" "$fake_bin_dir" "$plugin_config_dir" "$plugin_state_dir"
  cp "$BATS_TEST_DIRNAME/../bin/plugin-update" "$src_bin_dir/plugin-update"
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
cat <<EOT > "$HOME/install.log"
APP_PORT=${APP_PORT:-missing}
APP_HOST=${APP_HOST:-missing}
EOT
EOS
chmod +x "$target_dir/install.sh"
exit 0
EOF

  chmod +x "$src_bin_dir/plugin-update" "$fake_bin_dir/git"
}

teardown() {
  rm -rf "$home_dir"
}

@test "🧪 plugin-update uses defaults when values are kept" {
  printf 'willi84/test-pi\n' > "$plugin_config_dir/installed-plugins"

  run bash -c "printf '1\n\n\n' | env HOME='$home_dir' PATH='$fake_bin_dir:$PATH' bash '$src_bin_dir/plugin-update'"

  [ "$status" -eq 0 ]
  run cat "$install_log"
  [ "$status" -eq 0 ]
  [[ "$output" == *"APP_PORT=3000"* ]]
  [[ "$output" == *"APP_HOST=localhost"* ]]
}

@test "🧪 plugin-update asks for repo when no plugin is stored" {
  run bash -c "printf 'willi84/test-pi\n\n\n' | env HOME='$home_dir' PATH='$fake_bin_dir:$PATH' bash '$src_bin_dir/plugin-update'"

  [ "$status" -eq 0 ]
  run cat "$install_log"
  [ "$status" -eq 0 ]
  [[ "$output" == *"APP_PORT=3000"* ]]
  [[ "$output" == *"APP_HOST=localhost"* ]]
}

@test "🧪 plugin-update shows saved values and allows changing them" {
  cat <<'EOF' > "$plugin_config_dir/installed-plugins"
willi84/other-pi
willi84/test-pi
EOF
  cat <<'EOF' > "$plugin_state_dir/willi84_test-pi.env"
APP_PORT=8080
APP_HOST=old-host
EOF

  run bash -c "printf '2\n\nexample.local\n' | env HOME='$home_dir' PATH='$fake_bin_dir:$PATH' bash '$src_bin_dir/plugin-update'"

  [ "$status" -eq 0 ]
  run cat "$install_log"
  [ "$status" -eq 0 ]
  [[ "$output" == *"APP_PORT=8080"* ]]
  [[ "$output" == *"APP_HOST=example.local"* ]]
  run cat "$plugin_state_dir/willi84_test-pi.env"
  [ "$status" -eq 0 ]
  [[ "$output" == *"APP_PORT=8080"* ]]
  [[ "$output" == *"APP_HOST=example.local"* ]]
}
