#!/bin/bash
set -e

echo "🧹 Uninstalling pi-helper..."

rm -rf "$HOME/.pi-helper-src"
rm -rf "$HOME/.local/share/pi"
sudo rm -f /usr/local/bin/pi

echo "✅ Uninstalled pi-helper."
