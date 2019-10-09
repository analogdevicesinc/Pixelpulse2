#include <QStandardPaths>
#include <QDir>

#include "SMU.h"
#include "Plot/PhosphorRender.h"
#include "Plot/FloatBuffer.h"
#include "utils/fileio.h"
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

QString SessionItem::getTmpPathForFirmware()
{
    QString path = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    path += "/pixelpulse2/m1k_firmware";
    QDir dir(path);
    if (!dir.exists())
        dir.mkpath(".");
   return dir.path();
}

SessionItem::SessionItem():
m_session(new Session),
m_active(false),
m_continuous(false),
m_sample_rate(0),
m_sample_count(0),
m_queue_size(1000000)
{
    connect(this, &SessionItem::finished, this, &SessionItem::onFinished, Qt::QueuedConnection);
    connect(this, &SessionItem::attached, this, &SessionItem::onAttached, Qt::QueuedConnection);
    connect(this, &SessionItem::detached, this, &SessionItem::onDetached, Qt::QueuedConnection);

    connect(this, &SessionItem::sampleCountChanged, this, &SessionItem::onSampleCountChanged);
    connect(&timer, SIGNAL(timeout()), this, SLOT(getSamples()));

    std::thread usb_thread(usb_handle_thread_method, this);
    usb_thread.detach();

    sweepTimer = new QTimer();
    connect(sweepTimer,SIGNAL(timeout()),SLOT(beginNewSweep()));
}

SessionItem::~SessionItem() {
    Q_ASSERT(m_devices.size() == 0);
	delete sweepTimer;
}


/// called on initialisation
void SessionItem::openAllDevices()
{
    m_session->m_queue_size = m_queue_size;
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
    m_session->flush();
    m_session->configure(m_sample_rate);
    m_continuous = continuous;

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
    if (continuous)
        m_session->start(0);
    else{
        m_session->start(m_sample_count);
    }

    timer.start(0);
    m_active = true;
    emit activeChanged();
}

/// handles hotplug attach condition
/// runs on UI thread
/// triggered by libUSB callback over Queue -- removed
/// triggered by the responsible USB checker thread
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
}

/// handles hotplug detach condition
/// runs on UI thread
/// triggered by libUSB callback over Queue -- removed
/// triggered by the responsible USB checker thread
void SessionItem::onDetached(Device* device){
    if (m_active) {
            this->cancel();
    }
    for (auto dev: m_devices) {
         if (!dev->m_device->m_serial.compare(device->m_serial)) {
                m_devices.removeOne(dev);
                delete dev;
         }
    }

    devicesChanged();
}

void SessionItem::onSampleCountChanged(){
    restart();
}

void SessionItem::handleDownloadedFirmware()
{
    FileIO f;
    f.writeRawByFilename(getTmpPathForFirmware() + "/firmware.bin",  m_firmware_fd->downloadedData());
    emit firmwareDownloaded();
    disconnect(m_firmware_fd, SIGNAL(downloaded()), this, SLOT(handleDownloadedFirmware()));
}

void SessionItem::cancel() {
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
    if (!m_active)
        return;

    if(sweepTimer){
        sweepTimer->stop();
    }

    if (m_continuous)
        timer.stop();

    if(timer.isActive()){
        timer.stop();
    }
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
    if(sweepTimer){
        sweepTimer->stop();
    }
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
    QUrl firmwareUrl(url);
    m_firmware_fd = new FileDownloader(firmwareUrl, this);
    connect(m_firmware_fd, SIGNAL (downloaded()), this, SLOT (handleDownloadedFirmware()));
}

QString SessionItem::flash_firmware(QString url){
    QString ret = "";
    int flashed = 0;
    try{
        flashed = m_session->flash_firmware(url.toStdString());
    }
    catch(std::runtime_error &e){
        ret = e.what();
    }

    return ret;
}
void SessionItem::getSamples()
{
    if (!m_active)
        return;

    for (auto dev: m_devices) {
        std::vector<std::array<float, 4>> rxbuf;
        int ret = 0;
        try {
            ret = dev->m_device->read(rxbuf, 10000);
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
                    m_session->end();
                    emit finished(0);
                    sweepTimer->setInterval(100);
                    sweepTimer->setSingleShot(true);
                    sweepTimer->start();
            }
        }
    }
}

void SessionItem::beginNewSweep()
{
    qDebug()<<"Begin new Sweep\n";
    if (m_active) {
        //m_session->flush();
        for (auto dev: m_devices) {
            dev->setSamplesAdded(0);
            for (auto chan: dev->m_channels) {
                dev->m_device->set_mode(chan->m_index, chan->m_mode);
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

int SessionItem::programmingModeDeviceExists(){
    std::vector<libusb_device*> samba_devs;

    return m_session->scan_samba_devs(samba_devs);
}

void SessionItem::usb_handle_thread_method(SessionItem *session_item)
{
    std::vector < Device* > last_devices;

    while (true) {
        std::this_thread::sleep_for(std::chrono::milliseconds(2000));
        session_item->m_session->scan();

        std::vector < Device* > available_devices = session_item->m_session->m_available_devices;

        //check if there is any disconnected device
        for (auto other_device : last_devices) {
            bool found = 0;

            for (auto device : available_devices) {
                if (!device->m_serial.compare(other_device->m_serial)) {
                    found = 1;
                    break;
                }
            }

            if (!found) {
                emit session_item->detached(other_device);
                last_devices.erase(remove(last_devices.begin(), last_devices.end(), other_device), last_devices.end());
            }
        }

        //check if there is any new connected device
        for (auto device : available_devices) {
            bool found = 0;

            for (auto other_device : last_devices) {
                if (!device->m_serial.compare(other_device->m_serial)) {
                    found = 1;
                    break;
                }
            }

            if (!found) {
                emit session_item->attached(device);
            }
            else {
                available_devices.erase(remove(available_devices.begin(), available_devices.end(), device), available_devices.end());
                delete device;
            }
        }

        last_devices.insert(last_devices.end(), available_devices.begin(), available_devices.end());
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


void DeviceItem::write(ChannelItem* channel)
{
    for (auto chn: m_channels) {
        if(channel == nullptr || chn == channel){
            unsigned mode = chn->property("mode").toUInt();
            if (mode == SVMI || mode == SIMV) {
                try{
                    m_device->write(chn->m_tx_data, chn->m_index, true);
                }catch (std::system_error& e) {
                    qDebug() << "exception:" << e.what();
                }
            }
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
    timer = new TimerItem(this,parent);
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


    qDebug()<<"v1:"<<v1<<" |v2:"<<v2<<" |period:"<<period<<" |phase:"<<phase<<" |duty:"<<duty<<"\n";
    int samples = abs(period);

    m_tx_data.resize(0);
    if (src == "constant")
        txSignal->m_signal->constant(m_tx_data, 1, v1);
    else if (src == "square")
        txSignal->m_signal->square(m_tx_data, samples, v1, v2, period, phase, duty);
    else if (src == "sawtooth")
        txSignal->m_signal->sawtooth(m_tx_data, samples, v1, v2, period, phase);
    else if (src == "stairstep")
        txSignal->m_signal->stairstep(m_tx_data, samples, v1, v2, period, phase);
    else if (src == "sine")
        txSignal->m_signal->sine(m_tx_data, samples, v1, v2, period, phase);
    else if (src == "triangle")
        txSignal->m_signal->triangle(m_tx_data, samples, v1, v2, period, phase);
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
    //qDebug()<<"update SrcItem";nt samples = period;
   //time
/*    Src v = CONSTANT;
    if (m_src == "constant")        v = CONSTANT;
//    else if (m_src == "buffer")     v = BUFFER;
    //else if (m_src == "callback")   v = SRC_CALLBACK;
    else if (m_src == "square")     v = SQUARE;
    else if (m_src == "sawtooth")   v = SAWTOOTH;
    else if (m_src == "stairstep") v = STAIRSTEP;
    else if (m_src == "sine")       v = SINE;
    else if (m_src == "triangle")   v = TRIANGLE;
    else return;

    m_parent->m_signal->m

    m_parent->m_signal->m_src        = v;
    m_parent->m_signal->m_src_v1     = m_v1;
    m_parent->m_signal->m_src_v2     = m_v2;
    m_parent->m_signal->m_src_period = m_period;
    m_parent->m_signal->m_src_phase  = m_phase;
    m_parent->m_signal->m_src_duty   = m_duty;
*/
}

TimerItem::TimerItem(ChannelItem *chan,DeviceItem *dev):
channel(chan),
device(dev),
changeBufferTimer(new QTimer),
thread(new QThread)
{
    changeBufferTimer->setSingleShot(true);
    changeBufferTimer->setInterval(100);
    connect(changeBufferTimer,SIGNAL(timeout()), this, SLOT(needChangeBuffer()));

    connect(thread,SIGNAL(finished()),this,SLOT(clean()));

    for(auto sig : channel->m_signals){
        connect(sig->m_src,&SrcItem::changed,this,&TimerItem::parameterChanged);
    }

    session = (SessionItem*)device->parent();

}

void TimerItem::parameterChanged(){

    if(session->isContinuous())
    {
        //restart the timer if needed
        if(changeBufferTimer->isActive()){
            changeBufferTimer->stop();
        }
        changeBufferTimer->start();
    }
}

void TimerItem::needChangeBuffer(){
    bc = new BufferChanger(channel,device);
    connect(thread, SIGNAL(started()), bc, SLOT(changeBuffer()));

    thread->start();
    bc->moveToThread(thread);
}

void TimerItem::clean(){
    disconnect(thread,SIGNAL(started()),bc,SLOT(changeBuffer()));
    delete bc;
}

BufferChanger::BufferChanger(ChannelItem *chan,DeviceItem *dev):
channel(chan),
device(dev)
{}

void BufferChanger::changeBuffer(){
    channel->buildTxBuffer();

    device->write(channel);
    this->thread()->quit();
}
