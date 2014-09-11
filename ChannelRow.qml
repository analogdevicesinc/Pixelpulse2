import QtQuick 2.1
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0

Rectangle {
  property var channel
  color: '#333'

  ColumnLayout {
    anchors.fill: parent
    anchors.leftMargin: 10
    spacing: 24

    Text {
      text: channel.label
      color: 'white'
    }

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
