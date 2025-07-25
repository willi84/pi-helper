#!/bin/bash
set -e

REPO="${REPO:-willi84/pi-helper}"
INSTALL_DIR="$HOME/.pi-helper"
BIN_DIR="$INSTALL_DIR/bin"
LINK_NAME="pi"
LINK_TARGET="/usr/local/bin/$LINK_NAME"

echo "📥 Klone $REPO nach $INSTALL_DIR..."
rm -rf "$INSTALL_DIR"
git clone --depth=1 "https://github.com/$REPO.git" "$INSTALL_DIR"

echo "🔧 Setze Ausführrechte..."
chmod +x "$BIN_DIR"/*

echo "🔗 Erstelle Symlink $LINK_TARGET → $BIN_DIR/$LINK_NAME..."
sudo ln -sf "$BIN_DIR/$LINK_NAME" "$LINK_TARGET"

echo "✅ Installation abgeschlossen. Beispiel:"
echo "   $LINK_NAME install flask"
