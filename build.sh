#!/bin/sh
# Build entry point for Linux / macOS
#   Linux : ./build.sh [deb|rpm|appimage|all]
#   macOS : QTDIR=$HOME/Qt/6.5.3/macos ./build.sh
set -e
cd "$(dirname "$0")"
case "$(uname -s)" in
  Linux)  sh packaging/linux/build-linux.sh "${1:-all}" ;;
  Darwin) sh packaging/macos/build-macos.sh ;;
  *) echo "On Windows, use build.bat."; exit 1 ;;
esac
