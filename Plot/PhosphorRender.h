#pragma once

#include <QtQuick/QQuickItem>
#include "FloatBuffer.h"

class PhosphorRender : public QQuickItem
{
    Q_OBJECT

    Q_PROPERTY(FloatBuffer* buffer READ buffer WRITE setBuffer NOTIFY yBufferChanged)
    Q_PROPERTY(FloatBuffer* xBuffer READ xBuffer WRITE setXBuffer NOTIFY xBufferChanged)

    Q_PROPERTY(double xmin READ xmin WRITE setXmin NOTIFY xminChanged)
    Q_PROPERTY(double xmax READ xmax WRITE setXmax NOTIFY xmaxChanged)
    Q_PROPERTY(double ymin READ ymin WRITE setYmin NOTIFY yminChanged)
    Q_PROPERTY(double ymax READ ymax WRITE setYmax NOTIFY ymaxChanged)

    Q_PROPERTY(double pointSize READ pointSize WRITE setPointSize NOTIFY pointSizeChanged)


public:
    PhosphorRender(QQuickItem *parent = 0);
    ~PhosphorRender();

    QSGNode *updatePaintNode(QSGNode *, UpdatePaintNodeData *);

#define SETTER(PROP) \
    if (m_ ## PROP == PROP) return; \
    m_ ## PROP = PROP; \
    emit PROP ## Changed(PROP); \
    update();

    FloatBuffer* buffer() const { return m_ybuffer; }
    void setBuffer(FloatBuffer* ybuffer) {
        if (m_ybuffer != ybuffer) {
            if (m_ybuffer) {
                QObject::disconnect(m_ybuffer, &FloatBuffer::dataChanged, this, 0);
            }
            m_ybuffer = ybuffer;
            if (m_ybuffer) {
                QObject::connect(m_ybuffer, &FloatBuffer::dataChanged, this, &PhosphorRender::update);
            }
            emit yBufferChanged(m_ybuffer);
            update();
        }
    }

    FloatBuffer* xBuffer() const { return m_xbuffer; }
    void setXBuffer(FloatBuffer* xbuffer) {
        if (m_xbuffer) {
            QObject::disconnect(m_xbuffer, &FloatBuffer::dataChanged, this, 0);
        }
        m_xbuffer = xbuffer;
        if (m_xbuffer) {
            QObject::connect(m_xbuffer, &FloatBuffer::dataChanged, this, &PhosphorRender::update);
        }
        emit xBufferChanged(m_xbuffer);
        update();
    }


    double xmin() const { return m_xmin; }
    void setXmin(double xmin) { SETTER(xmin) }

    double xmax() const { return m_xmax; }
    void setXmax(double xmax) { SETTER(xmax) }

    double ymin() const { return m_ymin; }
    void setYmin(double ymin) { SETTER(ymin) }

    double ymax() const { return m_ymax; }
    void setYmax(double ymax) { SETTER(ymax) }

    double pointSize() const { return m_pointSize; }
    void setPointSize(double pointSize) { SETTER(pointSize) }

signals:
    void xBufferChanged(FloatBuffer* b);
    void yBufferChanged(FloatBuffer* b);
    void xminChanged(double v);
    void xmaxChanged(double v);
    void yminChanged(double v);
    void ymaxChanged(double v);
    void pointSizeChanged(double v);

private:
    FloatBuffer* m_ybuffer;
    FloatBuffer* m_xbuffer;

    double m_xmin;
    double m_xmax;
    double m_ymin;
    double m_ymax;
    double m_pointSize;
};
