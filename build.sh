#!/bin/sh
# Build a flashable zip for KernelSU / Magisk.
# Usage: sh build.sh
set -eu

MODDIR=$(cd "$(dirname "$0")" && pwd)
cd "$MODDIR"

VERSION=$(sed -n 's/^version=//p' module.prop | head -n1)
VERSION=${VERSION#v}
OUT="cepheus-gaming-tweaks-v${VERSION}.zip"

FILES="module.prop service.sh tweak.conf uninstall.sh customize.sh gamelist.txt README.md webroot META-INF"

echo ">> building $OUT"
rm -f "$OUT"
zip -r9 "$OUT" $FILES >/dev/null
echo ">> done: $MODDIR/$OUT"
unzip -l "$OUT"
