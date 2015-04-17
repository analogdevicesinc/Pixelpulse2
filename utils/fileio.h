/// simple implementation of writing files for qml

#ifndef FILEIO_H
#define FILEIO_H

#include <QObject>
#include <QFile>
#include <QDebug>
#include <QTextStream>

class FileIO : public QObject
{
    Q_OBJECT

public slots:
    bool write(const QString& source, const QString& data)
    {
        if (source.isEmpty())
            return false;
        QString s = source;
        // trim "file:/" uri from the path
        s.remove(0,6);
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
