#include <QQmlExtensionPlugin>

#include "SMU.h"

class PlotPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")
public:
    void registerTypes(const char *uri)
    {
        qmlRegisterType<SessionItem>(uri, 1, 0, "Session");
        qmlRegisterUncreatableType<DeviceItem>(uri, 1, 0, "Device", "Only created throuch Session");
        qmlRegisterUncreatableType<ChannelItem>(uri, 1, 0, "Channel", "Only created throuch Session");
        qmlRegisterUncreatableType<SignalItem>(uri, 1, 0, "Signal", "Only created throuch Session");
        qmlRegisterUncreatableType<ModeItem>(uri, 1, 0, "Mode", "Only created throuch Session");
    }
};
