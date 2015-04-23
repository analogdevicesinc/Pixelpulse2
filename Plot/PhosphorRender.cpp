#include "PhosphorRender.h"
#include <cmath>

#include <QtQuick/qsgnode.h>
#include <QtQuick/qsgflatcolormaterial.h>
#include <iostream>

PhosphorRender::PhosphorRender(QQuickItem *parent)
    : QQuickItem(parent), m_ybuffer(NULL), m_xbuffer(NULL),
    m_xmin(0), m_xmax(1), m_ymin(0), m_ymax(1),
    m_color(0.03*255, 0.3*255, 0.03*255, 1*255)
{
    setFlag(ItemHasContents, true);
}

PhosphorRender::~PhosphorRender()
{
}

QSGNode *PhosphorRender::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    if (!m_ybuffer) {
        return 0;
    }

    QSGGeometryNode *node = 0;
    QSGTransformNode *transformNode = 0;
    QSGGeometry *geometry = 0;
    QSGFlatColorMaterial *material = 0;

    unsigned n_points;

    if (m_xbuffer) {
        n_points = std::min(m_xbuffer->size(), m_ybuffer->size());
    } else {
        n_points = m_ybuffer->countPointsBetween(m_xmin, m_xmax);
    }

    if (!oldNode) {
        node = new QSGGeometryNode;
        geometry = new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), n_points);
        geometry->setLineWidth(3);
        geometry->setDrawingMode(GL_LINE_STRIP);
        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);
        material = new QSGFlatColorMaterial;
        node->setMaterial(material);
        node->setFlag(QSGNode::OwnsMaterial);

        transformNode = new QSGTransformNode;
        transformNode->appendChildNode(node);
    } else {
        transformNode = static_cast<QSGTransformNode *>(oldNode);
        node = static_cast<QSGGeometryNode *>(transformNode->firstChild());
        material = static_cast<QSGFlatColorMaterial*>(node->material());
        geometry = node->geometry();
        geometry->allocate(n_points);
    }

    QRectF bounds = boundingRect();
    QMatrix4x4 matrix;
    matrix.scale(bounds.width()/(m_xmax - m_xmin), bounds.height()/(m_ymin - m_ymax));
    matrix.translate(-m_xmin, -m_ymax);
    transformNode->setMatrix(matrix);
    transformNode->markDirty(QSGNode::DirtyMatrix);

    material->setColor(m_color);

    auto verticies = geometry->vertexDataAsPoint2D();
    if (m_xbuffer) {
        for (unsigned i=0; i<n_points; i++) {
            verticies[i].set(m_xbuffer->get(i), m_ybuffer->get(i));
        }
    } else {
        m_ybuffer->toVertexData(m_xmin, m_xmax, verticies, n_points);
    }
    node->markDirty(QSGNode::DirtyGeometry|QSGNode::DirtyMaterial);
    return transformNode;
}
