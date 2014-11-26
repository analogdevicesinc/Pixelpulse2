import QtQuick 2.1
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.1

ColumnLayout {
  spacing: 0
  
  ToolbarStyle {
    Layout.fillWidth: true
    height: toolbarHeight
  }

  Rectangle {
    Layout.fillHeight: true
    Layout.fillWidth: true
    color: '#ccc'
  }
}
