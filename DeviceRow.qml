import QtQuick 2.1
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0

Rectangle {
  property var device
  color: '#222'

  ColumnLayout {
    anchors.fill: parent
    anchors.leftMargin: 10

    Text {
      text: device.label
      color: 'white'
    }

    Repeater {
      model: device.channels

      ChannelRow {
        Layout.fillWidth: true
        Layout.fillHeight: true

        channel: model
      }
    }
  }
}
