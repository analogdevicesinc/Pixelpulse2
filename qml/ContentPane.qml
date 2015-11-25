import QtQuick 2.1
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import "jsutils.js" as JSUtils
import "sesssave.js" as StateSave

ColumnLayout {
  id: cLayout
  spacing: 12

  ToolbarStyle {
    Layout.fillWidth: true
    Layout.minimumWidth: parent.Layout.minimumWidth
    Layout.maximumWidth: parent.Layout.maximumWidth
    height: toolbarHeight
  }

  TextArea {
    id: outField
    readOnly: true
    Layout.fillWidth: true
    Layout.minimumWidth: parent.Layout.minimumWidth
    Layout.maximumWidth: parent.Layout.maximumWidth
    Layout.fillHeight: true
    selectByKeyboard: true
    selectByMouse: true
    backgroundVisible: false
	text: "Built: " + versions.build_date + "    " + "Version: " + versions.git_version + JSUtils.checkLatest(outField);
    style: TextAreaStyle {
        textColor: "#fff"
        selectionColor: "steelblue"
        selectedTextColor: "#eee"
        backgroundColor: "#eee"
    }
  }

  TextInput {
    id: inField
    Layout.fillWidth: true
    Layout.minimumWidth: parent.Layout.minimumWidth
    Layout.maximumWidth: parent.Layout.maximumWidth
	cursorVisible: true
	text: "type here."
	color: "#FFF"
    onAccepted: {
    // wow, javascript.
    var out;
    try {
      out = JSUtils.toJSON(eval(text), 5, 10, "  ");
      outField.textColor = "#fff";
    } catch (e) {
      out = e.message;
      outField.textColor = "#f77";
    };
    outField.text = out;
    }
	selectByMouse: true
  }
  MouseArea {
    anchors.fill: inField
    onPressed: { mouse.accepted = false; if (inField.text == "type here.") {inField.text = "" }}
  }
}
