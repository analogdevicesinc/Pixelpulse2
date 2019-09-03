import QtQuick 2.1
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0

Rectangle {
  property var device
  property alias channelRepeater: channelRepeater
  property var currentIndex
  color: '#222'

  Text {
    text: device.label
    color: 'white'
    rotation: -90
    transformOrigin: Item.TopLeft
    font.pixelSize: 18/session.devices.length
    y: width + timelinePane.spacing + 8
    x: (timelinePane.spacing - height) / 2
  }

  MouseArea {
      anchors.fill: parent
      onClicked: {
          session.devices[currentIndex].blinkLeds()
      }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.leftMargin: timelinePane.spacing
    spacing: 0

    Repeater {
      id: channelRepeater
      model: device.channels

      ChannelRow {
        Layout.fillWidth: true
        Layout.fillHeight: true

        channel: model
      }
    }
  }
}
