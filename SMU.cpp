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
m_active(false),
m_continuous(false),
m_sample_rate(0),
m_sample_count(0)
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
    m_session->m_hotplug_attach_callback = [this](Device* device){
        emit attached(device);
    };
    m_session->m_hotplug_detach_callback = [this](Device* device){
        emit detached(device);
    };

}

SessionItem::~SessionItem() {
        Q_ASSERT(m_devices.size() == 0);
}


/// called on initialisation
void SessionItem::openAllDevices()
{
    m_session->update_available_devices();
    for (auto i: m_session->m_available_devices) {
		auto dev = m_session->add_device(&*i);
        m_devices.append(new DeviceItem(this, dev));
	}
    devicesChanged();
}

/// called at exit
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

/// configure device, datapaths, and start streaming
void SessionItem::start(bool continuous)
{
    if (m_devices.size() == 0) return;
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

                    connect(sig->m_src, &SrcItem::changed, [=] {
                        dev->m_device->lock();
                        sig->m_src->update();
                        dev->m_device->unlock();
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

/// handles hotplug attach condition
/// runs on UI thread
/// triggered by libUSB callback over Queue
void SessionItem::onAttached(Device *device)
{
    auto dev = m_session->add_device(device);
    Q_UNUSED(dev);
    m_devices.append(new DeviceItem(this, device));
    devicesChanged();
}

/// handles hotplug detach condition
/// runs on UI thread
/// triggered by libUSB callback over Queue
void SessionItem::onDetached(Device* device){
    if (m_active) {
            this->cancel();
    }
    // wait for completion and teardown relevant state
	// cut out the middleman, ensure completion is handled
	// don't rely on nondeterministic race condition between Detached and Finished
    onFinished();
    m_session->remove_device(device);
    if ((int) m_session->m_devices.size() < m_devices.size()) {
        for (auto dev: m_devices) {
             if (dev->m_device == device)
                    m_devices.removeOne(dev);
        }
    }
    // remove from list of available devices
    m_session->destroy_available(device);
    devicesChanged();
}

/// cancel obnoxious amount of redirection
/// SessionItem::cancel calls Session::cancel calls Device::cancel on each device
void SessionItem::cancel() {
    if (!m_active) { return; }
    m_session->cancel();
}

/// completion event handler
/// runs on UI thread
/// waits for device to complete (paradoxically?), then tears down the output update connection
void SessionItem::onFinished()
{
    m_session->end();
    m_active = false;
    activeChanged();

    for (auto dev: m_devices) {
        for (auto chan: dev->m_channels) {
            for (auto sig: chan->m_signals) {
                disconnect(sig->m_src, &SrcItem::changed, 0, 0);
                if (!m_continuous) {
                    sig->updateMeasurement();
                }
            }
        }
    }
}

/// progress handler
/// called over Queue, updates BufferItem with new data as appropriate
void SessionItem::onProgress(sample_t sample) {

    if (!m_continuous && sample > m_sample_count) {
        // libsmu rounds up to the packet size and can report a sample count higher than requested,
        // but the buffers only deal with requested samples.
        sample = m_sample_count;
    }

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

/// DeviceItem constructor
DeviceItem::DeviceItem(SessionItem* parent, Device* dev):
QObject(parent),
m_device(dev)
{
    auto dev_info = dev->info();

    for (unsigned ch_i=0; ch_i < dev_info->channel_count; ch_i++) {
        m_channels.append(new ChannelItem(this, dev, ch_i));
    }
}

/// ChannelItem constructor
ChannelItem::ChannelItem(DeviceItem* parent, Device* dev, unsigned ch_i):
QObject(parent), m_device(dev), m_index(ch_i), m_mode(0)
{
    auto ch_info = dev->channel_info(ch_i);

    for (unsigned sig_i=0; sig_i < ch_info->signal_count; sig_i++) {
        auto sig = dev->signal(ch_i, sig_i);
        m_signals.append(new SignalItem(this, ch_i, sig));
    }
}

/// SignalItem constructor
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
    Q_UNUSED(sig_info);
    connect(m_channel, &ChannelItem::modeChanged, this, &SignalItem::onParentModeChanged);
}

/// mode changed handler
void SignalItem::onParentModeChanged(int) {
    isOutputChanged(getIsOutput());
    isInputChanged(getIsInput());
}

/// updates label in constant src mode
void SignalItem::updateMeasurement(){
    m_measurement = m_buffer->mean();
    measurementChanged(m_measurement);
}

/// SrcItem initialisation
SrcItem::SrcItem(SignalItem* parent):
QObject(parent),
m_src("constant"),
m_v1(0),
m_v2(0),
m_period(0),
m_phase(0),
m_duty(0.5),
m_parent(parent)
{
    connect(this, &SrcItem::srcChanged, [=]{ changed(); });
    connect(this, &SrcItem::v1Changed, [=]{ changed(); });
    connect(this, &SrcItem::v2Changed, [=]{ changed(); });
    connect(this, &SrcItem::periodChanged, [=]{ changed(); });
    connect(this, &SrcItem::phaseChanged, [=]{ changed(); });
    connect(this, &SrcItem::dutyChanged, [=]{ changed(); });
}

/// update output signal
void SrcItem::update() {
    Src v = SRC_CONSTANT;
    if (m_src == "constant")        v = SRC_CONSTANT;
    else if (m_src == "buffer")     v = SRC_BUFFER;
    else if (m_src == "callback")   v = SRC_CALLBACK;
    else if (m_src == "square")     v = SRC_SQUARE;
    else if (m_src == "sawtooth")   v = SRC_SAWTOOTH;
    else if (m_src == "stairstep") v = SRC_STAIRSTEP;
    else if (m_src == "sine")       v = SRC_SINE;
    else if (m_src == "triangle")   v = SRC_TRIANGLE;
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
