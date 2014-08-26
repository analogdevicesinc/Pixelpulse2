#include "SMU.h"
#include "../libsmu/libsmu.hpp"

SessionItem::SessionItem():
m_session(std::unique_ptr<Session>(new Session))
{

}

SessionItem::~SessionItem() {}

void SessionItem::openAllDevices() {
  m_session->update_available_devices();
  for (auto i: m_session->m_available_devices) {
		auto dev = m_session->add_device(&*i);
    m_devices.append(new DeviceItem(dev));
	}

  devicesChanged();
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
m_signal(sig)
{
  auto sig_info = sig->info();
}

ModeItem::ModeItem()
{

}
