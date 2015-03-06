TEMPLATE = app

QT += qml quick widgets
CONFIG += c++11
CONFIG += debug_and_release

LIBS += `curl-config --libs` -ljansson

CFLAGS += -v -static -static-libgcc -static-libstdc++ 
DEFINES += GIT_VERSION='"\\\"$(shell git describe --always)\\\""'
DEFINES += BUILD_DATE='"\\\"$(shell date)\\\""'

SOURCES += main.cpp \
    SMU.cpp \
    Plot/PhosphorRender.cpp \
    Plot/FloatBuffer.cpp \
    libsmu/device_m1000.cpp \
    libsmu/session.cpp \
    libsmu/device_cee.cpp

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in the Qt Creator code model
QML_IMPORT_PATH =

OTHER_FILES += \
    qml/main.qml \
    qml/Toolbar.qml \
    qml/PlotPane.qml \
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
    libsmu/device_m1000.hpp \
    libsmu/libsmu.h \
    libsmu/libsmu.hpp \
    libsmu/device_cee.hpp \
    libsmu/internal.hpp

win32:debug {
	CONFIG += console
}

osx {
	ICON = icons/pp2.icns
}

win32 {
	RC_ICONS = icons/pp2.ico
}

unix: CONFIG += link_pkgconfig
unix: PKGCONFIG += libusb-1.0
