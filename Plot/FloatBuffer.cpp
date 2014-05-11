#include "FloatBuffer.h"

FloatBuffer::FloatBuffer(QObject *parent):
	QObject(parent),
	secondsPerSample(0.00001)
	{}

qreal FloatBuffer::duration() {
	return data.size() * secondsPerSample;
}

void FloatBuffer::fill_sine(float t, float freq, float len) {
	secondsPerSample = t;
	unsigned samples = round(len/secondsPerSample);
	data.resize(samples);
	for (unsigned i=0; i<samples; i++) {
		data[i] = sinf(M_PI * freq * secondsPerSample * i);
	}
}

void FloatBuffer::fill_square(float t, float freq, float len) {
	secondsPerSample = t;
	unsigned samples = round(len/secondsPerSample);
	data.resize(samples);
	for (unsigned i=0; i<samples; i++) {
		data[i] = (fmod(i*secondsPerSample*freq*2, 2) >= 1)*2.0 - 1.0;
	}
}

void FloatBuffer::fill_sawtooth(float t, float freq, float len) {
	secondsPerSample = t;
	unsigned samples = round(len/secondsPerSample);
	data.resize(samples);
	for (unsigned i=0; i<samples; i++) {
		data[i] = fmod(i*secondsPerSample*freq*2, 2) - 1.0;
	}
}

void FloatBuffer::jitter(float amount) {
	for (unsigned i=0; i<data.size(); i++) {
		data[i] += (rand()/(float)RAND_MAX - 0.5) * amount;
	}
}