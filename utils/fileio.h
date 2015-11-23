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
        return writeByFilename(path, data);
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
    /// accept a file handle by URI and source datastring
    bool writeRawByURI(const QUrl& destination, const QByteArray& data) {
        auto path = destination.toLocalFile();
        return writeRawByFilename(path, data);
    }
    /// accept a file handle by string and source datastring
    bool writeRawByFilename(const QString& source, const QByteArray& data)
    {
        if (source.isEmpty())
            return false;
        QString s = source;
        QFile file(s);
        file.open(QIODevice::WriteOnly);
        QDataStream out(&file);
        out << data;
        return true;
    }

    QString readByURI(const QUrl& source) {
		auto path = source.toLocalFile();
		QFile file(path);
        file.open(QIODevice::ReadOnly | QIODevice::Text);
		QTextStream in(&file);
        return in.readAll();
	}

public:
    FileIO() {}
};

#endif // FILEIO_H
