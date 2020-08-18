#include <QStandardPaths>
#include <QDir>
#include <iomanip>

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
m_queue_size(1000000),
m_data_logger(new DataLogger(-1)),
m_logging(0)
{
    connect(this, &SessionItem::finished, this, &SessionItem::onFinished, Qt::QueuedConnection);
    connect(this, &SessionItem::attached, this, &SessionItem::onAttached, Qt::QueuedConnection);
    connect(this, &SessionItem::detached, this, &SessionItem::onDetached, Qt::QueuedConnection);

    connect(this, &SessionItem::sampleCountChanged, this, &SessionItem::onSampleCountChanged);
    connect(this, &SessionItem::loggingChanged, this, &SessionItem::onLoggingChanged);
    connect(this, &SessionItem::sampleTimeChanged, this, &SessionItem::onSampleTimeChanged);
    connect(&timer, SIGNAL(timeout()), this, SLOT(getSamples()));

    std::thread usb_thread(usb_handle_thread_method, this);
    usb_thread.detach();

    sweepTimer = new QTimer();
    connect(sweepTimer,SIGNAL(timeout()),SLOT(beginNewSweep()));
}

SessionItem::~SessionItem() {
        Q_ASSERT(m_devices.size() == 0);
        delete sweepTimer;
        delete this->m_data_logger;
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

    if (m_logging == 1) {
        delete m_data_logger;
        m_data_logger = new DataLogger(m_sample_time);
    }

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
                m_session->remove(dev->m_device, true);
                devicesChanged();
                delete dev;
         }
    }
}

void SessionItem::onSampleCountChanged(){
    restart();
}

void SessionItem::onSampleTimeChanged() {
    m_data_logger->setSampleTime(m_sample_time);
}

void SessionItem::onLoggingChanged()
{
    if (m_logging == 0) {
        m_logging = 1;

        if (m_active) {
            delete m_data_logger;
            m_data_logger = new DataLogger(m_sample_time);
        }
    } else {
        m_logging = 0;
    }
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

            if (m_logging) {
                std::thread t1([=] {this->m_data_logger->addBulkData(dev, rxbuf);});
                t1.detach();
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
                if ((device->m_usb_addr.first == other_device->m_usb_addr.first) &&
			     (device->m_usb_addr.second == other_device->m_usb_addr.second) ) {
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
                if ((device->m_usb_addr.first == other_device->m_usb_addr.first) &&
			     (device->m_usb_addr.second == other_device->m_usb_addr.second) ) {
                    found = 1;
                    break;
                }
            }

            if (!found) {
                emit session_item->attached(device);
            }
            else {
                available_devices.erase(remove(available_devices.begin(), available_devices.end(), device), available_devices.end());
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

DataLogger::DataLogger(float sampleTime)
{
    //if created by a valid session (1s or 10s sample time), create the log file
    if (sampleTime != -1
            && !(fabs(sampleTime - 0.01) < 0.00001 || fabs(sampleTime - 0.1) < 0.00001)) {
        this->sampleTime = sampleTime;
        auto current_time = std::chrono::system_clock::now();
        std::time_t time = std::chrono::system_clock::to_time_t(current_time);
        createLoggingFolder();
        QString directory = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        string timeString = directory.toStdString() + "/logging/PP_Log_";
        timeString.append(modifyDateTime(std::ctime(&time)));
        timeString.append(".csv");
        fileStream.open(timeString.c_str(), std::ios::out);
        startTime = std::chrono::system_clock::now();
        lastLog = startTime;
        fileStream << "Timestamp,Device serial,Min V ch A,Min A ch A,Min V ch B,Min A ch B,Max V ch A,Max A ch A,Max V ch B,Max A ch B,Avg V ch A,Avg A ch A,Avg V ch B,Avg A ch B\n";
        fileStream.flush();
    }
}

string DataLogger::modifyDateTime(string dateTime)
{
    std::map < string, string > months = {{"Jan", "01"}, {"Feb", "02"}, {"Mar", "03"}, {"Apr", "04"}, {"May", "05"}, {"Jun", "06"},
                                          {"Jul", "07"}, {"Aug", "08"}, {"Sep", "09"}, {"Oct", "10"}, {"Nov", "11"}, {"Dec", "12"}};
    string year = dateTime.substr(20, 4);
    string month = months[dateTime.substr(4, 3)];
    string day = dateTime.substr(8, 2);
    if (std::stoi(day) < 10)
        day[0] = '0';
    string hour = dateTime.substr(11, 2);
    string minute = dateTime.substr(14, 2);
    string second = dateTime.substr(17, 2);
    return year + month + day + hour + minute + second;
}

void DataLogger::updateMinimum(DeviceItem* deviceItem, std::array<float, 4> samples)
{
    minimum[deviceItem][0] = std::min(samples[0], minimum[deviceItem][0]);
    minimum[deviceItem][1] = std::min(samples[1], minimum[deviceItem][1]);
    minimum[deviceItem][2] = std::min(samples[2], minimum[deviceItem][2]);
    minimum[deviceItem][3] = std::min(samples[3], minimum[deviceItem][3]);
}

void DataLogger::updateMaximum(DeviceItem * deviceItem, std::array<float, 4> samples)
{
    maximum[deviceItem][0] = std::max(samples[0], maximum[deviceItem][0]);
    maximum[deviceItem][1] = std::max(samples[1], maximum[deviceItem][1]);
    maximum[deviceItem][2] = std::max(samples[2], maximum[deviceItem][2]);
    maximum[deviceItem][3] = std::max(samples[3], maximum[deviceItem][3]);
}

void DataLogger::updateSum(DeviceItem * deviceItem, std::array<float, 4> samples)
{
    sum[deviceItem][0] += samples[0];
    sum[deviceItem][1] += samples[1];
    sum[deviceItem][2] += samples[2];
    sum[deviceItem][3] += samples[3];
}

std::array < float, 4 > DataLogger::computeAverage(DeviceItem * deviceItem)
{
    return {sum[deviceItem][0] / dataCounter[deviceItem], sum[deviceItem][1] / dataCounter[deviceItem],
                sum[deviceItem][2] / dataCounter[deviceItem], sum[deviceItem][3] / dataCounter[deviceItem]};
}

void DataLogger::resetData(DeviceItem* deviceItem)
{
    dataCounter[deviceItem] = 0;
    minimum[deviceItem] = {100, 100, 100, 100};
    maximum[deviceItem] = {-100, -100, -100, -100};
    sum[deviceItem] = {0, 0, 0, 0};
}

void DataLogger::addData(DeviceItem * deviceItem, std::array<float, 4> samples)
{
    m_logMutex.lock();
    if (dataCounter[deviceItem] == 0) {
        resetData(deviceItem);
    }

    dataCounter[deviceItem] ++;
    updateMinimum(deviceItem, samples);
    updateMaximum(deviceItem, samples);
    updateSum(deviceItem, samples);
    std::chrono::duration < double > timeDiff = std::chrono::system_clock::now() - lastLog;

    if (timeDiff.count() >= sampleTime) {
        lastLog = std::chrono::system_clock::now();
        //Log data for all available devices.
        for (auto pair : sum) {
            printData(pair.first);
            resetData(pair.first);
        }
    }
    m_logMutex.unlock();
}

void DataLogger::addBulkData(DeviceItem* deviceItem, std::vector<std::array<float, 4> > buff)
{
    for (auto sample : buff)
        addData(deviceItem, sample);
}

void DataLogger::printData(DeviceItem* deviceItem)
{
    string deviceSerial = deviceItem->m_device->m_serial;
    deviceSerial = deviceSerial.substr(deviceSerial.size() - 5, 5);
    std::chrono::duration < double > timeDiff = std::chrono::system_clock::now() - startTime;

    std::array < float, 4 > average = computeAverage(deviceItem);

    fileStream << setprecision(3) << fixed << timeDiff.count() << "," << deviceSerial << ","
                     << minimum[deviceItem][0] << "," << minimum[deviceItem][1] << "," << minimum[deviceItem][2] << "," << minimum[deviceItem][3] << ","
                     << maximum[deviceItem][0] << "," << maximum[deviceItem][1] << "," << maximum[deviceItem][2] << "," << maximum[deviceItem][3] << ","
                     << average[0] << "," << average[1] << "," << average[2] << "," << average[3] << '\n';
    fileStream.flush();
}

void DataLogger::setSampleTime(float sampleTime)
{
    this->sampleTime = sampleTime;
}

void DataLogger::createLoggingFolder()
{
    QString directory = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (!QDir(directory + "/logging").exists()) {
        QDir().mkpath(directory + "/logging");
    }
}
