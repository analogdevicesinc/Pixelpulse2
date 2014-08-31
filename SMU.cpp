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

    qmlRegisterType<PhosphorRender>("Plot", 1, 0, "PhosphorRender");
    qmlRegisterType<FloatBuffer>("Plot", 1, 0, "FloatBuffer");
}

SessionItem::SessionItem():
m_session(std::unique_ptr<Session>(new Session)),
m_sample_rate(0),
m_sample_count(0)
{

}

SessionItem::~SessionItem() {}

void SessionItem::openAllDevices()
{
  m_session->update_available_devices();
  for (auto i: m_session->m_available_devices) {
		auto dev = m_session->add_device(&*i);
    m_devices.append(new DeviceItem(dev));
	}

  devicesChanged();
}

void SessionItem::start()
{
  m_active = true;
  activeChanged();
  m_session->configure(m_sample_rate);

  // Configure buffers
  for (auto dev: m_devices) {
    for (auto chan: dev->m_channels) {
      for (auto sig: chan->m_signals) {
        sig->m_buffer->allocate(m_sample_count);
        sig->m_signal->measure_buffer(sig->m_buffer->data(), m_sample_count);
      }
    }
  }

  m_session->run(m_sample_count);
  m_active = false;
  activeChanged();

  for (auto dev: m_devices) {
    for (auto chan: dev->m_channels) {
      for (auto sig: chan->m_signals) {
        sig->m_buffer->setValid(0, m_sample_count);
      }
    }
  }
}

DeviceItem::DeviceItem(Device* dev):
m_device(dev)
{
  auto dev_info = dev->info();

  for (unsigned ch_i=0; ch_i < dev_info->channel_count; ch_i++) {
    m_channels.append(new ChannelItem(dev, ch_i));
  }
}

ChannelItem::ChannelItem(Device* dev, unsigned ch_i):
m_device(dev), m_index(ch_i)
{
  auto ch_info = dev->channel_info(ch_i);

  for (unsigned sig_i=0; sig_i < ch_info->signal_count; sig_i++) {
    auto sig = dev->signal(ch_i, sig_i);
    m_signals.append(new SignalItem(sig));
  }
}

SignalItem::SignalItem(Signal* sig):
m_signal(sig),
m_buffer(new FloatBuffer(this))
{
  auto sig_info = sig->info();
}

ModeItem::ModeItem()
{

}
