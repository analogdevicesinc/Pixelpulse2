import QtQuick 2.1
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.1

ColumnLayout {
  spacing: 12
  width: contentPane.width

  ToolbarStyle {
    Layout.fillWidth: true
    height: toolbarHeight
  }

  TextArea {
    id: outField
    readOnly: true
    width: parent.width
    Layout.fillWidth: true
    Layout.fillHeight: true
    selectByKeyboard: true
    selectByMouse: true
    backgroundVisible: false
	textColor: "#FFF"
  }

  TextInput {
    id: inField
    width: parent.width
    Layout.fillWidth: true
	cursorVisible: true
	text: "type here."
	color: "#FFF"
    onAccepted: {
	  outField.text = JSON.stringify(eval(text), null, 2)
    }
	selectByMouse: true
  }
  MouseArea {
    anchors.fill: inField
    onPressed: { mouse.accepted = false; inField.text = "" }
  }
}
