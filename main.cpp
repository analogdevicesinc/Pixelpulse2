#include <iostream>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QRunnable>
#include <QThreadPool>
#include "SMU.h"
#include "utils/phone_home.h"
#include "utils/backtracing.h"

void new_release_check(void)
{
    Release release;
    int upToDate;

    phone_home_init();
    if (!release_is_up_to_date("1980-01-01", &release, &upToDate)) {
        printf("Failed to check if this build is up-to-date\n");
    } else {
        if (upToDate) {
            printf("up-to-date\n");
        } else {
            printf("A new release is available:\n %s(%s)\n SHA: %s\n URL: %s\n",
                    release.name,
                    release.build_date,
                    release.commit,
                    release.url);
            release.dispose(&release);
        }
    }
    phone_home_terminate();
}

class ReleaseCheck : public QRunnable
{
public:
    void run()
    {
        new_release_check();
    }
};

int main(int argc, char *argv[])
{
    init_signal_handlers();

    // preliminary update checking
    ReleaseCheck rCheck;
    rCheck.setAutoDelete(false);
    QThreadPool *threadPool = QThreadPool::globalInstance();
    threadPool->start(&rCheck);
    // back to your regularly scheduled Qt-a-thon
 
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
    threadPool->waitForDone();

    return r;
}
