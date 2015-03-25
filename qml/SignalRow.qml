import QtQuick 2.1
import QtQuick.Layouts 1.0
import Plot 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.1

Rectangle {
  id: signalBlock
  property var xaxis
  property var signal

  color: '#444'

  function updateMode() {
    channel.mode = {'Voltage': 1, 'Current': 2}[signal.label];
    var target = parent.parent.parent;
    for (var sig in target.children)
        if (target.children[sig].children[0])
           target.children[sig].children[0].updateMode();
  }

  function switchToConstant() {
     signalBlock.updateMode()
     signal.src.src = 'constant'
  }

  function switchToPeriodic(type) {
    signalBlock.updateMode()
    if (signal.src.src == 'constant') {
      if ((signal.src.v1 == 0) || (signal.src.v2 == 0))
          signal.src.v2 = (channel.mode == 1) ? 2.5 : 0.050;
      else
          signal.src.v2 = 0;
      signal.src.v1 = 0
      signal.src.period = 100
    }
    signal.src.src = type
  }

  Button {
    anchors.top: parent.top
    anchors.left: parent.left
    width: timelinePane.spacing
    height: timelinePane.spacing

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
      MenuItem { text: "Stairstep"
        onTriggered: signalBlock.switchToPeriodic('stairstep')
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
    y: width + timelinePane.spacing + 8
    x: (timelinePane.spacing - height) / 2
  }

  Rectangle {
    z: -1

    x: parent.width
    width: xaxis.width

    anchors.top: parent.top
    height: timelinePane.spacing

    gradient: Gradient {
        GradientStop { position: 1.0; color: Qt.rgba(1,1,1,0.08) }
        GradientStop { position: 0.0; color: Qt.rgba(0,0,0,0.0) }
    }

    RowLayout {
      id: editWaveform
      visible: signal.isOutput
      anchors.fill: parent
		TextInput {
		  id: v1TextBox
		  text: signal.src.v1.toFixed(4) + (channel.mode == 1 ? " Volts" : " Amperes")
		  color: "#FFF"
		  onAccepted: {
			signal.src.v1 = text
		  }
		  validator: DoubleValidator{bottom: axes.ymin; top: axes.ymax;}
          anchors.left: parent.left
          anchors.leftMargin: 80
		}
		TextInput {
		  id: v2TextBox
		  text: overlay_periodic.visible ? signal.src.v2.toFixed(4) + (channel.mode == 1 ? " Volts" : " Amperes") : ""
		  color: "#FFF"
		  onAccepted: {
			signal.src.v2 = text
		  }
		  validator: DoubleValidator{bottom: axes.ymin; top: axes.ymax;}
          anchors.left: v1TextBox.right
          anchors.leftMargin: 80
		}
		TextInput {
		  id: perTextBox
		  text: overlay_periodic.visible ? (controller.sampleRate / signal.src.period).toFixed(2)  + " Hertz": ""
		  color: "#FFF"
		  onAccepted: {
			signal.src.period = controller.sampleRate / text
		  }
		  validator: DoubleValidator{bottom: 0; top: controller.sampleRate/2;}
          anchors.left: v2TextBox.right
          anchors.leftMargin: 80
        }
     }
  }

  Item {
      id: vertAxes

      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.left: axes.right
      anchors.topMargin: timelinePane.spacing
      width: timelinePane.width - xaxis.width - signalsPane.width

      MouseArea {
        anchors.fill: parent

        property var zoomParams
        acceptedButtons: Qt.RightButton
        onPressed: {
          if (mouse.button == Qt.RightButton) {
            zoomParams = {
              firstY : mouse.y,
              prevY : mouse.y,
            }
          } else {
            mouse.accepted = false;
          }
        }
        onReleased: {
          zoomParams = null
        }
        onPositionChanged: {
          if (zoomParams) {
            var delta = (mouse.y - zoomParams.prevY)
            zoomParams.prevY = mouse.y
            var s = Math.pow(1.01, delta)
            var y = axes.pxToY(zoomParams.firstY);

            if (axes.ymax - axes.ymin < signal.resolution * 8 && s < 1) return;

            axes.ymin = Math.max(y - s * (y - axes.ymin), signal.min);
            axes.ymax = Math.min(y - s * (y - axes.ymax), signal.max);

          }
        }
      }
  }

  Axes {
    id: axes

    x: parent.width
    width: xaxis.width

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.topMargin: timelinePane.spacing

    ymin: signal.min
    ymax: signal.max
    xgridticks: 2
    yleft: false
    yright: true
    xbottom: false

    gridColor: '#222'
    textColor: '#fff'

    states: [
      State {
        name: "floating"
        PropertyChanges { target: axes
          anchors.top: undefined
          anchors.bottom: undefined
          gridColor: '#111'
          textColor: '#444'
        }
        PropertyChanges { target: axes_mouse_area
          drag.target: axes
          drag.axis: Drag.YAxis
        }
        PropertyChanges { target: overlay_periodic; visible: false }
        PropertyChanges { target: overlay_constant; visible: false }
      }
    ]

    MouseArea {
      id: axes_mouse_area
      anchors.fill: parent

      acceptedButtons: Qt.LeftButton | Qt.MiddleButton
      property var panStart
      onPressed: {
        if (mouse.button == Qt.MiddleButton) {
          axes.state = "floating"
        } else if (mouse.button == Qt.LeftButton && mouse.modifiers & Qt.ShiftModifier) {
          panStart = {
            y: mouse.y,
            ymin: axes.ymin,
            ymax: axes.ymax,
          }
        } else {
          mouse.accepted = false;
        }
      }
      onReleased: {
        axes.state = ""
        panStart = null
      }
      onPositionChanged: {
        // Shift + drag for Y-axis pan
        if (panStart) {
          var delta = (mouse.y - panStart.y) / axes.yscale
          delta = Math.max(delta, signal.min - panStart.ymin)
          delta = Math.min(delta, signal.max - panStart.ymax)
          axes.ymin = panStart.ymin + delta
          axes.ymax = panStart.ymax + delta
        }
      }
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
    }

    Rectangle {
      anchors.top: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      height: 2
      color: "#282828"
    }

    Rectangle {
      anchors.bottom: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: 1
      color: "#282828"
    }

    PhosphorRender {
        id: line
        anchors.fill: parent
        clip: true

        buffer: signal.buffer
        pointSize: Math.max(2, Math.min(xaxis.xscale/session.sampleRate*3, 20))
        color: signal.label == 'Current' ? Qt.rgba(0.2, 0.2, 0.03, 1) : Qt.rgba(0.03, 0.3, 0.03, 1)

        xmin: xaxis.visibleMin
        xmax: xaxis.visibleMax
        ymin: axes.ymin
        ymax: axes.ymax
    }

    OverlayPeriodic {
      id: overlay_periodic
      visible: (signal.src.src == 'sine' || signal.src.src == 'triangle' || signal.src.src == 'sawtooth' || signal.src.src == 'stairstep' || signal.src.src == 'square') && (channel.mode == {'Voltage': 1, 'Current': 2}[signal.label])
    }

    OverlayConstant {
      id: overlay_constant
      visible: signal.src.src == 'constant'
    }

  }
}
