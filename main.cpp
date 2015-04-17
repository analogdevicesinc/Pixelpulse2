#include <iostream>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QRunnable>
#include <QThreadPool>
#include "SMU.h"

#include "utils/backtracing.h"
#include "utils/fileio.h"

int main(int argc, char *argv[])
{
    init_signal_handlers(argv[0]);

    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    registerTypes();

    FileIO fileIO;
    SessionItem smu_session;
    smu_session.openAllDevices();
    engine.rootContext()->setContextProperty("session", &smu_session);

	QVariantMap versions;
	versions.insert("build_date", BUILD_DATE);
	versions.insert("git_version", GIT_VERSION);
	engine.rootContext()->setContextProperty("versions", versions);
    engine.rootContext()->setContextProperty("fileio", &fileIO);
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
