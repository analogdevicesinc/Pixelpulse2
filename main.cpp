#include <iostream>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "SMU.h"
#include "utils/backtracing.h"

int main(int argc, char *argv[])
{
    init_signal_handlers();
    
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    registerTypes();

    SessionItem smu_session;
    smu_session.openAllDevices();
    engine.rootContext()->setContextProperty("session", &smu_session);

    if (argc > 1) {
        if (strcmp(argv[1], "-v") || strcmp(argv[1], "--version")) {
            std::cout << GIT_VERSION << ": Built on " << BUILD_DATE << std::endl;
            return 0;
        }
        engine.load(argv[1]);
    } else {
        engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    }

    int r = app.exec();

    smu_session.closeAllDevices();

    return r;
}
