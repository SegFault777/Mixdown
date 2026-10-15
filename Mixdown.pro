# Mixdown - shared qmake project for Qt 5.15 (Windows 7/8/8.1) and Qt 6.5+ (Windows 10+, macOS 11+, Linux)
QT += core gui widgets webenginewidgets webchannel
CONFIG += c++17
TEMPLATE = app
TARGET = Mixdown
VERSION = 1.0.0
DEFINES += MIXDOWN_VERSION=\\\"$$VERSION\\\"

SOURCES += src/main.cpp src/mainwindow.cpp src/bridge.cpp
HEADERS += src/mainwindow.h src/bridge.h
RESOURCES += resources/resources.qrc

win32 {
    RC_ICONS = packaging/windows/mixdown.ico
    QMAKE_TARGET_PRODUCT = Mixdown
    QMAKE_TARGET_DESCRIPTION = Mixdown markup editor
    msvc: QMAKE_CXXFLAGS += /utf-8
}

macx {
    ICON = packaging/macos/mixdown.icns
    QMAKE_INFO_PLIST = packaging/macos/Info.plist
    QMAKE_MACOSX_DEPLOYMENT_TARGET = 11.0
    QMAKE_APPLE_DEVICE_ARCHS = x86_64 arm64
}

unix:!macx {
    TARGET = mixdown
    target.path = /usr/bin
    desktop.files = packaging/linux/mixdown.desktop
    desktop.path = /usr/share/applications
    mime.files = packaging/linux/mixdown.xml
    mime.path = /usr/share/mime/packages
    icon.files = resources/icons/mixdown.png
    icon.path = /usr/share/icons/hicolor/512x512/apps
    INSTALLS += target desktop mime icon
}
