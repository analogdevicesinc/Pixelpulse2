TEMPLATE = lib
CONFIG += plugin
QT += qml quick

TARGET = Plot

HEADERS += \
	plugin.h \
    PhosphorRender.h \
    FloatBuffer.h \

SOURCES += \
	PhosphorRender.cpp \
	FloatBuffer.cpp \

qmldir.files=$$PWD/qmldir
qmldir.path=$$DESTDIR

INSTALLS += qmldir target

QMAKE_CXXFLAGS_RELEASE -= -O2
QMAKE_CXXFLAGS_RELEASE += -O3