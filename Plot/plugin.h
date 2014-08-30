#pragma once
#include <QQmlExtensionPlugin>

#include "PhosphorRender.h"
#include "FloatBuffer.h"


class PlotPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")
public:
    void registerTypes(const char *uri)
    {
        qmlRegisterType<PhosphorRender>(uri, 1, 0, "PhosphorRender");
        qmlRegisterType<FloatBuffer>(uri, 1, 0, "FloatBuffer");
    }
};
