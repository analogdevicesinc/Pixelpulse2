#pragma once
#include <QObject>
#include <deque>
#include <numeric>
#include <math.h>
#include <QtQuick/qsgnode.h>
#include <iostream>
#include <array>

using namespace std;
class FloatBuffer : public QObject
{
    Q_OBJECT

public:
    FloatBuffer(QObject *parent = 0);
	// this access mechanism is slow
	//Q_PROPERTY( QList<qreal> qData READ getData NOTIFY dataChanged );
    unsigned countPointsBetween(double start, double end) {
        return timeToIndex(end) - timeToIndex(start);
    }

    unsigned size() {
        return m_length;
    }

    Q_INVOKABLE unsigned long ignoredFirstSamplesCount()
    {
        return m_first_samples_ignored;
    }

    Q_INVOKABLE void setIgnoredFirstSamplesCount(unsigned long count)
    {
        m_first_samples_ignored = count;
    }

    Q_INVOKABLE float get(unsigned i) {
        return m_data[wrapIndex(i)];
    }

// Not needed anymore
//    void shift(float d) {
//        m_data[(m_start + m_length) % m_data.size()] = d;

//        if (m_length < m_data.size()) {
//            m_length += 1;
//        } else {
//            m_start = (m_start + 1) % m_data.size();
//        }
//    }

    void append_samples(const std::vector<std::array<float, 4>>& samples, int signal_index)
    {
        size_t free_buffer_space = m_data.size() - m_start_test;
        int num_samples_to_add = std::min(samples.size(), free_buffer_space);

        for (int i = 0; i < num_samples_to_add; i++) {
            m_data[(m_start_test +  i) % m_data.size()] = samples[i][signal_index];
        }
        m_start_test += num_samples_to_add;
        if (m_length < m_start_test)
            m_length = m_start_test;

        emit dataChanged();
    }

    void append_samples_circular(const std::vector<std::array<float, 4>>& samples, int signal_index)
    {
        int num_samples_to_add = samples.size();
        if(m_length > maxSize){
            m_data.erase(m_data.begin(),std::min(m_data.end(), m_data.begin()+num_samples_to_add));
            for(int i=0;i<num_samples_to_add;i++){
                m_data.push_back(samples[i][signal_index]);
            }
        }
        else{
            for (int i = 0; i < num_samples_to_add; i++) {
                m_data[(m_start_test +  i) % m_data.size()] = samples[i][signal_index];
            }

            m_start_test += num_samples_to_add;
            if (m_length < m_start_test)
                m_length = m_start_test;
        }

        //qDebug()<<"m_len: "<<m_length<<"m_start:"<<m_start_test<<"\n";

        emit dataChanged();
    }

    void toVertexData(double start, double end, QSGGeometry::Point2D *vertices, unsigned n_verticies) {
        unsigned i_min = timeToIndex(start);
        unsigned i_max = timeToIndex(end);

        const unsigned diff = i_max - i_min;
         //qDebug()<<"From Index "<<i_min<<" to index "<<i_max<<"with "<<n_verticies<<"\n";
         //qDebug()<<"diff="<<diff<<"\n";
         if(diff <= n_verticies){

             for (unsigned i=i_min, j=0; i<i_max && j<n_verticies; i++, j++) {
                 vertices[j].set(indexToTime(i), m_data[wrapIndex(i)]);
             }
         }
         else{
             double inc = i_min;
             double incValue = (double)diff / n_verticies;
             //qDebug()<<"diff:"<<diff<<";incValue:"<<incValue;
             for (unsigned i=i_min, j=0; i<i_max && j<n_verticies;j++) {
                 vertices[j].set(indexToTime(i), m_data[wrapIndex(i)]);
                 inc += incValue;
                 i = (unsigned)inc;
             }
        }
    }

    void setRate(float secondsPerSample) {
        m_secondsPerSample = secondsPerSample;
        dataChanged();
    }

    void allocate(unsigned length) {
        m_data.resize(length);
        if (m_length > length) {
            m_length = length;
            dataChanged();
        }
        maxSize = length;
    }

//not needed anymore
//    float* data() {
//        return m_data.data();
//    }

    Q_INVOKABLE QList<qreal> getData() {
            QList<qreal> qData;
            qData.reserve(m_length);
            for (unsigned i=0; i < m_length; i++) {
                    qreal d = get(i);
                    qData.append(d);
            }
            return qData;
    }

    void startSweep() {
        // When switching from continuous to repeated-sweep mode, stop acting like a ring buffer
        if (m_start != 0) {
            m_start = 0;
            m_length = 0;
            dataChanged();
        }

        m_start_test = 0;
    }

// Not needed anymore
//    void sweepProgress(unsigned sample) {
//        if (m_length < sample) {
//             m_length = sample;
//        }
//        dataChanged();
//    }

// Not needed anymore
//    void continuousProgress(unsigned sample) {
//        Q_UNUSED(sample);
//        // m_start and m_length are adjusted in shift()
//        dataChanged();
//    }


    template<typename T>
    struct square
    {
        T operator()(const T& Left, const T& Right) const
        {
            return (Left + Right*Right);
        }
    };

    double rms() {
        std::vector<float> tmp = dif_mean(mean());
        return sqrt(accumulate(tmp.begin(), tmp.end(), 0.0, square<long double>()) / tmp.size());
    }

    double peak_to_peak(){
        if(m_data.size() != 0) {
            return *std::max_element(data_begin(), m_data.end()) - *std::min_element(data_begin(), m_data.end());
        }
        return 0;
    }

    std::vector<float> dif_mean(double avg){
        std::vector<float> tmp;
        for (std::deque<float>::iterator it = data_begin(); it != m_data.end(); ++it){
                    tmp.push_back(*it - avg);
        }
        return tmp;
    }

    double mean() {
        return accumulate(data_begin(), m_data.end(), 0.0) / data_size();
    }

signals:
    void dataChanged();

public slots:
    QObject * getObject() {
        return new FloatBuffer();
    }

private:
    float m_secondsPerSample;
    std::deque<float> m_data;
    size_t m_start;
    size_t m_length;
    size_t m_first_samples_ignored;
    size_t m_start_test;
    size_t maxSize;

    unsigned unwrapIndex(unsigned index) {
        if (index >= m_start) {
            return (index - m_start);
        } else {
            return (index + (m_data.size() - m_start));
        }
    }

    unsigned wrapIndex(unsigned index) {
        return (index + m_start + m_first_samples_ignored) % m_data.size();
    }

    unsigned timeToIndex(double time) {
        if (time < 0) time = 0;
        unsigned t = time / m_secondsPerSample;
        if (t > m_length) return m_length;
        return t;
    }

    double indexToTime(unsigned index) {
        return index * m_secondsPerSample;
    }

    /* A number of samples at the beginning of the buffer can be ignored by
     * the application. Use data_begin() and data_size() to access the rest of data */
    std::deque<float>::iterator data_begin()
    {
       return (m_data.begin() + m_first_samples_ignored);
    }

    float data_size()
    {
       return (m_data.size() - m_first_samples_ignored);
    }
};
