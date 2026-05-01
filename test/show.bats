#!/bin bats

setup() {
  source "$BATS_TEST_DIRNAME/test-helper.sh"
  source "$BATS_TEST_DIRNAME/../lib/show.sh"
}

@test "🧪 display_key_value formats key and value correctly" {
    expected="  key             value"
    actual="$(display_key_value "key" "value")"

    assert_equal_multiline "$expected" "$actual"
}

@test "🧪 display_headline prints exact output" {
    expected="$(printf '\n📦 a headline:\n\nx')"
    expected="${expected%x}"
    actual="$(display_headline "📦 a headline"; printf x)"
    actual="${actual%x}"

    assert_equal_multiline "$expected" "$actual"
}

