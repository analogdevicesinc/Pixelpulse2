import QtQuick 2.1
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.1


Rectangle {
  property var channel
  color: '#333'

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

  Text {
    text: "Channel " + channel.label
    color: 'white'
    rotation: -90
    transformOrigin: Item.TopLeft
    font.pixelSize: 18
    y: width + timelinePane.hspacing + 8
    x: (timelinePane.hspacing - height) / 2
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.leftMargin: timelinePane.hspacing
    spacing: timelinePane.vspacing

    Repeater {
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
