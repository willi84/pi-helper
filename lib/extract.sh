#!/bin/bash

# 🎯 get value of a comment metadata key like:
# # DESC: Foo
# # NAME: Bar
get_comment_meta_from_content() {
  local content="$1"
  local key="$2"

  [ -n "$key" ] || {
    echo "❌ Key fehlt" >&2
    return 1
  }

  local value
  value=$(printf '%s\n' "$content" | awk -v key="$key" '
    BEGIN { pattern = "^# " key ":" }
    $0 ~ pattern {
      sub(pattern "[ ]*", "")
      print
      exit
    }
  ')

  if [ -z "$value" ]; then
    return 2
  fi

  echo "$value"
}

get_comment_meta() {
  local file="$1"
  local key="$2"

  [ -f "$file" ] || {
    echo "❌ Datei nicht gefunden: $file" >&2
    return 1
  }

  [ -n "$key" ] || {
    echo "❌ Key fehlt" >&2
    return 1
  }

  local content
  content="$(cat "$file")"

  get_comment_meta_from_content "$content" "$key"
}

# 🎯 get description of the comments
get_description() {
  get_comment_meta "$1" "DESC"
}
