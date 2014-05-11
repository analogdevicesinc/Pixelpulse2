#include "PhosphorRender.h"
#include <cmath>

#include <QtQuick/qsgnode.h>
#include <QtQuick/qsgflatcolormaterial.h>
#include <iostream>

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

    void updateState(const RenderState &state, QSGMaterial *newMaterial, QSGMaterial *oldMaterial);

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

    QMatrix4x4 transformation;
    float pointSize;
};

void Shader::updateState(const RenderState &state, QSGMaterial *newMaterial, QSGMaterial *oldMaterial)
{
    Q_ASSERT(program()->isLinked());
    
    Material* m = static_cast<Material*>(newMaterial);
    program()->setUniformValue(m_id_matrix, state.combinedMatrix()*m->transformation);
    
    if (state.isOpacityDirty()) {
        program()->setUniformValue(m_id_opacity, state.opacity());
    }

    glBlendFunc(GL_ONE, GL_ONE);
    //glHint(GL_POINT_SMOOTH_HINT, GL_NICEST);
    glPointSize(1.8);
    glPointSize(m->pointSize);
}

PhosphorRender::PhosphorRender(QQuickItem *parent)
    : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
}

PhosphorRender::~PhosphorRender()
{
}

QSGNode *PhosphorRender::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    if (!m_buffer) {
        return 0;
    }

    QSGGeometryNode *node = 0;
    QSGGeometry *geometry = 0;
    Material *material = 0;

    unsigned n_points = m_buffer->count_points_between(m_xmin, m_xmax);

    if (!oldNode) {
        node = new QSGGeometryNode;
        geometry = new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), n_points);
        geometry->setLineWidth(2);
        geometry->setDrawingMode(GL_POINTS);
        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);
        material = new Material;
        material->setFlag(QSGMaterial::Blending);
        node->setMaterial(material);
        node->setFlag(QSGNode::OwnsMaterial);
    } else {
        node = static_cast<QSGGeometryNode *>(oldNode);
        geometry = node->geometry();
        geometry->allocate(n_points);
        material = static_cast<Material*>(node->material());
    }

    QRectF bounds = boundingRect();

    material->transformation.setToIdentity();
    material->transformation.scale(bounds.width()/(m_xmax - m_xmin), bounds.height()/(m_ymin - m_ymax));
    material->transformation.translate(-m_xmin, m_ymin);

    material->pointSize = m_pointSize;
    
    m_buffer->to_vertex_data(m_xmin, m_xmax, geometry->vertexDataAsPoint2D(), n_points);
    node->markDirty(QSGNode::DirtyGeometry);

    return node;
}

