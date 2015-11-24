/// simple implementation of bossac flashing and verification

#ifndef BOSSAC_H
#define BOSSAC_H

#include <QProcess>
#include <QObject>
#include <QTextStream>
#include <QTimer>

#include <QDebug>

class BossacWrapper: public QObject
{
    Q_OBJECT

public slots:
    QString getBossacPath() {
    #ifdef Q_OS_LINUX
        return "bossac";
    #elif defined(Q_OS_WIN32)
        return "bossac.exe";
    #elif defined(Q_OS_MAC)
        return "bossac";
    #else
        #error "We don't support this platform yet."
    #endif
    }

    bool flashByFilename(const QString& image) {
        QTimer timer;
        bool devReadyToProg = false;
        bool timeout = false;
        bool ret = true;

        // At this point device is set in programming mode. Make sure bossac sees it before
        // attempting to flash it.
        timer.setInterval(10000);
        timer.start();
        while (!devReadyToProg && !timeout) {
            QString output = deviceInformation().left(19);
            if (output == "Device found on COM") {
                devReadyToProg = true;
            } else {
                if (timer.remainingTime() == 0) {
                    timeout = true;
                    qDebug() << "The programming of the device has timeout!";
                }
            }
        }

        // Flash the device
        QProcess bossacThread;
        QString program = getBossacPath();
        QStringList arguments;
        arguments << "-e" /*erase*/ <<  "-w" /*write*/ <<  "-v" /*verify*/ << "-b" /*boot into flash*/ << image;
        bossacThread.setProcessChannelMode(QProcess::MergedChannels);

        if (devReadyToProg) {
            bossacThread.start(program, arguments);
            ret = bossacThread.waitForFinished();
            if (ret) {
                qDebug() << bossacThread.readAllStandardOutput();
            }
        }

        return ret;
    }

    QString deviceInformation()
    {
        QProcess bossacThread;
        QString program = getBossacPath();
        QStringList arguments;
        arguments << "-i" /*info*/;

        bossacThread.setProcessChannelMode(QProcess::MergedChannels);
        bossacThread.start(program, arguments);
        bossacThread.waitForFinished();
        return bossacThread.readAllStandardOutput();
    }

public:
    BossacWrapper() {}
};

#endif // BOSSAC_H
