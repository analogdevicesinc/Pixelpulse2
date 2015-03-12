#pragma once

#include <QtQuick/QQuickItem>
#include <QObject>
#include <QString>
#include <QDate>

#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>


class Release
{
public:
    Release();
    Release(QString version, QString name, QDate published, QUrl url);
    Release(QJsonObject json);
    ~Release();

    QString getVersion() {return m_version;}
    void setVersion(QString version) {m_version = version;}

    QString getName() {return m_name;}
    void setName(QString name) {m_name = name;}

    QDate getPublished() {return m_published;}
    void setPublished(QDate published) {m_published = published;}

    QUrl getUrl() {return m_url;}
    void setUrl(QUrl url) {m_url = url;}

private:
    QString m_version;
    QString m_name;
    QDate m_published;
    QUrl m_url;
};


class WebPageGetter : public QObject
{
    Q_OBJECT

public:
    WebPageGetter();
    ~WebPageGetter();
    void pageRequest(QUrl url);
    QByteArray pageData() const;

signals:
    void data_received();

public slots:
    void pageReceived(QNetworkReply *netReply);

private:
    QNetworkAccessManager m_netAccMng;
    QByteArray m_pageData;

};


class PhoneHome : public QObject
{
    Q_OBJECT

public:
    PhoneHome();
    PhoneHome(QUrl homeUrl);
    ~PhoneHome();
    
    Q_INVOKABLE void callHome();
    Release* getLatestRelease();

    QUrl getHomeUrl() {return m_homeUrl;}
    void setHomeUrl(QUrl homeUrl) {m_homeUrl = homeUrl;}
    
    QDate getClientBuild();
    void setClientBuild(QDate build) {m_clientBuild = build;}
    void setClientBuild(QString build);

signals:
    void answered();

private slots:
    void homeReply();

private:
    QUrl m_homeUrl;
    WebPageGetter *m_webPageGet;
    QList<Release*> m_releases;
    QDate m_clientBuild;
};

void phonehome_registerTypes();
