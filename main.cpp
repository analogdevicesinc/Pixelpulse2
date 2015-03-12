#include <iostream>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "SMU.h"
#include "phonehome/phonehome.hpp"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    registerTypes();
    phonehome_registerTypes();

    SessionItem smu_session;
    smu_session.openAllDevices();
    
    PhoneHome *phoneHome = new PhoneHome(
        QUrl("https://api.github.com/repos/analogdevicesinc/pixelpulse2/releases"));
    phoneHome->setClientBuild(BUILD_DATE);
    
    engine.rootContext()->setContextProperty("session", &smu_session);
    engine.rootContext()->setContextProperty("phonehome", phoneHome);

	QVariantMap versions;
	versions.insert("build_date", BUILD_DATE);
	versions.insert("git_version", GIT_VERSION);
	engine.rootContext()->setContextProperty("versions", versions);

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
    delete phoneHome;

    return r;
}
