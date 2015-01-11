import QtQuick 2.1
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.1

ColumnLayout {
  spacing: 32

  ToolbarStyle {
    Layout.fillWidth: true
    height: toolbarHeight
  }

  Repeater {
    model: session.devices

    Repeater {
      model: modelData.channels

      XYPlot {
        xsignal: modelData.signals[0]
        ysignal: modelData.signals[1]
      }
    }
  }
}
