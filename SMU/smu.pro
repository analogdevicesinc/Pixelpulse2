TEMPLATE = lib
CONFIG += plugin
QT += qml quick

TARGET = SMU

HEADERS += \
  plugin.h \
  SMU.h \

SOURCES += \
  SMU.cpp \

LIBS += \
  ../libsmu/smu.a \
  -lusb-1.0 \
  -lm \

qmldir.files=$$PWD/qmldir
qmldir.path=$$DESTDIR

INSTALLS += qmldir target

QMAKE_CXXFLAGS += -std=c++11
QMAKE_CXXFLAGS_RELEASE -= -O2
QMAKE_CXXFLAGS_RELEASE += -O3
