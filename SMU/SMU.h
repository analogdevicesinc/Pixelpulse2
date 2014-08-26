#include <QtQuick/QQuickItem>
#include <memory>

class SessionItem;
class DeviceItem;
class ChannelItem;
class SignalItem;
class ModeItem;

class Session;
class Device;
class Signal;

class SessionItem : public QObject {
  Q_OBJECT
  Q_PROPERTY(QQmlListProperty<DeviceItem> devices READ getDevices NOTIFY devicesChanged)

public:
  SessionItem();
  ~SessionItem();
  Q_INVOKABLE void openAllDevices();

  QQmlListProperty<DeviceItem> getDevices() { return QQmlListProperty<DeviceItem>(this, m_devices); }

signals:
  void devicesChanged();

protected:
  const std::unique_ptr<Session> m_session;

  QList<DeviceItem *> m_devices;
};

class DeviceItem : public QObject {
  Q_OBJECT
  Q_PROPERTY(QList<QObject *> channels READ getChannels CONSTANT);

public:
  DeviceItem(Device*);
  QList<QObject*> getChannels() const { return m_channels; }

protected:
  Device* const m_device;

  QList<QObject *> m_channels;
};

class ChannelItem : public QObject {
  Q_OBJECT
  Q_PROPERTY(QList<QObject *> signals READ getSignals CONSTANT);

public:
  ChannelItem(Device*, unsigned index);
  QList<QObject*> getSignals() const { return m_signals; }

protected:
  Device* const m_device;
  const unsigned m_index;

  QList<ModeItem *> m_modes;
  QList<QObject*> m_signals;
};

class SignalItem : public QObject {
Q_OBJECT
public:
  SignalItem(Signal*);

protected:
  Signal* const m_signal;
};

class ModeItem : public QObject {
Q_OBJECT
public:
  ModeItem();
};
