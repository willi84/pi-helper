#!/bin/bash
set -e

REPO="${REPO:-willi84/pi-helper}"
SRC_DIR="$HOME/.pi-helper-src"
INSTALL_DIR="$HOME/.local/share/pi"
BIN_DIR="$INSTALL_DIR/bin"
LINK_PATH="/usr/local/bin/pi"

echo "📥 Cloning $REPO into $SRC_DIR..."
rm -rf "$SRC_DIR"
git clone --depth=1 "https://github.com/$REPO.git" "$SRC_DIR"

echo "🔧 Copying scripts to $BIN_DIR..."
mkdir -p "$BIN_DIR"
cp "$SRC_DIR/bin/"* "$BIN_DIR/"

echo "📜 Setting executable bits..."
chmod +x "$BIN_DIR/"*

echo "🔗 Linking to $LINK_PATH..."
sudo ln -sf "$BIN_DIR/pi" "$LINK_PATH"

echo "✅ Installed successfully. Try:"
echo "   pi help"
