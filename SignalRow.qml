import QtQuick 2.1
import QtQuick.Layouts 1.0
import Plot 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.1

Rectangle {
  id: signalBlock
  property var xaxis
  property var signal

  color: '#444444'


  function switchToConstant() {
     signal.src.src = 'constant'
  }

  function switchToPeriodic(type) {
    if (signal.src.src == 'constant') {
      console.log('stp', type)
      signal.src.v1 = 0
      signal.src.v2 = 5
      signal.src.period = 100
    }
    signal.src.src = type
  }

  Button {
    anchors.top: parent.top
    anchors.left: parent.left
    width: timelinePane.hspacing
    height: timelinePane.hspacing

    style: ButtonStyle {
      background: Rectangle {
        opacity: control.pressed ? 0.3 : control.checked ? 0.2 : 0.1
        color: 'black'
      }
    }

    menu: Menu {
      MenuItem { text: "Constant"
        onTriggered: signalBlock.switchToConstant()
      }
      MenuItem { text: "Sine"
        onTriggered: signalBlock.switchToPeriodic('sine')
      }
      MenuItem { text: "Triangle"
        onTriggered: signalBlock.switchToPeriodic('triangle')
      }
      MenuItem { text: "Square"
        onTriggered: signalBlock.switchToPeriodic('square')
      }
    }
  }

  Text {
    color: 'white'
    text: signal.label
    rotation: -90
    transformOrigin: Item.TopLeft
    font.pixelSize: 18
    y: width + timelinePane.hspacing + 8
    x: (timelinePane.hspacing - height) / 2
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

    OverlayPeriodic{}
    OverlayConstant{}

  }
}
