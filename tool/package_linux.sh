#!/bin/sh
# Packs the Linux release build into dist/RealLife-RPG-linux-x64.tar.gz.
# Run from the repository root after: flutter build linux --release
set -eu
OUT=dist/RealLife-RPG-linux-x64
rm -rf "$OUT" "$OUT.tar.gz"
mkdir -p "$OUT"
cp -R build/linux/x64/release/bundle "$OUT/bundle"
cp packaging/linux/install.sh packaging/linux/OKU-BENI.txt packaging/linux/reallife-rpg.png "$OUT/"
tar -C dist -czf "$OUT.tar.gz" RealLife-RPG-linux-x64
echo "$OUT.tar.gz"
