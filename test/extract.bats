#!/bin/bash

setup() {
  source "$BATS_TEST_DIRNAME/test-helper.sh"
  source "$BATS_TEST_DIRNAME/../lib/extract.sh"

  extract_test_file="$(mktemp /tmp/pi-helper-extract.XXXXXX)"
  cat <<'EOF' > "$extract_test_file"
# DESC: Example description
# NAME: Example name
echo "hello"
EOF
}

teardown() {
  rm -f "$extract_test_file"
}

@test "🧪 get_comment_meta_from_content extracts comment metadata" {
    input="$(printf '# DESC: Example description\n# NAME: Example name\n')"
    expected="Example description"
    actual="$(get_comment_meta_from_content "$input" "DESC")"

    assert_equal_multiline "$expected" "$actual"
}

@test "🧪 get_comment_meta reads metadata from file content" {
    expected="Example name"
    actual="$(get_comment_meta "$extract_test_file" "NAME")"

    assert_equal_multiline "$expected" "$actual"
}
