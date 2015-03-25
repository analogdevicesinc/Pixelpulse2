import QtQuick 2.1
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.1

ColumnLayout {
  spacing: 32
  id: xyplot

  ToolbarStyle {
    Layout.fillWidth: true
    height: toolbarHeight
  }

  Repeater {
    model: session.devices

    Repeater {
      model: modelData.channels

      XYPlot {
        Layout.minimumWidth: xyplot.width
        Layout.maximumWidth: xyplot.width
        // if mode == SIMV, current is independent variable
        // if mode == SVMI (or Hi-Z), voltage is independent variable
        isignal: modelData.signals[1]
        vsignal: modelData.signals[0]
      }
    }
  }
}
