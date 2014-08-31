#pragma once
#include <QtQuick/QQuickItem>
#include "libsmu/libsmu.hpp"
#include <memory>

class SessionItem;
class DeviceItem;
class ChannelItem;
class SignalItem;
class ModeItem;

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
  DeviceItem(Device*);
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

public:
  ChannelItem(Device*, unsigned index);
  QQmlListProperty<SignalItem> getSignals() { return QQmlListProperty<SignalItem>(this, m_signals); }
  QString getLabel() const { return QString(m_device->channel_info(m_index)->label); }

protected:
  Device* const m_device;
  const unsigned m_index;

  QList<ModeItem *> m_modes;
  QList<SignalItem*> m_signals;

  friend class SessionItem;
};

class SignalItem : public QObject {
  Q_OBJECT
  Q_PROPERTY(FloatBuffer* buffer READ getBuffer CONSTANT);
  Q_PROPERTY(QString label READ getLabel CONSTANT);
  Q_PROPERTY(double min READ getMin CONSTANT);
  Q_PROPERTY(double max READ getMax CONSTANT);
  Q_PROPERTY(double resolution READ getResolution CONSTANT);

public:
  SignalItem(Signal*);
  FloatBuffer* getBuffer() const { return m_buffer; }
  QString getLabel() const { return QString(m_signal->info()->label); }
  double getMin() const { return m_signal->info()->min; }
  double getMax() const { return m_signal->info()->max; }
  double getResolution() const { return m_signal->info()->resolution; }

protected:
  Signal* const m_signal;
  FloatBuffer* m_buffer;
  friend class SessionItem;
};

class ModeItem : public QObject {
Q_OBJECT
public:
  ModeItem();
};

void registerTypes();
