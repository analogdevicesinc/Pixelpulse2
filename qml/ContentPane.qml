import QtQuick 2.1
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.1
import "prunedjson.js" as PrunedJSON

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
	  outField.text = PrunedJSON.toJSON(eval(text), 5, 10, "  ");
    }
	selectByMouse: true
  }
  MouseArea {
    anchors.fill: inField
    onPressed: { mouse.accepted = false; if (inField.text == "type here.") {inField.text = "" }}
  }
}
