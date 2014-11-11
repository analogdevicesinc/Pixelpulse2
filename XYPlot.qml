import QtQuick 2.1
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import Plot 1.0


Item {
  Layout.fillWidth: true
  Layout.fillHeight: true

  property var xsignal
  property var ysignal

  Axes {
    id: axes

    anchors.fill: parent
    anchors.margins: 30

    xmin: xsignal.min
    xmax: xsignal.max
    ymin: ysignal.min
    ymax: ysignal.max
    yleft: true
    yright: false
    xbottom: true

    gridColor: '#222'
    textColor: '#666'

    Rectangle {
      anchors.fill: parent
      color: '#0c0c0c'
      z: -1
    }

    PhosphorRender {
        id: line
        anchors.fill: parent
        clip: true

        xBuffer: xsignal.buffer
        buffer: ysignal.buffer
        pointSize: Math.max(2, Math.min(xaxis.xscale/session.sampleRate*3, 20))

        xmin: axes.xmin
        xmax: axes.xmax
        ymin: axes.ymin
        ymax: axes.ymax
    }
  }
}
