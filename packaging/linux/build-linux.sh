#!/bin/sh
# Usage: packaging/linux/build-linux.sh [deb|rpm|appimage|all]
# Requires: Qt 6.2+ (qmake6 and the WebEngine/WebChannel development packages), make, g++
#           deb -> dpkg-deb    rpm -> rpmbuild    appimage -> curl (downloads linuxdeploy)
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION="1.0.0"
LICENSE_NAME="${LICENSE_NAME:-Proprietary}"     # rpm License field - set your real license
MAINTAINER="${MAINTAINER:-Mixdown <mixdown@example.com>}"
QMAKE="${QMAKE:-qmake6}"
command -v "$QMAKE" >/dev/null 2>&1 || QMAKE=qmake
WHAT="${1:-all}"
BUILD="$ROOT/build/linux"; STAGE="$ROOT/build/stage"; DIST="$ROOT/dist"
rm -rf "$BUILD" "$STAGE"; mkdir -p "$BUILD" "$STAGE" "$DIST"

( cd "$BUILD" && "$QMAKE" "$ROOT/Mixdown.pro" CONFIG+=release && make -j"$(nproc)" && make install INSTALL_ROOT="$STAGE" )

make_deb() {
  D="$ROOT/build/deb"; rm -rf "$D"; mkdir -p "$D/DEBIAN"; cp -a "$STAGE"/. "$D"/
  SIZE=$(du -sk "$D" | cut -f1)
  # Package names below are for Debian/Ubuntu. Adjust Depends for other distributions.
  cat > "$D/DEBIAN/control" <<CTL
Package: mixdown
Version: $VERSION
Section: editors
Priority: optional
Architecture: amd64
Installed-Size: $SIZE
Maintainer: $MAINTAINER
Depends: libqt6core6, libqt6gui6, libqt6widgets6, libqt6webenginewidgets6, libqt6webenginecore6, libqt6webchannel6
Description: Mixdown markup editor
 Markdown, LaTeX, CSS and a small JS subset in one markup language.
CTL
  dpkg-deb --build --root-owner-group "$D" "$DIST/mixdown_${VERSION}_amd64.deb"
}

make_rpm() {
  T="$ROOT/build/rpm"; rm -rf "$T"; mkdir -p "$T/BUILD" "$T/RPMS" "$T/SPECS" "$T/SRPMS"
  cat > "$T/SPECS/mixdown.spec" <<SPEC
Name: mixdown
Version: $VERSION
Release: 1
Summary: Mixdown markup editor
License: $LICENSE_NAME
%description
Markdown, LaTeX, CSS and a small JS subset in one markup language.
%install
mkdir -p %{buildroot}
cp -a $STAGE/. %{buildroot}/
%files
/usr/bin/mixdown
/usr/share/applications/mixdown.desktop
/usr/share/mime/packages/mixdown.xml
/usr/share/icons/hicolor/512x512/apps/mixdown.png
SPEC
  QA_RPATHS=63 rpmbuild --define "_topdir $T" --define "debug_package %{nil}" --define "_build_id_links none" -bb "$T/SPECS/mixdown.spec"
  cp "$T"/RPMS/*/mixdown-*.rpm "$DIST/"
}

make_appimage() {
  A="$ROOT/build/appimage"; rm -rf "$A"; mkdir -p "$A"; cd "$A"
  curl -L -o linuxdeploy https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
  curl -L -o linuxdeploy-plugin-qt https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage
  chmod +x linuxdeploy linuxdeploy-plugin-qt
  export PATH="$A:$PATH"                                   # linuxdeploy looks for its plugins on PATH
  export APPIMAGE_EXTRACT_AND_RUN=1                        # works without FUSE (CI, containers)
  export QMAKE="$(command -v "$QMAKE")" VERSION OUTPUT="Mixdown-$VERSION-x86_64.AppImage"
  export EXTRA_QT_MODULES="webenginewidgets;webchannel"   # may be unnecessary depending on the plugin version
  ./linuxdeploy --appdir AppDir --plugin qt \
    --executable "$STAGE/usr/bin/mixdown" \
    --desktop-file "$ROOT/packaging/linux/mixdown.desktop" \
    --icon-file "$ROOT/resources/icons/mixdown.png" \
    --output appimage
  mv ./Mixdown-*.AppImage "$DIST/"
}

case "$WHAT" in
  deb) make_deb ;;
  rpm) make_rpm ;;
  appimage) make_appimage ;;
  all) make_deb; make_rpm; make_appimage ;;
  *) echo "Usage: $0 [deb|rpm|appimage|all]"; exit 1 ;;
esac
echo "Done: $DIST"
