#include <iostream>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QRunnable>
#include <QThreadPool>
#include "SMU.h"

//#include "utils/backtracing.h"
#include "utils/bossac_wrap.h"
#include "utils/fileio.h"

#define _DEFINE_STRINGIFY(x) #x
#define DEFINE_STRINGIFY(x) _DEFINE_STRINGIFY(x)

int main(int argc, char *argv[])
{
    // Prevent config being written to ~/.config/Unknown Organization/pixelpulse2.conf
    QCoreApplication::setOrganizationName("Pixelpulse2");
    QCoreApplication::setApplicationName("Pixelpulse2");

    QLocale::setDefault(QLocale(QLocale::English, QLocale::UnitedStates));

//    init_signal_handlers(argv[0]);

    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    registerTypes();

    FileIO fileIO;
    BossacWrapper bossacWrapper;
    SessionItem smu_session;
    smu_session.openAllDevices();
    engine.rootContext()->setContextProperty("session", &smu_session);

    QVariantMap versions;
    versions.insert("build_date", DEFINE_STRINGIFY(BUILD_DATE));
    versions.insert("git_version", DEFINE_STRINGIFY(GIT_VERSION));
    engine.rootContext()->setContextProperty("versions", versions);
    engine.rootContext()->setContextProperty("fileio", &fileIO);
    engine.rootContext()->setContextProperty("bossac", &bossacWrapper);
    if (argc > 1) {
        if (strcmp(argv[1], "-v") || strcmp(argv[1], "--version")) {
            std::cout << DEFINE_STRINGIFY(GIT_VERSION) << ": Built on " << DEFINE_STRINGIFY(BUILD_DATE) << std::endl;
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
