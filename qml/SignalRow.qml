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
     channel.mode = {'Voltage': 1, 'Current': 2}[signal.label];
     signal.src.src = 'constant'
  }

  function switchToPeriodic(type) {
    channel.mode = {'Voltage': 1, 'Current': 2}[signal.label];
    if (signal.src.src == 'constant') {
      signal.src.v2 = signal.src.v1
      signal.src.v1 = 0
      signal.src.period = 100
    }
    signal.src.src = type
  }

  Button {
    anchors.top: parent.top
    anchors.left: parent.left
    width: timelinePane.hspacing
    height: timelinePane.hspacing

    iconSource: 'qrc:/icons/' + signal.src.src + '.png'

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
      MenuItem { text: "Sawtooth"
        onTriggered: signalBlock.switchToPeriodic('sawtooth')
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

	states: [
        State {
            name: "floating"
            PropertyChanges { target: axes; anchors.top: undefined }
        },
        State {
            name: "notfloating"
            PropertyChanges { target: axes; anchors.top: signalBlock.top}
        }
    ]

    MouseArea {
      anchors.fill: parent
      drag.target: axes
      drag.axis: Drag.YAxis
      onDoubleClicked: {axes.state = "floating"}
      onReleased: {axes.state = "notfloating"}
      onWheel: {
      // Shift + scroll for Y-axis zoom
        if (wheel.modifiers & Qt.ShiftModifier) {
          var s = Math.pow(1.15, -wheel.angleDelta.y/120);
          var y = axes.pxToY(wheel.y);

          if (axes.ymax - axes.ymin < signal.resolution * 8 && s < 1) return;

          axes.ymin = Math.max(y - s * (y - axes.ymin), signal.min);
          axes.ymax = Math.min(y - s * (y - axes.ymax), signal.max);
        }
        else {
          wheel.accepted = false
        }
      }
      onPositionChanged: {
        // Shift + drag for Y-axis zoom
        if (mouse.modifiers & Qt.ShiftModifier) {
          var my = axes.pxToY(mouse.y);
          var range = axes.ymax - axes.ymin;
          var center = (axes.ymin + axes.ymax)/2
          axes.ymin = Math.max( (center*0.9+my*0.1) - range/2, signal.min); // -(signal.min+1)*0.1);
          axes.ymax = Math.min( (center*0.9+my*0.1) + range/2, signal.max); //+(signal.max+1)*0.1);
        }
        else {
          mouse.accepted = false
        }
      }
    }

    Rectangle {
      anchors.fill: parent
      opacity: 0.0
      z: -1
    }

    PhosphorRender {
        id: line
        anchors.fill: parent
        clip: true

        buffer: signal.buffer
        pointSize: Math.max(2, Math.min(xaxis.xscale/session.sampleRate*3, 20))

        xmin: xaxis.visibleMin
        xmax: xaxis.visibleMax
        ymin: axes.ymin
        ymax: axes.ymax
    }

    OverlayPeriodic {
      visible: (signal.src.src == 'sine' || signal.src.src == 'triangle' || signal.src.src == 'sawtooth' || signal.src.src == 'square') && (channel.mode == {'Voltage': 1, 'Current': 2}[signal.label])
    }

    OverlayConstant {
      visible: signal.src.src == 'constant'
    }

  }
}
