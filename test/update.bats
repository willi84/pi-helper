#!/bin bats

@test "🧪 update copies lib files and replaces update last" {
    home_dir="$(mktemp -d /tmp/pi-helper-update-home.XXXXXX)"
    src_dir="$home_dir/.pi-helper-src"
    install_dir="$home_dir/.local/share/pi"
    bin_dir="$install_dir/bin"
    lib_dir="$install_dir/lib"
    fake_bin_dir="$home_dir/fake-bin"

    mkdir -p "$src_dir/bin" "$src_dir/lib" "$bin_dir" "$fake_bin_dir"

    cat <<'EOF' > "$src_dir/bin/help"
#!/bin/bash
echo help
EOF

    cat <<'EOF' > "$src_dir/bin/update"
#!/bin/bash
echo new-update
EOF

    cat <<'EOF' > "$src_dir/lib/index.sh"
#!/bin/bash
echo lib
EOF

    cat <<'EOF' > "$bin_dir/update"
#!/bin/bash
echo old-update
EOF

    cat <<'EOF' > "$fake_bin_dir/git"
#!/bin/bash
exit 0
EOF

    chmod +x "$src_dir/bin/help" "$src_dir/bin/update" "$src_dir/lib/index.sh" "$bin_dir/update" "$fake_bin_dir/git"

    run env HOME="$home_dir" PATH="$fake_bin_dir:$PATH" bash "$BATS_TEST_DIRNAME/../bin/update"

    [ "$status" -eq 0 ]
    [ -f "$lib_dir/index.sh" ]
    [ -x "$bin_dir/help" ]
    [ -x "$bin_dir/update" ]
    run cat "$bin_dir/update"
    [ "$output" = "#!/bin/bash
echo new-update" ]

    rm -rf "$home_dir"
}

@test "🧪 update swaps its own script atomically" {
    home_dir="$(mktemp -d /tmp/pi-helper-update-atomic.XXXXXX)"
    src_dir="$home_dir/.pi-helper-src"
    install_dir="$home_dir/.local/share/pi"
    bin_dir="$install_dir/bin"
    lib_dir="$install_dir/lib"
    fake_bin_dir="$home_dir/fake-bin"

    mkdir -p "$src_dir/bin" "$src_dir/lib" "$bin_dir" "$fake_bin_dir"

    cat <<'EOF' > "$src_dir/bin/help"
#!/bin/bash
echo help
EOF

    cat <<'EOF' > "$src_dir/bin/update"
#!/bin/bash
echo new-update
EOF

    cat <<'EOF' > "$src_dir/lib/index.sh"
#!/bin/bash
echo lib
EOF

    cat <<'EOF' > "$fake_bin_dir/git"
#!/bin/bash
exit 0
EOF

    cp "$BATS_TEST_DIRNAME/../bin/update" "$bin_dir/update"

    chmod +x "$src_dir/bin/help" "$src_dir/bin/update" "$src_dir/lib/index.sh" "$bin_dir/update" "$fake_bin_dir/git"

    run env HOME="$home_dir" PATH="$fake_bin_dir:$PATH" bash "$bin_dir/update"

    [ "$status" -eq 0 ]
    [ -f "$lib_dir/index.sh" ]
    [ -x "$bin_dir/help" ]
    [ -x "$bin_dir/update" ]
    [ ! -e "$bin_dir/update.tmp" ]
    run cat "$bin_dir/update"
    [ "$output" = "#!/bin/bash
echo new-update" ]

    rm -rf "$home_dir"
}
