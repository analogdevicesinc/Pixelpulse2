#include "plot.h"
#include <cmath>

#include <QtQuick/qsgnode.h>
#include <QtQuick/qsgflatcolormaterial.h>

class Shader : public QSGMaterialShader
{
public:
    const char *vertexShader() const {
        return
        "attribute highp vec4 vertex;          \n"
        "uniform highp mat4 matrix;            \n"
        "void main() {                         \n"
        "    gl_Position = matrix * vertex;    \n"
        "}";
    }

    const char *fragmentShader() const {
        return
        "uniform lowp float opacity;                            \n"
        "void main() {                                          \n"
        "    gl_FragColor = vec4(0.03, 0.3, 0.03, 1) * opacity; \n"
        "}";
    }

    char const *const *attributeNames() const
    {
        static char const *const names[] = { "vertex", 0 };
        return names;
    }

    void initialize()
    {
        QSGMaterialShader::initialize();
        m_id_matrix = program()->uniformLocation("matrix");
        m_id_opacity = program()->uniformLocation("opacity");
    }

    void updateState(const RenderState &state, QSGMaterial *newMaterial, QSGMaterial *oldMaterial)
    {
        Q_ASSERT(program()->isLinked());
        if (state.isMatrixDirty())
            program()->setUniformValue(m_id_matrix, state.combinedMatrix());
        if (state.isOpacityDirty())
            program()->setUniformValue(m_id_opacity, state.opacity());
        //glEnable( GL_POINT_SMOOTH );
        glBlendFunc(GL_ONE, GL_ONE);
        //glHint(GL_POINT_SMOOTH_HINT, GL_NICEST);
        glPointSize(1.8);
    }

    void deactivate() {
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    }

private:
    int m_id_matrix;
    int m_id_opacity;
};

class Material : public QSGMaterial
{
public:
    QSGMaterialType *type() const { static QSGMaterialType type; return &type; }
    QSGMaterialShader *createShader() const { return new Shader; }
    QSGMaterial::Flags  flags() const { return QSGMaterial::Blending; }
};

PhosphorRender::PhosphorRender(QQuickItem *parent)
    : QQuickItem(parent)
    , m_p(0)
    , m_segmentCount(100000)
{
    setFlag(ItemHasContents, true);
}

PhosphorRender::~PhosphorRender()
{
}

void PhosphorRender::setP(qreal p)
{
    if (p == m_p)
        return;

    m_p = p;
    emit pChanged(p);
    update();
}

void PhosphorRender::setSegmentCount(int count)
{
    if (m_segmentCount == count)
        return;

    m_segmentCount = count;
    emit segmentCountChanged(count);
    update();
}

QSGNode *PhosphorRender::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    QSGGeometryNode *node = 0;
    QSGGeometry *geometry = 0;

    if (!oldNode) {
        node = new QSGGeometryNode;
        geometry = new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), m_segmentCount);
        geometry->setLineWidth(2);
        geometry->setDrawingMode(GL_POINTS);
        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);
        Material *material = new Material;
        material->setFlag(QSGMaterial::Blending);
        //material->setColor(QColor(255, 0, 0));
        node->setMaterial(material);
        node->setFlag(QSGNode::OwnsMaterial);
    } else {
        node = static_cast<QSGGeometryNode *>(oldNode);
        geometry = node->geometry();
        geometry->allocate(m_segmentCount);
    }

    QRectF bounds = boundingRect();
    QSGGeometry::Point2D *vertices = geometry->vertexDataAsPoint2D();
    for (int i = 0; i < m_segmentCount; ++i) {
        qreal t = i / qreal(m_segmentCount - 1);

        float x = bounds.x() + t * bounds.width() + rand()/(float)RAND_MAX * 3 - 1;
        float y;

        if (t < 0.3) {
            y = sinf(t*5000.0*(p()+0.01));
        } else if (t < 0.7) {
            y = fmod(t*2000.0*(p()+0.01), 2) - 1.0;
        } else {
            y = (fmod(t*2000.0*(p()+0.01), 2) >= 1) * 2 - 1.0;
        }

        y = bounds.y() + 20 + (y + 1)/2*(bounds.height()-20)+ rand()/(float)RAND_MAX - 1;

        vertices[i].set(x, y);
    }
    node->markDirty(QSGNode::DirtyGeometry);

    return node;
}