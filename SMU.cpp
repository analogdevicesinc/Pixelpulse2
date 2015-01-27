#include "SMU.h"
#include "libsmu/libsmu.hpp"
#include "Plot/PhosphorRender.h"
#include "Plot/FloatBuffer.h"

void registerTypes() {
    qmlRegisterType<SessionItem>();
    qmlRegisterType<DeviceItem>();
    qmlRegisterType<ChannelItem>();
    qmlRegisterType<SignalItem>();
    qmlRegisterType<ModeItem>();
    qmlRegisterType<SrcItem>();

    qmlRegisterType<PhosphorRender>("Plot", 1, 0, "PhosphorRender");
    qmlRegisterType<FloatBuffer>("Plot", 1, 0, "FloatBuffer");

    qRegisterMetaType<sample_t>("sample_t");
}

SessionItem::SessionItem():
m_session(new Session),
m_sample_rate(0),
m_sample_count(0),
m_active(false),
m_continuous(false)
{
  connect(this, &SessionItem::progress, this, &SessionItem::onProgress, Qt::QueuedConnection);
  connect(this, &SessionItem::finished, this, &SessionItem::onFinished, Qt::QueuedConnection);
  connect(this, &SessionItem::attached, this, &SessionItem::onAttached, Qt::QueuedConnection);
  connect(this, &SessionItem::detached, this, &SessionItem::onDetached, Qt::QueuedConnection);

  m_session->m_completion_callback = [this](unsigned status){
    emit finished(status);
  };

  m_session->m_progress_callback = [this](sample_t n) {
    emit progress(n);
  };
  m_session->m_hotplug_attach_callback = [this](){
    emit attached();
  };
  m_session->m_hotplug_detach_callback = [this](){
    emit detached();
  };

}

SessionItem::~SessionItem() {
    Q_ASSERT(m_devices.size() == 0);
}

void SessionItem::openAllDevices()
{
  m_session->update_available_devices();
  for (auto i: m_session->m_available_devices) {
		auto dev = m_session->add_device(&*i);
    m_devices.append(new DeviceItem(this, dev));
	}

  devicesChanged();
}

void SessionItem::closeAllDevices()
{
    qDebug() << "Closing devices";
    m_session->cancel();
    m_session->end();
    QList<DeviceItem *> devices;
    m_devices.swap(devices);
    devicesChanged();

    for (auto i: devices) {
      m_session->remove_device(i->m_device);
      delete i;
    }
}

void SessionItem::start(bool continuous)
{
  if (m_active) return;
  if (m_sample_rate == 0) return;
  m_continuous = continuous;

  m_active = true;
  activeChanged();
  m_session->configure(m_sample_rate);

  // Configure buffers
  for (auto dev: m_devices) {
    for (auto chan: dev->m_channels) {
      dev->m_device->set_mode(chan->m_index, chan->m_mode);
      for (auto sig: chan->m_signals) {
        sig->m_buffer->setRate(1.0/m_sample_rate);
        sig->m_buffer->allocate(m_sample_count);

        if (m_continuous) {
          sig->m_signal->measure_callback([=](float d){
            sig->m_buffer->shift(d);
          });
        } else {
          sig->m_signal->measure_buffer(sig->m_buffer->data(), m_sample_count);
        }

        sig->m_src->update();
      }
    }
  }

  m_session->start(continuous ? 0 : m_sample_count);
}

void SessionItem::onAttached()
{
  qDebug() << "attached\n";
  qDebug() << m_devices;
  for (auto i: m_session->m_available_devices) {
    auto dev = m_session->add_device(&*i);
    m_devices.append(new DeviceItem(this, dev));
  }
  devicesChanged();
}

void SessionItem::onDetached(){
  qDebug() << "detached\n";
  qDebug() << m_devices;
  closeAllDevices();
}

void SessionItem::cancel() {
  if (!m_active) { return; }
  m_session->cancel();
}

void SessionItem::onFinished()
{
  m_session->end();
  m_active = false;
  activeChanged();

  if (!m_continuous) {
      for (auto dev: m_devices) {
        for (auto chan: dev->m_channels) {
          for (auto sig: chan->m_signals) {
            sig->updateMeasurement();
          }
        }
      }
  }
}

void SessionItem::onProgress(sample_t sample) {
  for (auto dev: m_devices) {
    for (auto chan: dev->m_channels) {
      for (auto sig: chan->m_signals) {
        if (m_continuous) {
          sig->m_buffer->continuousProgress(sample);
        } else {
          sig->m_buffer->sweepProgress(sample);
        }
      }
    }
  }
}

DeviceItem::DeviceItem(SessionItem* parent, Device* dev):
QObject(parent),
m_device(dev)
{
  auto dev_info = dev->info();

  for (unsigned ch_i=0; ch_i < dev_info->channel_count; ch_i++) {
    m_channels.append(new ChannelItem(this, dev, ch_i));
  }
}

ChannelItem::ChannelItem(DeviceItem* parent, Device* dev, unsigned ch_i):
QObject(parent), m_device(dev), m_index(ch_i), m_mode(0)
{
  auto ch_info = dev->channel_info(ch_i);

  for (unsigned sig_i=0; sig_i < ch_info->signal_count; sig_i++) {
    auto sig = dev->signal(ch_i, sig_i);
    m_signals.append(new SignalItem(this, ch_i, sig));
  }
}

SignalItem::SignalItem(ChannelItem* parent, int index, Signal* sig):
QObject(parent),
m_index(index),
m_channel(parent),
m_signal(sig),
m_buffer(new FloatBuffer(this)),
m_src(new SrcItem(this)),
m_measurement(0.0)
{
  auto sig_info = sig->info();
  connect(m_channel, &ChannelItem::modeChanged, this, &SignalItem::onParentModeChanged);
}

void SignalItem::onParentModeChanged(int) {
  isOutputChanged(getIsOutput());
  isInputChanged(getIsInput());
}

void SignalItem::updateMeasurement(){
  m_measurement = m_buffer->mean();
  measurementChanged(m_measurement);
}

SrcItem::SrcItem(SignalItem* parent):
QObject(parent),
m_parent(parent),
m_src("constant"),
m_v1(0),
m_v2(0),
m_period(0),
m_phase(0),
m_duty(0.5)
{
}

void SrcItem::update() {
  Src v = SRC_CONSTANT;
  if      (m_src == "constant") v = SRC_CONSTANT;
  else if (m_src == "buffer")   v = SRC_BUFFER;
  else if (m_src == "callback") v = SRC_CALLBACK;
  else if (m_src == "square")   v = SRC_SQUARE;
  else if (m_src == "sawtooth") v = SRC_SAWTOOTH;
  else if (m_src == "sine")     v = SRC_SINE;
  else if (m_src == "triangle") v = SRC_TRIANGLE;
  else return;

  m_parent->m_signal->m_src        = v;
  m_parent->m_signal->m_src_v1     = m_v1;
  m_parent->m_signal->m_src_v2     = m_v2;
  m_parent->m_signal->m_src_period = m_period;
  m_parent->m_signal->m_src_phase  = m_phase;
  m_parent->m_signal->m_src_duty   = m_duty;
}

ModeItem::ModeItem()
{

}
