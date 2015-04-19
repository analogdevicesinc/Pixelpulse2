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
	/// accept a file handle by URI and source datastring
    bool writeByURI(const QUrl& destination, const QString& data) {
        auto path = destination.toLocalFile();
        return write(path, data);
    }
	/// accept a file handle by string and source datastring
    bool writeByFilename(const QString& source, const QString& data)
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
