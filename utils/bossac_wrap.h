/// simple implementation of bossac flashing and verification

#ifndef BOSSAC_H
#define BOSSAC_H

#include <QProcess>
#include <QObject>
#include <QTextStream>

class BossacWrapper: public QObject
{
    Q_OBJECT

public slots:
    QString getBossacPath() {
    #ifdef Q_OS_LINUX
        return "bossac";
    #elif defined(Q_OS_WIN32)
        return "bossac.exe";
    #else
    #error "We don't support that version yet..."
    #endif
    }

    bool flashByFilename(const QString& image) {
        //QObject *parent;
        QProcess bossacThread;
        QString program = getBossacPath();
        QStringList arguments;
        arguments << "-e" /*erase*/ <<  "-w" /*write*/ <<  "-v" /*verify*/ << "-b" /*boot into flash*/ << image;

        bossacThread.start(program, arguments);
        if (!bossacThread.waitForFinished())
            return false;
        else
            return true;
    }

public:
    BossacWrapper() {}
};

#endif // BOSSAC_H
