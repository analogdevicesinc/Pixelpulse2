#include "FloatBuffer.h"

FloatBuffer::FloatBuffer(QObject *parent):
	QObject(parent),
	m_secondsPerSample(0.00001)
	{}

void FloatBuffer::fillSine(float t, float freq, float len) {
	m_secondsPerSample = t;
	unsigned samples = round(len/m_secondsPerSample);
	m_data.resize(samples);
	for (unsigned i=0; i<samples; i++) {
		m_data[i] = sinf(M_PI * freq * m_secondsPerSample * i);
	}
	Q_EMIT dataChanged();
}

void FloatBuffer::fillSquare(float t, float freq, float len) {
	m_secondsPerSample = t;
	unsigned samples = round(len/m_secondsPerSample);
	m_data.resize(samples);
	for (unsigned i=0; i<samples; i++) {
		m_data[i] = (fmod(i*m_secondsPerSample*freq*2, 2) >= 1)*2.0 - 1.0;
	}
	Q_EMIT dataChanged();
}

void FloatBuffer::fillSawtooth(float t, float freq, float len) {
	m_secondsPerSample = t;
	unsigned samples = round(len/m_secondsPerSample);
	m_data.resize(samples);
	for (unsigned i=0; i<samples; i++) {
		m_data[i] = fmod(i*m_secondsPerSample*freq*2, 2) - 1.0;
	}
	Q_EMIT dataChanged();
}

void FloatBuffer::jitter(float amount) {
	for (unsigned i=0; i<m_data.size(); i++) {
		m_data[i] += (rand()/(float)RAND_MAX - 0.5) * amount;
	}
	Q_EMIT dataChanged();
}