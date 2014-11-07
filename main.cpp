#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QSurfaceFormat>
#include "SMU.h"

int main(int argc, char *argv[])
{
    registerTypes();

    QSurfaceFormat fmt;
    qDebug() << "Default: " << fmt.profile() << fmt.majorVersion() << fmt.minorVersion();

    fmt.setVersion(2, 0);
    fmt.setProfile(QSurfaceFormat::NoProfile);

    qDebug() << "Using: " << fmt.profile() << fmt.majorVersion() << fmt.minorVersion();
    QSurfaceFormat::setDefaultFormat(fmt);

    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    SessionItem smu_session;
    smu_session.openAllDevices();
    engine.rootContext()->setContextProperty("session", &smu_session);

    engine.load("main.qml");
    return app.exec();
}
