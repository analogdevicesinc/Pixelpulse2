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

  Q_INVOKABLE void start();

  bool getActive() { return m_active; }
  QQmlListProperty<DeviceItem> getDevices() { return QQmlListProperty<DeviceItem>(this, m_devices); }

signals:
  void devicesChanged();
  void activeChanged();
  void sampleRateChanged();
  void sampleCountChanged();
  void progress(sample_t);
  void completed();

protected slots:
  void onProgress(sample_t);
  void onCompleted();

protected:
  const std::unique_ptr<Session> m_session;
  bool m_active;
  unsigned m_sample_rate;
  unsigned m_sample_count;
  QList<DeviceItem *> m_devices;
};

class DeviceItem : public QObject {
  Q_OBJECT
  Q_PROPERTY(QQmlListProperty<ChannelItem> channels READ getChannels CONSTANT);
  Q_PROPERTY(QString label READ getLabel CONSTANT);

public:
  DeviceItem(SessionItem*, Device*);
  QQmlListProperty<ChannelItem> getChannels() { return QQmlListProperty<ChannelItem>(this, m_channels); }
  QString getLabel() const { return QString(m_device->info()->label); }

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

public:
  SignalItem(ChannelItem*, int index, Signal*);
  FloatBuffer* getBuffer() const { return m_buffer; }
  QString getLabel() const { return QString(m_signal->info()->label); }
  double getMin() const { return m_signal->info()->min; }
  double getMax() const { return m_signal->info()->max; }
  double getResolution() const { return m_signal->info()->resolution; }
  SrcItem* getSrc() const { return m_src; }

protected:
  int const m_index;
  ChannelItem* const m_channel;
  Signal* const m_signal;
  FloatBuffer* m_buffer;
  SrcItem* m_src;
  friend class SessionItem;
  friend class SrcItem;
};

class ModeItem : public QObject {
Q_OBJECT
public:
  ModeItem();
};

class SrcItem : public QObject {
  Q_OBJECT
  Q_PROPERTY(QString src   READ getSrc    WRITE setSrc    NOTIFY srcChanged);
  Q_PROPERTY(double v1     READ getV1     WRITE setV1     NOTIFY V1Changed);
  Q_PROPERTY(double v2     READ getV2     WRITE setV2     NOTIFY V2Changed);
  Q_PROPERTY(double period READ getPeriod WRITE setPeriod NOTIFY periodChanged);
  Q_PROPERTY(double phase  READ getPhase  WRITE setPhase  NOTIFY phaseChanged);
  Q_PROPERTY(double duty   READ getDuty   WRITE setDuty   NOTIFY dutyChanged);
  
public: 
  SrcItem(SignalItem*);
  
  QString getSrc() { return ""; }
  double getV1()     { return m_parent->m_signal->m_src_v1; }
  double getV2()     { return m_parent->m_signal->m_src_v2; }
  double getPeriod() { return m_parent->m_signal->m_src_period; }
  double getPhase()  { return m_parent->m_signal->m_src_phase; }
  double getDuty()   { return m_parent->m_signal->m_src_duty; }
  
  void setSrc(QString s) {}
  void setV1(double v)     { if (v != getV1())     { m_parent->m_signal->m_src_v1     = v; emit V1Changed(v); }}
  void setV2(double v)     { if (v != getV2())     { m_parent->m_signal->m_src_v2     = v; emit V2Changed(v); }}
  void setPeriod(double v) { if (v != getPeriod()) { m_parent->m_signal->m_src_period = v; emit periodChanged(v); }}
  void setPhase(double v)  { if (v != getPhase())  { m_parent->m_signal->m_src_phase  = v; emit phaseChanged(v); }}
  void setDuty(double v)   { if (v != getDuty())   { m_parent->m_signal->m_src_duty   = v; emit dutyChanged(v); }}

signals:
  void srcChanged(QString);
  void V1Changed(double);
  void V2Changed(double);
  void periodChanged(double);
  void phaseChanged(double);
  void dutyChanged(double);

protected:
  SignalItem* m_parent;
};

void registerTypes();
