import QtQuick 2.1
import QtQuick.Layouts 1.0
import Plot 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.1
import QtQml 2.2

Rectangle {
  id: signalBlock
  property alias ymin: axes.ymin;
  property alias ymax: axes.ymax;
  property var xaxis
  property var signal
  property int ygridticks: axes.ygridticks
  color: '#444'
  property int currentFontSize: 11;

  property color gradColor: Qt.rgba(1,1,1,0.08)
  property color gradColor2: Qt.rgba(0,0,0,0.0)


  function constrainValue(value, min, max) {
    if (value < min)
        value = min;
    else if (value > max)
        value = max;
    return value;
  }

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
    font.pixelSize: 18 / session.devices.length
    y: width + timelinePane.spacing + 8
    x: (timelinePane.spacing - height) / 2
  }

  Rectangle {
    id: idRectangle
    z: -1
    x: parent.width
    width: xaxis.width
    anchors.top: parent.top
    height: timelinePane.spacing

    gradient: Gradient {
        GradientStop { position: 1.0; color: gradColor }
        GradientStop { position: 0.0; color: gradColor2 }
    }

    RowLayout {
      id: editWaveform
      anchors.fill: parent
      property bool isVoltageSignal: signal.label === "Voltage" ? true : false
      property real up_dn_Sensitivity : isVoltageSignal ? 0.01 : 0.001;
      property real pgUp_pgDn_Sensitivity : isVoltageSignal ? 1.0 : 0.1;

        // V1
        TextInput {
          id: v1TextBox
          text: signal.isOutput ? signal.src.v1.toFixed(4) : signal.peak_to_peak.toFixed(4)
          color: "#FFF"
          selectByMouse: true
          font.pixelSize: currentFontSize
          property real position: idRectangle.x + idRectangle.width * 10/100;


          Binding {
            target: v1TextBox; property: 'text'
            value: signal.isOutput ? signal.src.v1.toFixed(4) : signal.peak_to_peak.toFixed(4)
          }

          onAccepted: {
            var value = constrainValue(Number.fromLocaleString(text), axes.ymin, axes.ymax);
            text = value.toFixed(4);
            signal.src.v1 = text;

            signalBlock.updateMode() // enough to call it for V1 (not necessary for V2, Freq - not visible when sourcing current anyway)
          }

          Keys.onPressed: {
            var value;

            switch (event.key) {
              case Qt.Key_Escape:
                text = signal.src.v1.toFixed(4);
                break;

              case Qt.Key_Down:
                  value = Number.fromLocaleString(text) - editWaveform.up_dn_Sensitivity;
                  text = value.toFixed(4);
                  accepted();
                  break;

              case Qt.Key_Up:
                  value = Number.fromLocaleString(text) + editWaveform.up_dn_Sensitivity;
                  text = value.toFixed(4);
                  accepted();
                  break;

              case Qt.Key_PageDown:
                  value = Number.fromLocaleString(text) - editWaveform.pgUp_pgDn_Sensitivity;
                  text = value.toFixed(4);
                  accepted();
                  break;

              case Qt.Key_PageUp:
                  value = Number.fromLocaleString(text) + editWaveform.pgUp_pgDn_Sensitivity;
                  text = value.toFixed(4);
                  accepted();
                  break;
            }
          }

          validator: DoubleValidator{}
          anchors.left: parent.left
          anchors.leftMargin: idRectangle.width * 10/100;
        }
        Text {
           id: v1UnitLabel
           color: 'white'
           text: (signal.label == "Voltage" ? " Volts" : " Amperes") + (signal.isOutput ? "" : " (peak to peak)");
           anchors.left: v1TextBox.right
           anchors.leftMargin: idRectangle.width * 1/100
           font.pixelSize: currentFontSize
           property real position: v1TextBox.position + v1TextBox.width + idRectangle.width * 1/100;

        }
        // Resistance
        Text {
          color: 'white'
          visible: signal.src.src == 'constant' && signal.isOutput == true
          text: {
             var r = Math.abs((channel.signals[0].measurement / channel.signals[1].measurement)).toFixed();
             (Math.abs(channel.signals[1].measurement) > 0.001) ? "    " + r + " Ohms" : ""
          }
          anchors.left: v1UnitLabel.right
          anchors.leftMargin: idRectangle.width * 1/100
          font.pixelSize: currentFontSize
          property real position: v1TextBox.position + v1TextBox.width + idRectangle.width * 1/100;
        }
        // V2
        TextInput {
          id: v2TextBox
          visible: signal.isOutput ;
          text: overlay_periodic.visible? signal.src.v2.toFixed(4) : "";
          color: "#FFF"
          selectByMouse: true
          font.pixelSize: currentFontSize
          property real position: v1UnitLabel.position + v1UnitLabel.width + idRectangle.width * 10/100

          Binding {
            target: v2TextBox; property: 'text'
            value: overlay_periodic.visible ? signal.src.v2.toFixed(4) : "";
          }

          onAccepted: {
            var value = constrainValue(Number.fromLocaleString(text), axes.ymin, axes.ymax);
            text = value.toFixed(4);
            signal.src.v2 = text;
          }

          Keys.onPressed: {
            var value;

            switch (event.key) {
              case Qt.Key_Escape:
                text = signal.src.v1.toFixed(4);
                break;

              case Qt.Key_Down:
                  value = Number.fromLocaleString(text) - editWaveform.up_dn_Sensitivity;
                  text = value.toFixed(4);
                  accepted();
                  break;

              case Qt.Key_Up:
                  value = Number.fromLocaleString(text) + editWaveform.up_dn_Sensitivity;
                  text = value.toFixed(4);
                  accepted();
                  break;

              case Qt.Key_PageDown:
                  value = Number.fromLocaleString(text) - editWaveform.pgUp_pgDn_Sensitivity;
                  text = value.toFixed(4);
                  accepted();
                  break;

              case Qt.Key_PageUp:
                  value = Number.fromLocaleString(text) + editWaveform.pgUp_pgDn_Sensitivity;
                  text = value.toFixed(4);
                  accepted();
                  break;
            }
          }

          validator: DoubleValidator{}
          anchors.left: v1UnitLabel.right
          anchors.leftMargin: idRectangle.width * 10/100
        }
        Text {
           id: v2UnitLabel
           color: 'white'
           text: overlay_periodic.visible ? (signal.label == "Voltage" ? " Volts" : " Amperes") : ""
           anchors.left: v2TextBox.right
           anchors.leftMargin: idRectangle.width * 1/100
           font.pixelSize: currentFontSize
           property real position: v2TextBox.position + v2TextBox.width + idRectangle.width * 1/100;
        }

        // Freq
        TextInput {
          id: perTextBox
          visible: perUnitLabel.position + perUnitLabel.width <= idRectangle.x + idRectangle.width
          text: signal.isOutput ? (signal.src.src != 'constant' ? Math.abs(Math.round((controller.sampleRate / signal.src.period))).toFixed(3) : ""): signal.measurement.toFixed(4);
          color: "#FFF"
          selectByMouse: true
          font.pixelSize: currentFontSize

          property real position: v2UnitLabel.position + v2UnitLabel.width + idRectangle.width * 10/100
          property real up_dn_freq_Sensivity: 1
          property real pgUp_pgDn_freq_Sensivity: 100

          onAccepted: {
            var value = constrainValue(Number.fromLocaleString(text), 0, controller.maxOutSignalFreq);
            text = parseFloat(value).toFixed(3)
            signal.src.period = controller.sampleRate / text
          }

          Binding {
            target: perTextBox; property: 'text';
            value: signal.isOutput ? (signal.src.src != 'constant' ? Math.abs(Math.round((controller.sampleRate / signal.src.period))).toFixed(3) : ""): signal.measurement.toFixed(4);
          }

          Keys.onPressed: {
            var value;

            switch (event.key) {
              case Qt.Key_Escape:
                text = signal.src.v1.toFixed(4);
                break;

              case Qt.Key_Down:
                  value = Number.fromLocaleString(text) - up_dn_freq_Sensivity;
                  text = parseFloat(value).toFixed(3);
                  accepted();
                  break;

              case Qt.Key_Up:
                  value = Number.fromLocaleString(text) + up_dn_freq_Sensivity;
                  text = parseFloat(value).toFixed(3);
                  accepted();
                  break;

              case Qt.Key_PageDown:
                  value = Number.fromLocaleString(text) - pgUp_pgDn_freq_Sensivity;
                  text = parseFloat(value).toFixed(3);
                  accepted();
                  break;

              case Qt.Key_PageUp:
                  value = Number.fromLocaleString(text) + pgUp_pgDn_freq_Sensivity;
                  text = parseFloat(value).toFixed(3);
                  accepted();
                  break;
            }
          }

          validator: DoubleValidator{}
          anchors.left: v2UnitLabel.right
          anchors.leftMargin: idRectangle.width * 10/100
        }
        Text {
           id: perUnitLabel
           color: 'white'
           visible: perUnitLabel.position + perUnitLabel.width <= idRectangle.x + idRectangle.width;
           anchors.left: perTextBox.right
           anchors.leftMargin: idRectangle.width * 1/100
           text: signal.isOutput ? (signal.src.src != 'constant' ? "Hertz" : ""): "RMS";
           font.pixelSize: currentFontSize
           property real position: perTextBox.position + perTextBox.width + idRectangle.width * 1/100;
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

            var resolution = signal.label === 'Current' ? signal.resolution * 10 : signal.resolution;


            if (axes.ymax - axes.ymin < resolution * ygridticks && s < 1) return;

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

    gridColor: window.signalAxesColor//'#222'
    textColor: '#FFF'

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

          var resolution = signal.label === 'Current' ? signal.resolution * 10 : signal.resolution;
          if (axes.ymax - axes.ymin < resolution * ygridticks && s < 1) return;

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
      color: window.signalAxesColor
    }

    Rectangle {
      anchors.bottom: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: 1
      color: window.signalAxesColor
    }

    Rectangle {
      id: bg
      anchors.fill: parent
      color: window.signalRowColor
      z: -1
    }

    PhosphorRender {
        id: line
        anchors.fill: parent
        clip: true

        buffer: signal.buffer
        pointSize: Math.min(25, Math.max(2, xaxis.xscale/session.sampleRate*3) * window.dotSizeSignal * 10)
        color: signal.label == 'Current' ? window.dotSignalCurrent : window.dotSignalVoltage //Qt.rgba(0.2, 0.2, 0.03, 1) : Qt.rgba(0.03, 0.3, 0.03, 1)

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
