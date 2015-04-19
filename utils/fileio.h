/// simple implementation of writing files for qml

#ifndef FILEIO_H
#define FILEIO_H

#include <QObject>
#include <QFile>
#include <QUrl>
#include <QDebug>
#include <QTextStream>

class FileIO : public QObject
{
    Q_OBJECT

public slots:
    bool writeToURL(const QUrl& destination, const QString& data) {
        qDebug() << destination;
        auto path = destination.toLocalFile();
        qDebug() << path;
        return write(path, data);
    }
    bool write(const QString& source, const QString& data)
    {
        if (source.isEmpty())
            return false;
        QString s = source;
        QFile file(s);
        file.open(QIODevice::WriteOnly | QIODevice::Text);
        QTextStream out(&file);
        // end with a newline
        out << data << "\n";
        return true;
    }

public:
    FileIO() {}
};

#endif // FILEIO_H
