#pragma once
#include <QtQuick/QQuickItem>
#include <QTimer>
#include <QThread>
#include <libsmu/libsmu.hpp>
#include <memory>
#include "utils/filedownloader.h"
#include <iostream>
#include <QTime>
#include <cmath>
#include <fstream>
#include <QThreadPool>
#include <QtConcurrent/QtConcurrent>

class SessionItem;
class DeviceItem;
class ChannelItem;
class SignalItem;
class ModeItem;
class SrcItem;
class TimerItem;
class BufferChanger;
class FloatBuffer;
class DataLogger;

/// SessionItem is the primary object in Pixelpulse2
/// It abstracts over a libsmu session, exposing relevant parameters to QML.
class SessionItem : public QObject {
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<DeviceItem> devices READ getDevices NOTIFY devicesChanged)
    Q_PROPERTY(bool active READ getActive NOTIFY activeChanged);
    Q_PROPERTY(unsigned sampleRate MEMBER m_sample_rate NOTIFY sampleRateChanged);
    Q_PROPERTY(unsigned sampleCount MEMBER m_sample_count NOTIFY sampleCountChanged);
    Q_PROPERTY(double sampleTime MEMBER m_sample_time NOTIFY sampleTimeChanged);
    Q_PROPERTY(unsigned logging MEMBER m_logging NOTIFY loggingChanged);
    Q_PROPERTY(int activeDevices READ getActiveDevices NOTIFY activeChanged);
    Q_PROPERTY(int availableDevices READ getAvailableDevices NOTIFY devicesChanged);
    Q_PROPERTY(int queueSize MEMBER m_queue_size CONSTANT)

public:
    SessionItem();
    ~SessionItem();
    Q_INVOKABLE void openAllDevices();
    Q_INVOKABLE void closeAllDevices();

    Q_INVOKABLE void start(bool continuous);
    Q_INVOKABLE void cancel();
    Q_INVOKABLE void restart();
    int getAvailableDevices() { return m_session->m_available_devices.size(); }
    int getActiveDevices() { return m_session->m_devices.size(); }

    Q_INVOKABLE void updateMeasurements();
    Q_INVOKABLE void updateAllMeasurements();

    Q_INVOKABLE void downloadFromUrl(QString url);
    Q_INVOKABLE QString flash_firmware(QString url);
    Q_INVOKABLE QString getTmpPathForFirmware();
    Q_INVOKABLE int programmingModeDeviceExists();

    bool isContinuous(){return m_continuous;}
    bool getActive() { return m_active; }
    QQmlListProperty<DeviceItem> getDevices() { return QQmlListProperty<DeviceItem>(this, m_devices); }
    static void usb_handle_thread_method(SessionItem *session_item);

signals:
    void devicesChanged();
    void activeChanged();
    void sampleRateChanged();
    void sampleCountChanged();
    void sampleTimeChanged();
    void loggingChanged();
    void finished(unsigned status);
    void attached(smu::Device* device);
    void detached(smu::Device* device);
    void firmwareDownloaded();

protected slots:
    void onFinished();
    void onAttached(smu::Device* device);
    void onDetached(smu::Device* device);
    void handleDownloadedFirmware();
    void onSampleCountChanged();
    void onSampleTimeChanged();
    void onLoggingChanged();
    void getSamples();
    void beginNewSweep();

protected:
    smu::Session* m_session;
    bool m_active;
    bool m_continuous;
    unsigned m_sample_rate;
    unsigned m_sample_count;
    double m_sample_time;
    unsigned m_queue_size;
    DataLogger *m_data_logger;
    unsigned m_logging;
    FileDownloader *m_firmware_fd;
    QList<DeviceItem *> m_devices;
    QTimer timer;
    QTimer *sweepTimer;
};


/// DeviceItem abstracts over a LibSMU Device exposing relevant parameters to QML
class DeviceItem : public QObject {
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<ChannelItem> channels READ getChannels CONSTANT);
    Q_PROPERTY(QString label READ getLabel CONSTANT);
    Q_PROPERTY(QString FWVer READ getFWVer CONSTANT);
    Q_PROPERTY(QString HWVer READ getHWVer CONSTANT);
    Q_PROPERTY(int DefaultRate READ getDefaultRate CONSTANT);
    Q_PROPERTY(QString UUID READ getDevSN CONSTANT);

public:
    DeviceItem(SessionItem*, smu::Device*);
    QQmlListProperty<ChannelItem> getChannels() { return QQmlListProperty<ChannelItem>(this, m_channels); }
    QString getLabel() { return QString(m_device->info()->label); }
    QString getFWVer() { return QString::fromStdString(m_device->m_fwver); }
    QString getHWVer() { return QString::fromStdString(m_device->m_hwver); }
    QString getDevSN() { return QString::fromStdString(m_device->m_serial); }
    int getDefaultRate() { return m_device->get_default_rate(); }
    friend class DataLogger;
    Q_INVOKABLE int ctrl_transfer( int x, int y, int z) { return m_device->ctrl_transfer(0x40, x, y, z, 0, 0, 100);}
    Q_INVOKABLE void blinkLeds();

    size_t samplesAdded() { return m_samples_added; }
    void setSamplesAdded(size_t count) { m_samples_added = count; }
    void write(ChannelItem* chn = nullptr);

protected:
    smu::Device* const m_device;
    QList<ChannelItem*> m_channels;
    friend class SessionItem;
    size_t m_samples_added;
};

class ChannelItem : public QObject {
    Q_OBJECT
    Q_PROPERTY(QQmlListProperty<SignalItem> signals READ getSignals CONSTANT);
    Q_PROPERTY(QString label READ getLabel CONSTANT);
    Q_PROPERTY(unsigned mode MEMBER m_mode NOTIFY modeChanged);

public:
    ChannelItem(DeviceItem*, smu::Device*, unsigned index);
    QQmlListProperty<SignalItem> getSignals() { return QQmlListProperty<SignalItem>(this, m_signals); }
    QString getLabel() const { return QString(m_device->channel_info(m_index)->label); }

    void buildTxBuffer();

signals:
    void modeChanged(unsigned mode);

protected:
    smu::Device* const m_device;
    const unsigned m_index;
    unsigned m_mode;

    QList<ModeItem *> m_modes;
    QList<SignalItem*> m_signals;

    std::vector<float> m_tx_data;
    TimerItem *timer;

    friend class SessionItem;
    friend class DeviceItem;
    friend class SignalItem;
    friend class TimerItem;
};

/// Abstracts over a LibSMU Signal and the BufferItem used for rendering data
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
    Q_PROPERTY(double peak_to_peak READ getPeak NOTIFY peakChanged);
    Q_PROPERTY(double rms READ getRms NOTIFY rmsChanged);
    Q_PROPERTY(double mean READ getMean NOTIFY meanChanged);

public:
    SignalItem(ChannelItem*, int index, smu::Signal*);
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
    double getPeak(){
        return m_peak_to_peak;
    }
    double getRms() {
        return m_rms;
    }
    double getMean() {
	return m_mean;
    }

signals:
    void isOutputChanged(bool);
    void isInputChanged(bool);
    void measurementChanged(double);
    void peakChanged(double);
    void rmsChanged(double);
    void meanChanged(double);

protected slots:
    void onParentModeChanged(int);

protected:
    int const m_index;
    ChannelItem* const m_channel;
    smu::Signal* const m_signal;
    FloatBuffer* m_buffer;
    SrcItem* m_src;
    double m_measurement;
    double m_peak_to_peak;
    double m_rms;
    double m_mean;
    friend class SessionItem;
    friend class ChannelItem;
    friend class SrcItem;
    friend class TimerItem;

    void updateMeasurementMean();
    void updateMeasurementLatest();
    void updatePeakToPeak();
    void updateRms();
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
        if (m_src.compare("constant") != 0){
            phase = fmod(fmod(phase, m_period)+m_period, m_period);
            if (phase != m_phase) {
                m_phase = phase;
                phaseChanged(m_phase);
            }
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
    friend class TimerItem;
};

class TimerItem : public QObject{
    Q_OBJECT
private:
    ChannelItem *channel;
    DeviceItem *device;
    SessionItem *session;
    QTimer *changeBufferTimer;
    BufferChanger *bc;
    QThread *thread;
    bool modified;

public:
    TimerItem(ChannelItem *channel,DeviceItem *dev);
protected:
    friend class DeviceItem;
    friend class SrcItem;
    friend class SignalItem;
    friend class ChannelItem;
public slots:
    void parameterChanged();
private slots:
    void needChangeBuffer();
    void clean();
};

class BufferChanger :public QObject{
    Q_OBJECT
private:
    ChannelItem *channel;
    DeviceItem *device;
public:
    BufferChanger(ChannelItem *chan,DeviceItem *dev);
    ~BufferChanger(){}
protected slots:
    void changeBuffer();
};

void registerTypes();

class DataLogger: public QObject {
    Q_OBJECT
public:
    DataLogger(float sampleTime, QObject* parent = nullptr);
    void addData(DeviceItem*, std::array < float, 4 >);
    void addBulkData(DeviceItem*, std::vector < std::array < float, 4 > >);
    double computeAverage(DeviceItem*, int channel);
    double computeMinimum(DeviceItem*, int channel);
    double computeMaximum(DeviceItem*, int channel);
    void printData(DeviceItem* deviceItem);
    void setSampleTime(float sampleTime);
private:
    float sampleTime;
    std::ofstream fileStream;
    std::map < DeviceItem*, std::vector < std::array < float, 4 > > > data;
    std::map < DeviceItem*, int > dataCounter;
    std::map < DeviceItem*, std::array < float, 4 > > minimum;
    std::map < DeviceItem*, std::array < float, 4 > > maximum;
    std::map < DeviceItem*, std::array < float, 4 > > sum;
    void updateMinimum(DeviceItem*, std::array < float, 4 >);
    void updateMaximum(DeviceItem*, std::array < float, 4 >);
    void updateSum(DeviceItem*, std::array < float, 4 >);
    std::array < float, 4 > computeAverage(DeviceItem*);
    void resetData(DeviceItem*);
    std::string modifyDateTime(std::string);
    std::chrono::time_point <std::chrono::system_clock> startTime;
    std::chrono::time_point <std::chrono::system_clock> lastLog;
    void createLoggingFolder();
    std::mutex m_logMutex;
    int m_threadsNumber = 5;
    QThreadPool m_threadPool;
    void doAddBulkData(DeviceItem*, std::vector < std::array < float, 4 > >);
};

