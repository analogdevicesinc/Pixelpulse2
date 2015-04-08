#pragma once
#include <QtQuick/QQuickItem>
#include "libsmu/libsmu.hpp"
#include <memory>

class SessionItem;
class DeviceItem;
class ChannelItem;
class SignalItem;
class ModeItem;
class SrcItem;

class FloatBuffer;

class SessionItem : public QObject {
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<DeviceItem> devices READ getDevices NOTIFY devicesChanged)
    Q_PROPERTY(bool active READ getActive NOTIFY activeChanged);
    Q_PROPERTY(unsigned sampleRate MEMBER m_sample_rate NOTIFY sampleRateChanged);
    Q_PROPERTY(unsigned sampleCount MEMBER m_sample_count NOTIFY sampleCountChanged);

public:
    SessionItem();
    ~SessionItem();
    Q_INVOKABLE void openAllDevices();
    Q_INVOKABLE void closeAllDevices();

    Q_INVOKABLE void start(bool continuous);
    Q_INVOKABLE void cancel();

    bool getActive() { return m_active; }
    QQmlListProperty<DeviceItem> getDevices() { return QQmlListProperty<DeviceItem>(this, m_devices); }

signals:
    void devicesChanged();
    void activeChanged();
    void sampleRateChanged();
    void sampleCountChanged();
    void progress(sample_t);
    void finished(unsigned status);
    void attached(Device* device);
    void detached(Device* device);

protected slots:
    void onProgress(sample_t);
    void onFinished();
    void onAttached(Device* device);
    void onDetached(Device* device);

protected:
    Session* m_session;
    bool m_active;
    bool m_continuous;
    unsigned m_sample_rate;
    unsigned m_sample_count;
    QList<DeviceItem *> m_devices;
};

class DeviceItem : public QObject {
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<ChannelItem> channels READ getChannels CONSTANT);
    Q_PROPERTY(QString label READ getLabel CONSTANT);
    Q_PROPERTY(QString FWVer READ getFWVer CONSTANT);
    Q_PROPERTY(QString HWVer READ getHWVer CONSTANT);
    Q_PROPERTY(int DefaultRate READ getDefaultRate CONSTANT);
    Q_PROPERTY(QString UUID READ getDevSN CONSTANT);

public:
    DeviceItem(SessionItem*, Device*);
    QQmlListProperty<ChannelItem> getChannels() { return QQmlListProperty<ChannelItem>(this, m_channels); }
    QString getLabel() { return QString(m_device->info()->label); }
    QString getFWVer() { return QString(m_device->fwver()); }
    QString getHWVer() { return QString(m_device->hwver()); }
    QString getDevSN() { return QString(m_device->serial()); }
    int getDefaultRate() { return m_device->get_default_rate(); }
    Q_INVOKABLE int ctrl_transfer( int x, int y, int z) { return m_device->ctrl_transfer(0x40, x, y, z, 0, 0, 100);}

protected:
    Device* const m_device;
    QList<ChannelItem*> m_channels;
    friend class SessionItem;
};

class ChannelItem : public QObject {
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<SignalItem> signals READ getSignals CONSTANT);
    Q_PROPERTY(QString label READ getLabel CONSTANT);
    Q_PROPERTY(unsigned mode MEMBER m_mode NOTIFY modeChanged);

public:
    ChannelItem(DeviceItem*, Device*, unsigned index);
    QQmlListProperty<SignalItem> getSignals() { return QQmlListProperty<SignalItem>(this, m_signals); }
    QString getLabel() const { return QString(m_device->channel_info(m_index)->label); }

signals:
    void modeChanged(unsigned mode);

protected:
    Device* const m_device;
    const unsigned m_index;
    unsigned m_mode;

    QList<ModeItem *> m_modes;
    QList<SignalItem*> m_signals;

    friend class SessionItem;
    friend class SignalItem;
};

class SignalItem : public QObject {
    Q_OBJECT
    Q_PROPERTY(FloatBuffer* buffer READ getBuffer CONSTANT);
    Q_PROPERTY(QString label READ getLabel CONSTANT);
    Q_PROPERTY(double min READ getMin CONSTANT);
    Q_PROPERTY(double max READ getMax CONSTANT);
    Q_PROPERTY(double resolution READ getResolution CONSTANT);
    Q_PROPERTY(SrcItem* src READ getSrc CONSTANT);
    Q_PROPERTY(bool isOutput READ getIsOutput NOTIFY isOutputChanged);
    Q_PROPERTY(bool isInput READ getIsInput NOTIFY isInputChanged);
    Q_PROPERTY(double measurement READ getMeasurement NOTIFY measurementChanged);

public:
    SignalItem(ChannelItem*, int index, Signal*);
    FloatBuffer* getBuffer() const { return m_buffer; }
    QString getLabel() const { return QString(m_signal->info()->label); }
    double getMin() const { return m_signal->info()->min; }
    double getMax() const { return m_signal->info()->max; }
    double getResolution() const { return m_signal->info()->resolution; }
    SrcItem* getSrc() const { return m_src; }
    bool getIsOutput() const {
        return m_signal->info()->outputModes & (1<<m_channel->m_mode);
    }
    bool getIsInput() const {
        return m_signal->info()->inputModes & (1<<m_channel->m_mode);
    }
    double getMeasurement() {
        return m_measurement;
    }

signals:
    void isOutputChanged(bool);
    void isInputChanged(bool);
    void measurementChanged(double);

protected slots:
    void onParentModeChanged(int);

protected:
    int const m_index;
    ChannelItem* const m_channel;
    Signal* const m_signal;
    FloatBuffer* m_buffer;
    SrcItem* m_src;
    double m_measurement;
    friend class SessionItem;
    friend class SrcItem;

    void updateMeasurement();
};

class ModeItem : public QObject {
Q_OBJECT
public:
    ModeItem();
};

class SrcItem : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString src   MEMBER m_src     NOTIFY srcChanged);
    Q_PROPERTY(double v1     MEMBER m_v1      NOTIFY v1Changed);
    Q_PROPERTY(double v2     MEMBER m_v2      NOTIFY v2Changed);
    Q_PROPERTY(double period MEMBER m_period  NOTIFY periodChanged);
    Q_PROPERTY(double phase  MEMBER m_phase   WRITE setPhase NOTIFY phaseChanged);
    Q_PROPERTY(double duty   MEMBER m_duty    NOTIFY dutyChanged);

public:
    SrcItem(SignalItem*);
    Q_INVOKABLE void update();
    void setPhase(double phase) {
        phase = fmod(fmod(phase, m_period)+m_period, m_period);
        if (phase != m_phase) {
            m_phase = phase;
            phaseChanged(m_phase);
        }
    }

signals:
    void srcChanged(QString);
    void v1Changed(double);
    void v2Changed(double);
    void periodChanged(double);
    void phaseChanged(double);
    void dutyChanged(double);
    void changed();

protected:
    QString m_src;
    double m_v1;
    double m_v2;
    double m_period;
    double m_phase;
    double m_duty;

    SignalItem* m_parent;
};

void registerTypes();
