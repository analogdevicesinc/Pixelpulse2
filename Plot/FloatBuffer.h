#pragma once
#include <QObject>
#include <vector>
#include <math.h>
#include <QtQuick/qsgnode.h>

class FloatBuffer : public QObject
{
	Q_OBJECT
    Q_PROPERTY(qreal duration READ duration NOTIFY durationChanged)

public:
    FloatBuffer(QObject *parent = 0);

	unsigned count_points_between(double start, double end) {
		return time_to_index(end) - time_to_index(start);
	}

	void to_vertex_data(double start, double end, QSGGeometry::Point2D *vertices, unsigned n_verticies) {
		unsigned i_min = time_to_index(start);
		unsigned i_max = time_to_index(end);

		for (unsigned i=i_min, j=0; i<i_max && j<n_verticies; i++, j++) {
			vertices[j].set(index_to_time(i), data[i]);
		}
	}

	qreal duration();

	Q_INVOKABLE void fill_sine(float t, float freq, float len);
	Q_INVOKABLE void fill_square(float t, float freq, float len);
	Q_INVOKABLE void fill_sawtooth(float t, float freq, float len);
	Q_INVOKABLE void jitter(float amount);

signals:
	void durationChanged(qreal duration);

public slots:
    QObject * getObject() {
    	return new FloatBuffer();
    }

private:
	float secondsPerSample;
	std::vector<float> data;

	unsigned time_to_index(double time) {
		if (time < 0) time = 0;
		unsigned t = time / secondsPerSample;
		if (t > data.size()) return data.size();
		return t;
	}

	double index_to_time(unsigned index) {
		return index*secondsPerSample;
	}
};