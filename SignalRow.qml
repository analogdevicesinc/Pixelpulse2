import QtQuick 2.1
import QtQuick.Layouts 1.0
import Plot 1.0

Rectangle {
  property var xaxis
  property var signal

  color: '#444444'

  Text {
    color: 'white'
    text: signal.label
  }

  Axes {
    id: axes

    x: parent.width
    y: 0
    width: xaxis.width
    height: parent.height

    ymin: signal.min
    ymax: signal.max
    xgridticks: 2
    yleft: false
    yright: true
    xbottom: false

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

        buffer: signal.buffer
        pointSize: Math.max(2, Math.min(xaxis.xscale/session.sampleRate*3, 20))

        xmin: xaxis.visibleMin
        xmax: xaxis.visibleMax
        ymin: signal.min
        ymax: signal.max
    }

    OverlayConstant{}

  }
}
