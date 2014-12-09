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
    Layout.fillWidth: true
    color: '#ccc'
    height: toolbarHeight
  }

  TextInput {
    Layout.fillWidth: true
    height: toolbarHeight
	cursorVisible: true
	text: "type here."
	color: "#FFF"
    onAccepted: {
	  console.log(eval(text))
    }
  }

}
