#!/bin/sh
# Usage: QTDIR=$HOME/Qt/6.5.3/macos packaging/macos/build-macos.sh
# Use Qt 6.5 LTS to support macOS 11 (Qt 6.8 and later require macOS 12+).
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION="1.0.0"
QT="${QTDIR:-$HOME/Qt/6.5.3/macos}"
export PATH="$QT/bin:$PATH"
BUILD="$ROOT/build/macos"; DIST="$ROOT/dist"
rm -rf "$BUILD"; mkdir -p "$BUILD" "$DIST"
cd "$BUILD"
qmake "$ROOT/Mixdown.pro" CONFIG+=release
make -j"$(sysctl -n hw.ncpu)"
macdeployqt Mixdown.app
codesign --force --deep -s - Mixdown.app          # ad-hoc signature (the minimum needed to run on Apple Silicon)
hdiutil create -volname Mixdown -srcfolder Mixdown.app -ov -format UDZO "$DIST/Mixdown-$VERSION-mac.dmg"
echo "Done: $DIST/Mixdown-$VERSION-mac.dmg"
