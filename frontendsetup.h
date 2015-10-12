#pragma once
#include "SMU.h"

class SessionItem;
class DeviceItem;
class ChannelItem;
class SignalItem;

class SelectableLabels : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString crtLabel READ crtLabel NOTIFY crtLabelChanged)
    Q_PROPERTY(int labelCount READ labelCount NOTIFY labelCountChanged)
    Q_PROPERTY(int crtLabelPos READ crtLabelPos WRITE setCrtLabelPos NOTIFY crtLabelPosChanged)
    Q_PROPERTY(bool posAtLowest READ getPosAtLowest NOTIFY posAtLowestChanged)
    Q_PROPERTY(bool posAtHighest READ getPosAtHighest NOTIFY posAtHighestChanged)

public:
    SelectableLabels(QObject *parent = 0);
    ~SelectableLabels();

    QString crtLabel();
    int labelCount() { return m_labels.size(); }
    int crtLabelPos() { return m_crt_label; }
    void setCrtLabelPos(int);
    bool getPosAtLowest() { return m_pos_at_lowest; }
    void setPosAtLowest(bool);
    bool getPosAtHighest() { return m_pos_at_highest; }
    void setPosAtHighest(bool);

signals:
    crtLabelChanged();
    labelCountChanged();
    crtLabelPosChanged();
    posAtLowestChanged();
    posAtHighestChanged();

protected:
    virtual void on_crt_label_pos_changed();

protected:
    QList<QString> m_labels;
    int m_crt_label;
    bool m_pos_at_lowest;
    bool m_pos_at_highest;
};

class DeviceList : public SelectableLabels {
    Q_OBJECT
    Q_PROPERTY(DeviceItem* crtDevice READ crtDevice NOTIFY crtDeviceChanged)

public:
    DeviceList(QObject * parent = 0);
    ~DeviceList();

    DeviceItem* crtDevice();
    void setCrtDevice(DeviceItem *);

signals:
    crtDeviceChanged(DeviceItem *);

public slots:
    void OnDevicesChanged(QList<DeviceItem *>);
    void OnCrtChannelChanged(ChannelItem *);

protected:
    void on_crt_label_pos_changed();

protected:
    QList<DeviceItem *>m_devices;
};

class ChannelList : public SelectableLabels {
    Q_OBJECT
    Q_PROPERTY(ChannelItem* crtChannel READ crtChannel WRITE setCrtChannel NOTIFY crtChannelChanged)
    Q_PROPERTY(QQmlListProperty<ChannelItem> allChannels READ getAllChannels NOTIFY allChannelsChanged)

public:
    ChannelList(QObject * parent = 0);
    ~ChannelList();

    ChannelItem* crtChannel();
    void setCrtChannel(ChannelItem *);
    QQmlListProperty<ChannelItem> getAllChannels() { return QQmlListProperty<ChannelItem>(this, m_channels); }

signals:
    allChannelsChanged();
    crtChannelChanged(ChannelItem *);

public slots:
    void OnDevicesChanged(QList<DeviceItem *>);
    void OnCrtDeviceChanged(DeviceItem *);

protected:
    void on_crt_label_pos_changed();

protected:
    QList<ChannelItem *>m_channels;
};

class SignalList: public QObject {
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<SignalItem> list READ getList NOTIFY listChanged)

public:
    SignalList(QObject *parent = 0, int signalsType = 0);
    ~SignalList();
    QQmlListProperty<SignalItem> getList() { return QQmlListProperty<SignalItem>(this, m_signals); }

signals:
    listChanged();

public slots:
    void OnDevicesChanged(QList<DeviceItem *>);

protected:
    int m_signalsType; // 0 = voltage, 1 = current
    QList<SignalItem *>m_signals;
};

class FrontendSetup : public QObject {
    Q_OBJECT
    Q_PROPERTY(DeviceList* deviceList READ deviceList CONSTANT)
    Q_PROPERTY(ChannelList* channelList READ channelList CONSTANT)
    Q_PROPERTY(SignalList* voltageList READ voltageList CONSTANT)
    Q_PROPERTY(SignalList* currentList READ currentList CONSTANT)

public:
    FrontendSetup(QObject *parent = 0);
    ~FrontendSetup();
    DeviceList* deviceList() { return m_deviceList; }
    ChannelList* channelList() { return m_channelList; }
    SignalList* voltageList() { return m_voltages; }
    SignalList* currentList() { return m_currents; }

public slots:
    void OnDevicesChanged(QList<DeviceItem *>);

protected:
    DeviceList *m_deviceList;
    ChannelList *m_channelList;
    SignalList *m_voltages;
    SignalList *m_currents;
};

void registerFrontendTypes();
