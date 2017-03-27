#include "SMU.h"
#include "Plot/PhosphorRender.h"
#include "Plot/FloatBuffer.h"
#include "utils/fileio.h"
#include "utils/bossac_wrap.h"
#include "qdebug.h"

using namespace smu;

void registerTypes() {
    qmlRegisterType<SessionItem>();
    qmlRegisterType<DeviceItem>();
    qmlRegisterType<ChannelItem>();
    qmlRegisterType<SignalItem>();
    qmlRegisterType<SrcItem>();

    qmlRegisterType<PhosphorRender>("Plot", 1, 0, "PhosphorRender");
    qmlRegisterType<FloatBuffer>("Plot", 1, 0, "FloatBuffer");

    qRegisterMetaType<uint64_t>("uint64_t");
}

SessionItem::SessionItem():
m_session(new Session),
m_active(false),
m_continuous(false),
m_sample_rate(0),
m_sample_count(0)
{
    connect(this, &SessionItem::finished, this, &SessionItem::onFinished, Qt::QueuedConnection);
    connect(this, &SessionItem::attached, this, &SessionItem::onAttached, Qt::QueuedConnection);
    connect(this, &SessionItem::detached, this, &SessionItem::onDetached, Qt::QueuedConnection);

    connect(&timer, SIGNAL(timeout()), this, SLOT(getSamples()));

    m_session->hotplug_attach([this](Device* device, void* data){
        Q_UNUSED(data);
        emit attached(device);
    });
    m_session->hotplug_detach([this](Device* device, void* data){
        Q_UNUSED(data);
        emit detached(device);
    });
}

SessionItem::~SessionItem() {
        Q_ASSERT(m_devices.size() == 0);
}


/// called on initialisation
void SessionItem::openAllDevices()
{
    m_session->m_queue_size = 1000000;
    m_session->add_all();
    for (auto i: m_session->m_available_devices)
        m_devices.append(new DeviceItem(this, &*i));
    devicesChanged();
}

/// called at exit
void SessionItem::closeAllDevices()
{
    m_session->cancel();
    m_session->end();
    QList<DeviceItem *> devices;
    m_devices.swap(devices);
    devicesChanged();

    for (auto i: devices)
        m_session->remove(i->m_device);
}

/// configure device, datapaths, and start streaming
void SessionItem::start(bool continuous)
{
qDebug() << "Session start(" << continuous << ")";
    if (m_devices.size() == 0) return;
    if (m_sample_rate == 0) return;

    m_session->configure(m_sample_rate);
    m_continuous = continuous;

    // Configure buffers
    for (auto dev: m_devices) {
        dev->setSamplesAdded(0);
        for (auto chan: dev->m_channels) {
            dev->m_device->set_mode(chan->m_index, chan->m_mode);
            chan->buildTxBuffer();
            for (auto sig: chan->m_signals) {
                sig->m_buffer->setRate(1.0/m_sample_rate);
                sig->m_buffer->allocate(m_sample_count);
                sig->m_buffer->startSweep();
            }
        }
        dev->write();
    }

    m_session->flush();
    if (continuous)
        m_session->start(0);
    else
        m_session->start(m_sample_count);
    timer.start(0);

    m_active = true;
    emit activeChanged();
}

/// handles hotplug attach condition
/// runs on UI thread
/// triggered by libUSB callback over Queue
void SessionItem::onAttached(Device *device)
{
    if (m_active) {
        this->cancel();
    }

    int err = m_session->add(device);

    if (!err) {
        m_devices.append(new DeviceItem(this, device));
        devicesChanged();
    }
qDebug() << "Device attached";
}

/// handles hotplug detach condition
/// runs on UI thread
/// triggered by libUSB callback over Queue
void SessionItem::onDetached(Device* device){
    if (m_active) {
            this->cancel();
    }
    m_session->remove(device, true);
    for (auto dev: m_devices) {
         if (dev->m_device == device) {
                m_devices.removeOne(dev);
         }
    }
    m_session->destroy(device);
    devicesChanged();
qDebug() << "Device detached";
}

void SessionItem::handleDownloadedFirmware()
{
    FileIO f;
    BossacWrapper bw;
    f.writeRawByFilename(bw.getTmpPathForFirmware() + "/firmware.bin",  m_firmware_fd->downloadedData());

    delete m_firmware_fd;
    m_firmware_fd = NULL;
}

void SessionItem::cancel() {
    if (!m_active)
        return;

    if (m_continuous)
        timer.stop();

    m_session->cancel();
    m_session->end();
    qDebug() << "Session cancel" << "status:" << m_session->cancelled();

    m_active = false;
    emit activeChanged();
}

void SessionItem::restart()
{
    if (!m_active)
        return;

    cancel();
    while(m_active);
    start(m_continuous);
}

void SessionItem::onFinished()
{
    for (auto dev: m_devices) {
        for (auto chan: dev->m_channels) {
            for (auto sig: chan->m_signals) {
                sig->updateMeasurementMean();
                sig->updatePeakToPeak();
                sig->updateRms();
            }
        }
    }
}

void SessionItem::updateMeasurements() {
/*
    for (auto dev: m_devices) {
        for (auto chan: dev->m_channels) {
            for (auto sig: chan->m_signals) {
                sig->updateMeasurementLatest();
            }
        }
    }
*/
}

void SessionItem::updateAllMeasurements() {
    for (auto dev: m_devices) {
        for (auto chan: dev->m_channels) {
            for (auto sig: chan->m_signals) {
                sig->updateMeasurementMean();
                sig->updatePeakToPeak();
                sig->updateRms();
            }
        }
    }
}

void SessionItem::downloadFromUrl(QString url)
{
    /*
     * this causes Error in `/home/dan/work/git/build-pixelpulse2-Desktop_Qt_5_5_1_GCC_64bit3-Debug/pixelpulse2': corrupted double-linked list: 0x0000000001bf9140 ***
     *
    QUrl firmwareUrl(url);
    m_firmware_fd = new FileDownloader(firmwareUrl, this);
    connect(m_firmware_fd, SIGNAL (downloaded()), this, SLOT (handleDownloadedFirmware()));
    */
}

void SessionItem::getSamples()
{
    if (!m_active)
        return;

    for (auto dev: m_devices) {
        std::vector<std::array<float, 4>> rxbuf;
        int ret = 0;

        try {
            ret = dev->m_device->read(rxbuf, 1000);
        } catch (std::system_error& e) {
            qDebug() << "exception:" << e.what();
        } catch (std::runtime_error& e) {
            qDebug() << "exception:" << e.what();
        }

        qDebug() << ret;

        if (ret == 0)
            return;

        dev->setSamplesAdded(dev->samplesAdded() + ret);

        int i = 0;
        for (auto chan: dev->m_channels) {
            int j = 0;
            for (auto sig: chan->m_signals) {
                if (m_continuous)
                    sig->m_buffer->append_samples_circular(rxbuf, i * 2 + j);
                else
                    sig->m_buffer->append_samples(rxbuf, i * 2 + j);
                j++;
            }
            i++;
        }

        if (!m_continuous) {
            if (dev->samplesAdded() == m_sample_count || !m_active) {
                    timer.stop();
                    dev->setSamplesAdded(0);
                    emit finished(0);
                    QTimer::singleShot(100, this, SLOT(beginNewSweep()));
            }
        }
    }
}

void SessionItem::beginNewSweep()
{
    if (m_active) {
        m_session->flush();
        for (auto dev: m_devices) {
            dev->setSamplesAdded(0);
            for (auto chan: dev->m_channels) {
                chan->buildTxBuffer();
                for (auto sig: chan->m_signals) {
                    sig->m_buffer->startSweep();
                }
            }
            dev->write();
        }
        m_session->start(m_sample_count);
        timer.start(0);
    }
}

/// DeviceItem constructor
DeviceItem::DeviceItem(SessionItem* parent, Device* dev):
QObject(parent),
m_device(dev),
m_samples_added(0)
{
    auto dev_info = dev->info();

    for (unsigned ch_i=0; ch_i < dev_info->channel_count; ch_i++) {
        m_channels.append(new ChannelItem(this, dev, ch_i));
    }
}

void DeviceItem::write()
{
    for (auto chn: m_channels) {
        unsigned mode = chn->property("mode").toUInt();
        if (mode == SVMI || mode == SIMV) {
            m_device->write(chn->m_tx_data, chn->m_index, true);
        }
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

void ChannelItem::buildTxBuffer()
{
    SignalItem *txSignal;

    switch (m_mode) {
        case SVMI:
            txSignal = m_signals[0];
            break;
        case SIMV:
            txSignal = m_signals[1];
            break;
        default:
            return;
    }

    QString src = txSignal->getSrc()->property("src").toString();
    float v1 = txSignal->getSrc()->property("v1").toFloat();
    float v2 = txSignal->getSrc()->property("v2").toFloat();
    float period = txSignal->getSrc()->property("period").toFloat();
    float phase = txSignal->getSrc()->property("phase").toFloat();
    float duty = txSignal->getSrc()->property("duty").toFloat();

    m_tx_data.resize(0);

    if (src == "constant")
        txSignal->m_signal->constant(m_tx_data, 1, v1);
    else if (src == "square")
        txSignal->m_signal->square(m_tx_data, period, v1, v2, period, phase, duty);
    else if (src == "sawtooth")
        txSignal->m_signal->sawtooth(m_tx_data, period, v1, v2, period, phase);
    else if (src == "stairstep")
        txSignal->m_signal->stairstep(m_tx_data, period, v1, v2, period, phase);
    else if (src == "sine")
        txSignal->m_signal->sine(m_tx_data, period, v1, v2, period, phase);
    else if (src == "triangle")
        txSignal->m_signal->triangle(m_tx_data, period, v1, v2, period, phase);
}

/// SignalItem constructor
SignalItem::SignalItem(ChannelItem* parent, int index, Signal* sig):
QObject(parent),
m_index(index),
m_channel(parent),
m_signal(sig),
m_buffer(new FloatBuffer(this)),
m_src(new SrcItem(this)),
m_measurement(0.0),
m_peak_to_peak(0.0),
m_rms(0.0),
m_mean(0.0)
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
void SignalItem::updateMeasurementMean(){
    m_mean = m_buffer->mean();
    meanChanged(m_mean);
}

void SignalItem::updateMeasurementLatest(){
/*
    m_measurement = m_signal->measure_instantaneous();
    measurementChanged(m_measurement);
*/
}

void SignalItem::updatePeakToPeak() {
    m_peak_to_peak = m_buffer->peak_to_peak();
    peakChanged(m_peak_to_peak);
}

void SignalItem::updateRms() {
    m_rms = m_buffer->rms();
    rmsChanged(m_rms);
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
   /*time
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
*/
}
