import QtQuick 2.1
import QtQuick.Layouts 1.0
import Plot 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.1
import QtQml.Models 2.1

Rectangle {
  id: signalBlock
  property var xaxis
  property var channel
  property var signal
  property var allsignals
  property var signal_type
  property int textSpacing: 18
  property int vertScaleWidth: 2 * textSpacing
  property int vertScalesWidth: (vertScaleWidth + view.spacing)  * (lockAxes ? 1 : allsignals.length)
  color: '#444'

  function updateMode() {
    channel.mode = {'Voltage': 1, 'Current': 2}[signal.label];
    //var target = parent.parent.parent;
    //for (var sig in target.children)
    //    if (target.children[sig].children[0])
    //       target.children[sig].children[0].updateMode();
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
      anchors.fill: parent
        // V1
        TextInput {
          id: v1TextBox
          text: signal.isOutput ? signal.src.v1.toFixed(4) : signal.measurement.toFixed(4)
          color: "#FFF"
          onAccepted: {
            signal.src.v1 = text
          }
          validator: DoubleValidator{bottom: axes.ymin; top: axes.ymax;}
          anchors.left: parent.left
          anchors.leftMargin: 80
        }
        Text {
           id: v1UnitLabel
           color: 'white'
           text: (signal.label == "Voltage" ? " Volts" : " Amperes")
           anchors.left: v1TextBox.right
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
        }
        // V2
        TextInput {
          id: v2TextBox
          text: overlay_periodic.visible ? signal.src.v2.toFixed(4) : ""
          color: "#FFF"
          onAccepted: {
            signal.src.v2 = text
          }
          validator: DoubleValidator{bottom: axes.ymin; top: axes.ymax;}
          anchors.left: v1TextBox.right
          anchors.leftMargin: 80
        }
        Text {
           color: 'white'
           text: overlay_periodic.visible ? (signal.label == "Voltage" ? " Volts" : " Amperes") : ""
           anchors.left: v2TextBox.right
        }
        // Freq
        TextInput {
          id: perTextBox
          visible: signal.src.src != 'constant' && signal.isOutput == true
          text: Math.abs(Math.round((controller.sampleRate / signal.src.period)).toExponential())
          color: "#FFF"
          onAccepted: {
            text = parseFloat(text).toExponential()
            signal.src.period = controller.sampleRate / text
          }
          validator: DoubleValidator{bottom: 0; top: controller.sampleRate/2;}
          anchors.left: v2TextBox.right
          anchors.leftMargin: 80
        }
        Text {
           color: 'white'
           visible: signal.src.src != 'constant' && signal.isOutput == true
           anchors.left: perTextBox.right
           text: " Hertz"
        }
     }
  }

  ListModel {
      id: signalColors
      ListElement {
          r: 0.03
          g: 0.2
          b: 0.03
          a: 1
      }
      ListElement {
          r: 0.3
          g: 0.3
          b: 0.0
          a: 1
      }
      ListElement {
          r: 0.3
          g: 0.3
          b: 0.3
          a: 1
      }

      ListElement {
          r: 0.45
          g: 0.0
          b: 0.0
          a: 1
      }
  }

  // Same colors (green, yellow, etc.) as "signalColors" but a little more brighter
  ListModel {
      id: axisColors
      ListElement {
          r: 0.0
          g: 1.0
          b: 0.0
          a: .75
      }
      ListElement {
          r: 1.0
          g: 1.0
          b: 0.0
          a: .75
      }
      ListElement {
          r: 0.6
          g: 0.6
          b: 0.6
          a: .75
      }

      ListElement {
          r: 1.0
          g: 0.0
          b: 0.0
          a: .75
      }
  }

  Axes {
    id: axes

    x: parent.width
    width: xaxis.width

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.topMargin: timelinePane.spacing

    property var axes_list: view.contentItem.children
    ymin: axes_list.length > 1 ? axes_list[channelList.crtLabelPos].min : signal.min
    ymax: axes_list.length > 1 ? axes_list[channelList.crtLabelPos].max : signal.max
    xgridticks: 2

    gridColor: '#222'
    zHorizontalGrid: -2

    states: [
      State {
        name: "floating"
        PropertyChanges { target: axes
          anchors.top: undefined
          anchors.bottom: undefined
          gridColor: '#111'
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
        var axes_list = view.contentItem.children;
        var i = channelList.crtLabelPos;
        var axis = axes_list[i];

        if (wheel.modifiers & Qt.ShiftModifier) {
          var s = Math.pow(1.15, -wheel.angleDelta.y/120);
          var y = axis.pxToVal(wheel.y);

          if (axis.max - axis.min < signal.resolution * 8 && s < 1) return;

          axis.min = Math.max(y - s * (y - axis.min), signal.min);
          axis.max = Math.min(y - s * (y - axis.max), signal.max);
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

    Repeater {
        model: allsignals
        PhosphorRender {
            id: line
            anchors.fill: parent
            clip: true
            z: -1

            buffer: modelData.buffer
            pointSize: Math.max(2, Math.min(xaxis.xscale/session.sampleRate*3, 20))
            color: Qt.rgba(signalColors.get(index).r,
                            signalColors.get(index).g,
                            signalColors.get(index).b,
                            signalColors.get(index).a)

            xmin: xaxis.visibleMin
            xmax: xaxis.visibleMax
            property var axis_list: view.contentItem.children
            property var axisIndex: lockAxes ? channelList.crtLabelPos : index
            ymin: axis_list.length > 1 ? axis_list[axisIndex].min : 0
            ymax: axis_list.length > 1 ? axis_list[axisIndex].max : 0

            // Check if user clicked on the line described by the waveform
            // and set channel that the waveform belongs to as the active channnel
            MouseArea{
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                propagateComposedEvents: true

                onClicked: {
                    var axes_list = view.contentItem.children;
                    var i = lockAxes ? channelList.crtLabelPos : index;
                    var axis = axes_list[i];

                    // multiply with 10 because xaxis xmin and xmax go from 0 to 0.1 and we need 0 to 1.0
                    var x = Math.round(xaxis.pxToX(mouse.x) * 10 * buffer.size());
                    var y = axis.pxToVal(mouse.y);

                    if (x > 0 && Math.abs(buffer.get(x) - y) < 0.04 * (ymax - ymin))
                        channelList.crtLabelPos = index;

                    mouse.accepted = false
                }
            }
        }
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

  Rectangle {
      id:vAxesContainer

      property int margin: 18
      color: '#000'
      anchors.left: axes.right
      anchors.top: axes.top
      anchors.bottom: axes.bottom
      anchors.leftMargin: margin
      width: vertScalesWidth

      Component {
          id: axesDelegate

          AxisScale {
              signalParent: signals[signal_type]
              vertical: true
              min: signals[signal_type].min
              max: signals[signal_type].max
              width: vertScaleWidth
              withGrid: true
              anchors { top: parent.top; bottom: parent.bottom }
              textColor: lockAxes ? '#fff' : Qt.rgba(axisColors.get(index).r,
                                 axisColors.get(index).g,
                                 axisColors.get(index).b,
                                 axisColors.get(index).a)
              visible: !lockAxes | index === channelList.crtLabelPos

              MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton

                onClicked: {
                  if (mouse.button == Qt.LeftButton)
                    channelList.crtChannel = modelData;
                }
              }
          }
      }

      DelegateModel {
          id: visualModel

          model: channelList.allChannels
          delegate: axesDelegate
      }

      ListView {
          id: view
          anchors.fill: parent
          model: visualModel
          orientation: ListView.Horizontal
          interactive: false

          spacing: 10
          cacheBuffer: 50

          currentIndex: -1 // This removes a default qtquickitem from the contentItem.children list which was causing trouble when accessing the list by index

          Connections {
            target: channelList
            onCrtChannelChanged: {
                if (lockAxes)
                    return;

              var i = 0;
              var last = visualModel.items.count;
              while (i < last) {
                  var chn = visualModel.items.get(i).model.modelData
                  var chnIndex = channelList.crtLabelPos
                  var vertAxesList = view.contentItem.children

                  if (chn === channelList.crtChannel) {
                      visualModel.items.move(i, 0);
                      axes.ymin = Qt.binding(function() { return vertAxesList[chnIndex].min } );
                      axes.ymax = Qt.binding(function() { return vertAxesList[chnIndex].max } );
                      break;
                  }
                  i++;
              }
            }
          }
      }
  }

}
