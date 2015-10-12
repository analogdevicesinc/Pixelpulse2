#include "frontendsetup.h"

void registerFrontendTypes() {
    qmlRegisterType<SelectableLabels>();
    qmlRegisterType<DeviceList>();
    qmlRegisterType<ChannelList>();
    qmlRegisterType<SignalList>();
}

SelectableLabels::SelectableLabels(QObject *parent) : QObject(parent)
{
    this->m_crt_label = -1;
}

SelectableLabels::~SelectableLabels()
{
}

QString SelectableLabels::crtLabel()
{
    if (m_crt_label < 0 || m_crt_label > m_labels.size() - 1)
        return NULL;

    return m_labels[m_crt_label];
}

void SelectableLabels::setCrtLabelPos(int newPos)
{
    int count = m_labels.size();

    setPosAtLowest(false);
    setPosAtHighest(false);

    if (newPos < 0)
        newPos = 0;
    else if (newPos > count - 1)
        newPos = count - 1;

    if (newPos != this->m_crt_label) {
        this->m_crt_label = newPos;
        emit labelCountChanged();
        emit crtLabelChanged();
        on_crt_label_pos_changed();
    }

    if (newPos == 0)
        setPosAtLowest(true);
    if (newPos == count - 1)
        setPosAtHighest(true);
}

void SelectableLabels::setPosAtLowest(bool newState)
{
    if (newState != m_pos_at_lowest) {
        m_pos_at_lowest = newState;
        emit posAtLowestChanged();
    }
}

void SelectableLabels::setPosAtHighest(bool newState)
{
    if (newState != m_pos_at_highest) {
        m_pos_at_highest = newState;
        emit posAtHighestChanged();
    }
}

void SelectableLabels::on_crt_label_pos_changed()
{

}

DeviceList::DeviceList(QObject * parent) : SelectableLabels(parent)
{
}

DeviceList::~DeviceList()
{
}

DeviceItem* DeviceList::crtDevice()
{
    if (m_crt_label > -1 && !m_devices.isEmpty())
        return m_devices[m_crt_label];
    else
        return NULL;
}

void DeviceList::setCrtDevice(DeviceItem *dev)
{
    int i = m_devices.indexOf(dev, 0);

    if (i > -1 && i != m_crt_label)
        setCrtLabelPos(i);
}

void DeviceList::OnDevicesChanged(QList<DeviceItem *> devices)
{
    QString newLabel;
    int count = devices.size();

    this->m_labels.clear();
    this->m_devices.clear();
    m_crt_label = -1;

    for (int i = 0; i < count; i++) {
       newLabel = devices[i]->getLabel();
       if (count > 1)
           newLabel.append("-" + QString::number(i + 1));

       m_labels.append(newLabel);
       m_devices.append(devices[i]);
    }

    setCrtLabelPos(count > 0 ? 0 : -1);
    emit labelCountChanged();
}

void DeviceList::OnCrtChannelChanged(ChannelItem *chn)
{
    setCrtDevice((DeviceItem *)chn->parent());
}

void DeviceList::on_crt_label_pos_changed()
{
    if (m_crt_label > -1 && !m_devices.isEmpty())
        emit crtDeviceChanged(m_devices[m_crt_label]);
}

ChannelList::ChannelList(QObject * parent) : SelectableLabels(parent)
{
}

ChannelList::~ChannelList()
{
}

ChannelItem* ChannelList::crtChannel()
{
    if (m_crt_label > -1 && !m_channels.isEmpty()) {
        return m_channels[m_crt_label]; }
    else
        return NULL;
}

void ChannelList::setCrtChannel(ChannelItem *chn)
{
    int i = m_channels.indexOf(chn, 0);

    if (i > -1 && i != m_crt_label)
        setCrtLabelPos(i);
}

void ChannelList::OnDevicesChanged(QList<DeviceItem *> devices)
{
    QString newLabel;
    int count = devices.size();
    char chnLabel = 'A';

    this->m_labels.clear();
    this->m_channels.clear();
    m_crt_label = -1;

    for (int i = 0; i < count; i++) {
        DeviceItem *dev = devices[i];

        for (int j = 0; j < dev->getChannelList().size(); j++) {
           newLabel = "Channel " + QString(chnLabel++);
           m_labels.append(newLabel);
           m_channels.append(dev->getChannelList()[j]);
        }
    }

    emit allChannelsChanged();
    setCrtLabelPos(count > 0 ? 0 : -1);
    emit labelCountChanged();
}

void ChannelList::OnCrtDeviceChanged(DeviceItem *dev)
{
    ChannelItem *chn = crtChannel();
    if (chn && (DeviceItem *)chn->parent() != dev)
        setCrtChannel(dev->getChannelList()[0]);
}

void ChannelList::on_crt_label_pos_changed()
{
    if (m_crt_label > -1 && !m_channels.isEmpty())
        emit crtChannelChanged(m_channels[m_crt_label]);
}

SignalList::SignalList(QObject *parent, int signalsType)
    : QObject(parent), m_signalsType(signalsType)
{

}

SignalList::~SignalList()
{

}

void SignalList::OnDevicesChanged(QList<DeviceItem *> devices)
{
    int count = devices.size();

    this->m_signals.clear();

    for (int i = 0; i < count; i++) {
        DeviceItem *dev = devices[i];

        for (int j = 0; j < dev->getChannelList().size(); j++)
           m_signals.append(dev->getChannelList()[j]->getSignalList()[m_signalsType]);
    }

    emit listChanged();
}

FrontendSetup::FrontendSetup(QObject *parent) : QObject(parent)
{
    m_deviceList = new DeviceList();
    m_channelList = new ChannelList();
    m_voltages = new SignalList(NULL, 0);
    m_currents = new SignalList(NULL, 1);
    QObject::connect(m_channelList, SIGNAL(crtChannelChanged(ChannelItem *)),
                     m_deviceList, SLOT(OnCrtChannelChanged(ChannelItem*)));
    QObject::connect(m_deviceList, SIGNAL(crtDeviceChanged(DeviceItem*)),
                     m_channelList, SLOT(OnCrtDeviceChanged(DeviceItem*)));
}

FrontendSetup::~FrontendSetup()
{
    if (m_deviceList) {
        delete m_deviceList;
        m_deviceList = NULL;
    }
    if (m_channelList) {
        delete m_channelList;
        m_channelList = NULL;
    }
}

void FrontendSetup::OnDevicesChanged(QList<DeviceItem *> devices)
{
    m_deviceList->OnDevicesChanged(devices);
    m_channelList->OnDevicesChanged(devices);
    m_voltages->OnDevicesChanged(devices);
    m_currents->OnDevicesChanged(devices);
}
