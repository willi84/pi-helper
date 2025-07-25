#!/bin/bash
set -e

VERSION=$(./version.sh)
PART="${1:-patch}"

IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

case "$PART" in
  major)
    ((MAJOR++)); MINOR=0; PATCH=0 ;;
  minor)
    ((MINOR++)); PATCH=0 ;;
  patch)
    ((PATCH++)) ;;
  *)
    echo "❌ Invalid version bump: use major, minor or patch"
    exit 1 ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo "$NEW_VERSION" > version.tmp
echo "echo "$NEW_VERSION"" > version.sh
chmod +x version.sh

./changelog.sh
git add CHANGELOG.md version.sh
git commit -m "chore: release v$NEW_VERSION"
git tag "v$NEW_VERSION"
git push && git push --tags

echo "🚀 Released v$NEW_VERSION"
