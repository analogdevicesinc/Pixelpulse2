import QtQuick 2.1
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.1

Rectangle {
  property var channel
  property alias signalRepeater:signalRepeater
  color: window.channelColor //'#333'

  Button {
    anchors.top: parent.top
    anchors.left: parent.left
    width: timelinePane.spacing
    height: timelinePane.spacing

    property var icons: [
      'mv',
      'svmi',
      'simv',
    ]
    iconSource: 'qrc:/icons/' + icons[channel.mode] + '.png'

    style: ButtonStyle {
      background: Rectangle {
        opacity: control.pressed ? 0.3 : control.checked ? 0.2 : 0.1
        color: 'black'
      }
    }

    function updateMode() {
       var chIdx = {A: 1, B: 2}[channel.label];
       var offs = 1 + deviceRepeater.count + parent.parent.parent.currentIndex * 2;

       xyPane.children[offs+chIdx].ysignal = (channel.mode == 1) ? xyPane.children[offs+chIdx].isignal : xyPane.children[offs+chIdx].vsignal;
       xyPane.children[offs+chIdx].xsignal = (channel.mode == 1) ? xyPane.children[offs+chIdx].vsignal : xyPane.children[offs+chIdx].isignal;
    }

    menu: Menu {
      MenuItem { text: "Measure Voltage"
        onTriggered: channel.mode = 0
      }
      MenuItem { text: "Source Voltage, Measure Current"
        onTriggered: channel.mode = 1
      }
      MenuItem { text: "Source Current, Measure Voltage"
        onTriggered: channel.mode = 2
      }
    }
  }


  Text {
    text: "Channel " + channel.label
    color: 'white'
    rotation: -90
    transformOrigin: Item.TopLeft
    font.pixelSize: 18 / session.devices.length
    y: width + timelinePane.spacing + 8
    x: (timelinePane.spacing - height) / 2
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.leftMargin: timelinePane.spacing
    spacing: 0

    Repeater {
      id: signalRepeater
      model: modelData.signals

      SignalRow {
        Layout.fillHeight: true
        Layout.fillWidth: true

        signal: model
        xaxis: timeline_xaxis
      }
    }
  }
}
