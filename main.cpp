#include <iostream>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "SMU.h"
#include "utils/phone_home.h"

int main(int argc, char *argv[])
{
    
    /* Usage Example */
    Release release;
    
    phone_home_init();
    if (release_is_up_to_date("1980-01-01", &release)) {
        printf("up-to-date\n");
    } else {
        printf("A new release is avaliable:\n %s(%s)\n SHA: %s\n URL: %s\n",
                release.name,
                release.build_date,
                release.commit,
                release.url);
        release.dispose(&release);
    }
    phone_home_terminate();
    
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    registerTypes();

    SessionItem smu_session;
    smu_session.openAllDevices();
    engine.rootContext()->setContextProperty("session", &smu_session);

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

    return r;
}
