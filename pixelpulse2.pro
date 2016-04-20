TEMPLATE = app

QT += qml quick widgets
QT += network
CONFIG += c++11

isEmpty(LIBUSB_LIBRARY) {
  LIBUSB_LIBRARY = "C:\libusb\Win32\Release\dll\libusb-1.0.lib"
}

isEmpty(LIBUSB_INCLUDE_PATH) {
  LIBUSB_INCLUDE_PATH = "C:\libusb\libusb"
}

isEmpty(BUILD_DATE) {
    unix: BUILD_DATE='"\\\"$(shell date +%F)\\\""'
    win32: BUILD_DATE=Not_Defined
}

isEmpty(GIT_VERSION) {
    unix: GIT_VERSION='"\\\"$(shell git -C $$PWD describe --always --tags --abbrev)\\\""'
    win32: GIT_VERSION=Not_Defined
}

DEFINES += BUILD_DATE=$${BUILD_DATE} GIT_VERSION=$${GIT_VERSION}

QMAKE_CFLAGS_DEBUG += -ggdb
QMAKE_CXXFLAGS_DEBUG += -ggdb

SOURCES += main.cpp \
    SMU.cpp \
    Plot/PhosphorRender.cpp \
    Plot/FloatBuffer.cpp \
    libsmu/src/device_m1000.cpp \
    libsmu/src/session.cpp \
    libsmu/src/device_cee.cpp \
    utils/filedownloader.cpp

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in the Qt Creator code model
QML_IMPORT_PATH =

OTHER_FILES += \
    qml/main.qml \
    qml/Toolbar.qml \
    qml/PlotPane.qml \
    qml/DeviceManagerPane.qml \
    qml/ToolbarStyle.qml \
    qml/ContentPane.qml \
    qml/XYPlot.qml \
    qml/Controller.qml \
    qml/SignalRow.qml \
    qml/ChannelRow.qml \
    qml/OverlayConstant.qml \
    qml/TimelineFlickable.qml \
    qml/TimelineHeader.qml \
    qml/Axes.qml \
    qml/OverlayPeriodic.qml \
    qml/DragDot.qml \
    qml/DeviceRow.qml

HEADERS += \
    SMU.h \
    Plot/PhosphorRender.h \
    Plot/FloatBuffer.h \
    libsmu/src/device_m1000.hpp \
    libsmu/src/libsmu.h \
    libsmu/src/libsmu.hpp \
    libsmu/src/device_cee.hpp \
    libsmu/src/internal.hpp \
    utils/fileio.h \
    utils/bossac_wrap.h \
    utils/filedownloader.h

osx {
	ICON = icons/pp2.icns
        LIBS += -lobjc -framework IOKit -framework CoreFoundation
        INCLUDEPATH += /usr/local/opt/qt5/include
        QT_LOGGING_RULES=qt.network.ssl.warning=false
}

win32 {
	RC_ICONS = icons/pp2.ico
	LIBS += $${LIBUSB_LIBRARY}
	INCLUDEPATH += $${LIBUSB_INCLUDE_PATH}
}

unix {
	CONFIG += link_pkgconfig
# if we do not have a locally compiled static version of libusb-1.0 installed, use pkg-config
	!exists(/usr/local/lib/libusb-1.0.a) {
		PKGCONFIG += libusb-1.0
	}
# if we do have a locally compiled static version of libusb-1.0 installed, use it
	exists(/usr/local/lib/libusb-1.0.a) {
		LIBS += /usr/local/lib/libusb-1.0.a
                INCLUDEPATH += "/usr/local/include/libusb-1.0"
	}
}

unix:!osx {
	PKGCONFIG += libudev
	INSTALLS+=target
	isEmpty(PREFIX) {
		PREFIX = /usr
	}
	BINDIR = $$PREFIX/bin
	target.path=$$BINDIR
	QMAKE_CFLAGS_DEBUG += -rdynamic
	QMAKE_CXXFLAGS_DEBUG += -rdynamic
}
