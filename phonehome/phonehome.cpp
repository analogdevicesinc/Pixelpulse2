#include "phonehome.hpp"

void phonehome_registerTypes() {
    qmlRegisterType<PhoneHome>();
}

// Relsease Class Definitions

Release::Release(QString version, QString name, QDate published, QUrl url)
{
    m_version = version;
    m_name = name;
    m_published = published;
    m_url = url;
}

Release::Release(QJsonObject json)
{
    //m_version = TO DO - once git releases will store the version name as well
    m_name = json["name"].toString();
    m_published = QDate::fromString(json["published_at"].toString().section("T", 0, 0),
                                    "yyyy-MM-dd");
    m_url = QUrl(json["html_url"].toString());
}

Release::~Release()
{
}

// WebPageGetter Class Definitions

WebPageGetter::WebPageGetter()
{
}

WebPageGetter::~WebPageGetter()
{
}

void WebPageGetter::pageRequest(QUrl url)
{
    if (!url.isEmpty())
    {
        connect(&m_netAccMng, SIGNAL(finished(QNetworkReply*)),
                SLOT(pageReceived(QNetworkReply*)));
        QNetworkRequest req(url);
        m_netAccMng.get(req);
    }
}

void WebPageGetter::pageReceived(QNetworkReply *netReply)
{
    m_pageData = netReply->readAll();
    netReply->deleteLater();
    emit data_received();
}

QByteArray WebPageGetter::pageData() const
{
    return m_pageData;
}

// PhoneHome Class Definitions

PhoneHome::PhoneHome(QUrl homeUrl)
{
    m_homeUrl = homeUrl;
}

PhoneHome::~PhoneHome()
{
    if (m_webPageGet)
        delete m_webPageGet;

    for (int i = 0; i < m_releases.count(); i++)
        delete m_releases[i];
    m_releases.clear();
}

void PhoneHome::homeReply()
{
    QJsonDocument jdocHomeReply(QJsonDocument::fromJson(m_webPageGet->pageData()));

    QJsonArray releases = jdocHomeReply.array();

    for (int i = 0; i < releases.count(); i++)
    {
        Release *release = new Release(releases[i].toObject());
        m_releases.append(release);
    }
    emit answered();
    
    // The following code should be moved in a handler of the answered() signal.
    Release *r = getLatestRelease();
    
    if (r && m_clientBuild < r->getPublished())
        printf("A new PixelPulse2 version is available.\n");
}

void PhoneHome::callHome()
{
    m_webPageGet = new WebPageGetter;

    connect(m_webPageGet, SIGNAL(data_received()),
            SLOT(homeReply()));

    m_webPageGet->pageRequest(m_homeUrl);
}

Release *PhoneHome::getLatestRelease()
{
    Release *latestRelease;

    if (m_releases.count() < 1)
        return NULL;

    latestRelease = m_releases[0];
    for (int i = 1; i < m_releases.count(); i++)
    {
        if (latestRelease->getPublished() < m_releases[i]->getPublished())
            latestRelease = m_releases[i];
    }

    return latestRelease;
}

void PhoneHome::setClientBuild(QString build)
{
    m_clientBuild = QDate::fromString(build, "yyyy-MM-dd");
}
