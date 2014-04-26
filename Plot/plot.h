#include <QtQuick/QQuickItem>

class PhosphorRender : public QQuickItem
{
    Q_OBJECT

    Q_PROPERTY(qreal p READ p WRITE setP NOTIFY pChanged)
    Q_PROPERTY(int segmentCount READ segmentCount WRITE setSegmentCount NOTIFY segmentCountChanged)

public:
    PhosphorRender(QQuickItem *parent = 0);
    ~PhosphorRender();

    QSGNode *updatePaintNode(QSGNode *, UpdatePaintNodeData *);

    qreal p() const { return m_p; }

    int segmentCount() const { return m_segmentCount; }

    void setP(qreal p);

    void setSegmentCount(int count);

signals:
    void pChanged( qreal p);

    void segmentCountChanged(int count);

private:
    qreal m_p;

    int m_segmentCount;
};