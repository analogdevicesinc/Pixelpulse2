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

	unsigned countPointsBetween(double start, double end) {
		return timeToIndex(end) - timeToIndex(start);
	}

	void toVertexData(double start, double end, QSGGeometry::Point2D *vertices, unsigned n_verticies) {
		unsigned i_min = timeToIndex(start);
		unsigned i_max = timeToIndex(end);

		for (unsigned i=i_min, j=0; i<i_max && j<n_verticies; i++, j++) {
			vertices[j].set(indexToTime(i), m_data[wrapIndex(i)]);
		}
	}

	qreal duration() {
		return m_data.size() * m_secondsPerSample;
	}

	Q_INVOKABLE void fillSine(float t, float freq, float len);
	Q_INVOKABLE void fillSquare(float t, float freq, float len);
	Q_INVOKABLE void fillSawtooth(float t, float freq, float len);
	Q_INVOKABLE void jitter(float amount);

	Q_INVOKABLE void rotate(unsigned samples) {
		m_split = (m_split + samples) % m_data.size();
		dataChanged();
	}

signals:
	void durationChanged(qreal duration);
	void dataChanged();

public slots:
    QObject * getObject() {
    	return new FloatBuffer();
    }

private:
	float m_secondsPerSample;
	std::vector<float> m_data;
	unsigned m_split;

	unsigned unwrapIndex(unsigned index) {
		if (index >= m_split) {
			return (index - m_split);
		} else {
			return (index + (m_data.size() - m_split));
		}
	}

	unsigned wrapIndex(unsigned index) {
		return (index + m_split) % m_data.size();
	}

	unsigned timeToIndex(double time) {
		if (time < 0) time = 0;
		unsigned t = time / m_secondsPerSample;
		if (t > m_data.size()) return m_data.size();
		return t;
	}

	double indexToTime(unsigned index) {
		return index * m_secondsPerSample;
	}
};
