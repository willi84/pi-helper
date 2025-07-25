#!/bin/bash
set -e

VERSION=$(./version.sh)
DATE=$(date +"%Y-%m-%d")
CHANGELOG="CHANGELOG.md"
TMP="CHANGELOG.tmp"

LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
COMMITS=$(git log --pretty=format:"%s" "$LAST_TAG"..HEAD)

if [ -z "$COMMITS" ]; then
  echo "⚠️ No new commits since $LAST_TAG"
  exit 0
fi

{
  echo "## v$VERSION – $DATE"
  echo
} > "$TMP"

declare -A TYPES=(
  [feat]="✨ Features"
  [fix]="🐛 Fixes"
  [chore]="🧹 Chores"
  [docs]="📝 Docs"
  [refactor]="♻️ Refactoring"
  [test]="🧪 Tests"
  [ci]="⚙️ CI"
  [style]="🎨 Style"
)

for type in "${!TYPES[@]}"; do
  MATCHED=$(echo "$COMMITS" | grep -iE "^$type\s*:" || true)
  if [ -n "$MATCHED" ]; then
    echo "### ${TYPES[$type]}" >> "$TMP"
    echo "$MATCHED" | sed -E "s/^$type\s*:\s*/- /I" >> "$TMP"
    echo >> "$TMP"
  fi
done

OTHER=$(echo "$COMMITS" | grep -vE "^(feat|fix|chore|docs|refactor|test|ci|style)\s*:" || true)
if [ -n "$OTHER" ]; then
  echo "### 🗃 Other Changes" >> "$TMP"
  echo "$OTHER" | sed -E 's/^/- /' >> "$TMP"
  echo >> "$TMP"
fi

cat "$CHANGELOG" >> "$TMP"
mv "$TMP" "$CHANGELOG"

echo "✅ CHANGELOG.md updated for version $VERSION"
