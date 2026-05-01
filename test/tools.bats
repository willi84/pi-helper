setup() {
  source "$BATS_TEST_DIRNAME/test-helper.sh"
  source "$BATS_TEST_DIRNAME/../lib/tools.sh"
  setup_tools_dir_mock
}

teardown() {
  cleanup_tools_dir_mock
}

@test "🧪 get_project_root finds project root" {
    expected="$mock_root"
    actual="$(get_project_root)"

    assert_equal_multiline "$expected" "$actual"
}

@test "🧪 get_project_root returns error if root not found" {
    rm -rf "$mock_root/.project-root"

    run get_project_root

    [ "$status" -ne 0 ]
    [[ "$output" == *"❌ Project root nicht gefunden"* ]]
}

@test "🧪 get_lib_dir finds lib directory" {
    expected="$mock_root/lib"
    actual="$(get_lib_dir)"

    assert_equal_multiline "$expected" "$actual"
}

@test "🧪 get_lib_dir returns error if lib directory not found" {
    rm -rf "$mock_root/lib"

    run get_lib_dir

    [ "$status" -ne 0 ]
    [[ "$output" == *"❌ lib-Verzeichnis nicht gefunden"* ]]
}

@test "🧪 is_executable returns true for executable file" {
    file="$mock_root/executable.sh"
    touch "$file"
    chmod +x "$file"

    run is_executable "$file"

    [ "$status" -eq 0 ]
}
