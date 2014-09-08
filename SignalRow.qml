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

  PhosphorRender {
      x: parent.width
      y: 0
      width: xaxis.width
      height: parent.height

      id: line
      anchors.margins: 20

      buffer: signal.buffer

      pointSize: Math.max(2, Math.min(xaxis.xscale/session.sampleRate*3, 20))

      xmin: xaxis.visibleMin
      xmax: xaxis.visibleMax
      ymin: signal.min
      ymax: signal.max
  }
}
