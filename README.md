# Mixdown (Qt)

An installable desktop version of the **Mixdown** editor, a markup language that mixes Markdown, simplified LaTeX,
simplified CSS and a small JS subset in a single document.

The web editor (`resources/index.html`) is wrapped in Qt WebEngine. Opening/saving `.mxd` files, file association and
the menus are handled in C++ (Qt). **The same source builds with Qt 5.15 and Qt 6.**

## Supported systems and Qt versions

| Target | Qt | Installer |
|---|---|---|
| Windows 7 SP1 / 8 / 8.1 (64-bit) | **Qt 5.15** (MSVC 2019 64-bit) | `Mixdown-1.0.0-win-qt5-setup.exe` |
| Windows 10 (1809) or later (64-bit) | Qt 6.5 LTS (MSVC 2019 64-bit) | `Mixdown-1.0.0-win-qt6-setup.exe` |
| macOS 11 or later (Intel + Apple Silicon) | Qt 6.5 LTS | `Mixdown-1.0.0-mac.dmg` |
| Linux x86_64 | Qt 6.2 or later | `.deb`, `.rpm`, `.AppImage` |

- To support macOS 11, use Qt **6.5 LTS** (Qt 6.8 and later require macOS 12+).
- On Windows, Qt WebEngine only supports **MSVC kits** (MinGW is not possible).

## Project layout

```
Mixdown.pro                  qmake project (shared by Qt 5 and Qt 6)
src/                         C++ sources (main, mainwindow, bridge)
resources/index.html         the web editor (embedded via qrc)
packaging/windows/           Inno Setup script (.iss)
packaging/linux/             .desktop, MIME type, deb/rpm/AppImage script
packaging/macos/             Info.plist, dmg script
build.sh / build.bat         build entry points per OS
tools/make_icons.py          regenerates the icons (Pillow)
```

## Easiest: build in the cloud (nothing to install, no Visual Studio)

`.github/workflows/build.yml` builds every installer on GitHub's servers, which already have the compilers.

1. Create a GitHub repository and upload the contents of this folder (including the hidden `.github` folder).
2. Open the **Actions** tab -> **Build installers** -> **Run workflow**.
3. When it finishes (roughly 20-40 minutes), download the installers from the run's **Artifacts**
   (Windows Qt 5 / Windows Qt 6 / macOS / Linux). Pushing a tag such as `v1.0.0` also attaches them to a GitHub release.

This is free for public repositories. The workflow could not be tested where it was written; if a step fails, send me the log.

Why not MinGW or another compiler on Windows? Qt WebEngine is only built for **MSVC**, so any local Windows build needs the
Microsoft C++ compiler. The cloud runner already has it.

## Building locally (no cross-compiling: build on each target OS)

### Windows

1. Install Qt with the **Qt WebEngine** and **Qt WebChannel** modules:
   **5.15.2 MSVC 2019 64-bit** for Windows 7/8/8.1, **6.5.x MSVC 2019 64-bit** for Windows 10+.
2. Install Visual Studio 2019 Build Tools and Inno Setup 6 (put `iscc.exe` on `PATH`).
3. Double-click `build.bat` and answer the question, or run it from a command prompt (Visual Studio is detected automatically):
   ```
   build.bat C:\Qt\5.15.2\msvc2019_64 5
   build.bat C:\Qt\6.5.3\msvc2019_64 6
   ```
   The results are written to `dist\`. Without Inno Setup, only the program folder `dist\win-qtN` is produced.

Windows 7 needs **SP1 and KB2999226 (Universal CRT)**.

### macOS

```
QTDIR=$HOME/Qt/6.5.3/macos ./build.sh
```

This creates `dist/Mixdown-1.0.0-mac.dmg`. The app is only ad-hoc signed, so on first launch use right-click -> Open.
Proper distribution needs Apple Developer signing and notarization.

### Linux

```
./build.sh deb        # or: rpm, appimage, all
```

- Requires `qmake6`, the Qt 6 WebEngine/WebChannel development packages, `make`, `g++`, plus `dpkg-deb` (deb) or `rpmbuild` (rpm).
- The AppImage is built by downloading `linuxdeploy` (internet access required). How well Qt WebEngine gets bundled
  depends on the linuxdeploy-plugin-qt version.
- Set the real `Depends` (Debian/Ubuntu package names) and the rpm `License` in `packaging/linux/build-linux.sh`.

## Behavior

- Menus: File (Open / Save / Save As / Export HTML), Edit, View (zoom, full screen), Help.
- Double-clicking a `.mxd` file opens it in this program (Windows: the "file association" installer task; Linux: MIME type;
  macOS: Info.plist).
- Settings, language and theme are kept in the app's local storage.

## Notes

- **The WebEngine in Qt 5.15.2 is based on Chromium 83**, which no longer receives security updates. The app only opens its
  bundled local page and hands web links to the default browser, but do not use it to browse external sites.
- `index.html` contains replacements for CSS that Chromium 83 does not support (`inset`, flex `gap`).
- Opening the same file twice opens a separate window each time (no single-instance handling).
- This project has **not been compiled or install-tested** in the environment where it was written. If the first build on a
  machine with Qt installed reports errors, please report them.
