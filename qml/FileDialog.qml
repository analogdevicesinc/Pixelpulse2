import QtQuick 2.2
import QtQuick.Dialogs 1.0

Item {
id: dialogItem

FileDialog {
    id: fileDialog
	property alias visible: toolbar.dialogVisible

    title: "Please choose a file"
    onAccepted: {
        fileio.write(fileDialog.fileUrls, "Ask Ubuntu");
    }
    onRejected: {
        console.log("Canceled")
    }
    Component.onCompleted: visible = true
}
}
