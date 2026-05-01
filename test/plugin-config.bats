#!/bin bats

setup() {
  home_dir="$(mktemp -d /tmp/pi-helper-plugin-config-home.XXXXXX)"
  repo_root="$home_dir/repo"
  src_bin_dir="$repo_root/bin"
  src_lib_dir="$repo_root/lib"
  fake_bin_dir="$home_dir/fake-bin"
  install_log="$home_dir/install.log"
  plugin_config_dir="$home_dir/.local/share/pi/config/plugins"
  plugin_state_dir="$home_dir/.local/share/pi/state/plugins"
  systemctl_log="$home_dir/systemctl.log"
  active_services_file="$home_dir/active-services"

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

  cat <<'EOF' > "$fake_bin_dir/sudo"
#!/bin/bash
if [ "$1" = "-n" ]; then
  shift
fi
"$@"
EOF

  cat <<'EOF' > "$fake_bin_dir/systemctl"
#!/bin/bash
log_file="${SYSTEMCTL_LOG:?}"
active_file="${ACTIVE_SERVICES_FILE:?}"

if [ "$1" = "--user" ]; then
  shift
fi

cmd="$1"

if [ "$cmd" = "is-active" ] && [ "$2" = "--quiet" ]; then
  service="$3"
else
  service="$2"
fi

case "$cmd" in
  is-active)
    grep -Fxq "$service" "$active_file"
    ;;
  restart)
    printf 'restart %s\n' "$service" >> "$log_file"
    ;;
  *)
    exit 1
    ;;
esac
EOF

  chmod +x "$src_bin_dir/plugin-config" "$fake_bin_dir/git"
  chmod +x "$fake_bin_dir/sudo" "$fake_bin_dir/systemctl"
  : > "$install_log"
  : > "$systemctl_log"
  : > "$active_services_file"
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

  run bash -c "printf '2\n\nexample.local\n' | env HOME='$home_dir' PATH='$fake_bin_dir:$PATH' SYSTEMCTL_LOG='$systemctl_log' ACTIVE_SERVICES_FILE='$active_services_file' bash '$src_bin_dir/plugin-config'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Plugin config saved: willi84/test-pi"* ]]
  [[ "$output" == *"Config path: $plugin_state_dir/willi84_test-pi.env"* ]]
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

  run bash -c "printf '1\n9090\n\n' | env HOME='$home_dir' PATH='$fake_bin_dir:$PATH' SYSTEMCTL_LOG='$systemctl_log' ACTIVE_SERVICES_FILE='$active_services_file' bash '$src_bin_dir/plugin-config'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Plugin config saved: willi84/test-pi"* ]]
  run cat "$plugin_state_dir/willi84_test-pi.env"
  [ "$status" -eq 0 ]
  [[ "$output" == *"APP_PORT=9090"* ]]
  [[ "$output" == *"APP_HOST=old-host"* ]]
}

@test "🧪 plugin-config reads variables from plugin config env file" {
  cat <<'EOF' > "$plugin_config_dir/installed-plugins"
willi84/kiosk-pi
EOF
  cat <<'EOF' > "$fake_bin_dir/git"
#!/bin/bash
target_dir="${@: -1}"
mkdir -p "$target_dir"
cat <<'EOS' > "$target_dir/install.sh"
#!/bin/bash
echo "loading kiosk-config.env"
EOS
cat <<'EOS' > "$target_dir/kiosk-config.env"
KIOSK_HOSTNAME="<HOSTNAME>"
KIOSK_URL="https://bahn.dev/"
WIFI_SSID="<SSID>"
WIFI_PASSWORD="<PASSWORD>"
WIFI_HIDDEN="false"
EOS
chmod +x "$target_dir/install.sh"
exit 0
EOF
  chmod +x "$fake_bin_dir/git"

  run bash -c "printf '1\ninfo-screen\n\nOfficeWiFi\nsecret123\ntrue\n' | env HOME='$home_dir' PATH='$fake_bin_dir:$PATH' SYSTEMCTL_LOG='$systemctl_log' ACTIVE_SERVICES_FILE='$active_services_file' bash '$src_bin_dir/plugin-config'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Plugin config saved: willi84/kiosk-pi"* ]]
  [[ "$output" == *"Config path: $plugin_state_dir/willi84_kiosk-pi.env"* ]]
  [[ "$output" == *"Active plugin parameters:"* ]]
  [[ "$output" == *"KIOSK_URL=https://bahn.dev/"* ]]
  run cat "$plugin_state_dir/willi84_kiosk-pi.env"
  [ "$status" -eq 0 ]
  [[ "$output" == *"KIOSK_HOSTNAME=info-screen"* ]]
  [[ "$output" == *"KIOSK_URL=https://bahn.dev/"* ]]
  [[ "$output" == *"WIFI_SSID=OfficeWiFi"* ]]
  [[ "$output" == *"WIFI_PASSWORD=secret123"* ]]
  [[ "$output" == *"WIFI_HIDDEN=true"* ]]
}

@test "🧪 plugin-config restarts detected running service after config change" {
  cat <<'EOF' > "$plugin_config_dir/installed-plugins"
willi84/kiosk-pi
EOF
  printf 'kiosk-display.service\n' > "$active_services_file"
  cat <<'EOF' > "$fake_bin_dir/git"
#!/bin/bash
target_dir="${@: -1}"
mkdir -p "$target_dir"
cat <<'EOS' > "$target_dir/install.sh"
#!/bin/bash
echo "loading kiosk-config.env"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/kiosk-config.env"
cat <<EOT > "$HOME/install.log"
KIOSK_URL=${KIOSK_URL:-missing}
EOT
EOS
cat <<'EOS' > "$target_dir/setup-kiosk.sh"
#!/bin/bash
sudo tee /etc/systemd/system/kiosk-display.service >/dev/null <<EOF2
[Unit]
Description=Kiosk Display
EOF2
sudo systemctl restart kiosk-display
EOS
cat <<'EOS' > "$target_dir/kiosk-config.env"
KIOSK_URL="https://bahn.dev/"
EOS
chmod +x "$target_dir/install.sh"
exit 0
EOF
  chmod +x "$fake_bin_dir/git"

  run bash -c "printf '1\nhttps://example.org/\n' | env HOME='$home_dir' PATH='$fake_bin_dir:$PATH' SYSTEMCTL_LOG='$systemctl_log' ACTIVE_SERVICES_FILE='$active_services_file' bash '$src_bin_dir/plugin-config'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Re-running install.sh for config changes..."* ]]
  [[ "$output" == *"Synced plugin env file:"* ]]
  [[ "$output" == *"Detected plugin services:"* ]]
  [[ "$output" == *"Checking service: kiosk-display.service"* ]]
  [[ "$output" == *"Restarted service: kiosk-display.service"* ]]
  [[ "$output" == *"KIOSK_URL=https://example.org/"* ]]
  run cat "$install_log"
  [ "$status" -eq 0 ]
  [[ "$output" == *"KIOSK_URL=https://example.org/"* ]]
  run cat "$systemctl_log"
  [ "$status" -eq 0 ]
  [[ "$output" == *"restart kiosk-display.service"* ]]
}

@test "🧪 plugin-config reads inline env assignments with URL defaults" {
  cat <<'EOF' > "$plugin_config_dir/installed-plugins"
willi84/kiosk-pi
EOF
  cat <<'EOF' > "$fake_bin_dir/git"
#!/bin/bash
target_dir="${@: -1}"
mkdir -p "$target_dir"
cat <<'EOS' > "$target_dir/install.sh"
#!/bin/bash
echo "loading kiosk-config.env"
EOS
cat <<'EOS' > "$target_dir/kiosk-config.env"
KIOSK_HOSTNAME="<HOSTNAME>" KIOSK_URL="https://bahn.dev/" WIFI_SSID="<SSID>" WIFI_PASSWORD="<PASSWORD>" WIFI_HIDDEN="false"
EOS
chmod +x "$target_dir/install.sh"
exit 0
EOF
  chmod +x "$fake_bin_dir/git"

  run bash -c "printf '1\ninfo-screen\nhttps://example.org/screen\nOfficeWiFi\nsecret123\ntrue\n' | env HOME='$home_dir' PATH='$fake_bin_dir:$PATH' SYSTEMCTL_LOG='$systemctl_log' ACTIVE_SERVICES_FILE='$active_services_file' bash '$src_bin_dir/plugin-config'"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Plugin config saved: willi84/kiosk-pi"* ]]
  [[ "$output" == *"KIOSK_URL=https://example.org/screen"* ]]
  run cat "$plugin_state_dir/willi84_kiosk-pi.env"
  [ "$status" -eq 0 ]
  [[ "$output" == *"KIOSK_HOSTNAME=info-screen"* ]]
  [[ "$output" == *"KIOSK_URL=https://example.org/screen"* ]]
  [[ "$output" == *"WIFI_SSID=OfficeWiFi"* ]]
  [[ "$output" == *"WIFI_PASSWORD=secret123"* ]]
  [[ "$output" == *"WIFI_HIDDEN=true"* ]]
}
