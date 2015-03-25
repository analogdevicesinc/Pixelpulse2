import QtQuick 2.1
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.1

ColumnLayout {
  spacing: 32
  id: xyplot
  Layout.minimumWidth: 0.3*parent.width
  Layout.maximumWidth: 0.6*parent.width

  ToolbarStyle {
    Layout.fillWidth: true
    height: toolbarHeight
  }

  Repeater {
    model: session.devices

    Repeater {
      model: modelData.channels

      XYPlot {
        // if mode == SIMV, current is independent variable
        // if mode == SVMI (or Hi-Z), voltage is independent variable
        Layout.minimumWidth: parent.width
        Layout.maximumWidth: parent.width
        isignal: modelData.signals[1]
        vsignal: modelData.signals[0]
      }
    }
  }
}
