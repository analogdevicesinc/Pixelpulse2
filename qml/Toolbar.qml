import QtQuick 2.1
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.1
import QtQuick.Dialogs 1.0
import "dataexport.js" as CSVExport
import "sesssave.js" as StateSave

ToolbarStyle {
  ExclusiveGroup {
    id: timeGroup
  }

  property alias repeatedSweep: repeatedSweepItem.checked
  property alias plotsVisible: plotsVisibleItem.checked
  property alias contentVisible: contentVisibleItem.checked
  property alias deviceMngrVisible: deviceMngrVisibleItem.checked

  FileDialog {
    id: dataDialog
    selectExisting: false
    sidebarVisible: false
    title: "Please enter a location to save your data."
    nameFilters: [ "CSV files (*.csv)", "All files (*)" ]
    onAccepted: { CSVExport.saveData(dataDialog.fileUrls[0]);}
  }
  FileDialog {
    id: sessSaveDialog
    selectExisting: false
    sidebarVisible: false
    title: "Please enter a location to save your session."
    nameFilters: [ "JSON files (*.json)", "All files (*)" ]
    onAccepted: { fileio.writeByURI(sessSaveDialog.fileUrls[0], JSON.stringify(StateSave.saveState(), 0, 2));}
  }
  FileDialog {
    id: sessRestoreDialog
    selectExisting: true
    sidebarVisible: false
    title: "Please select a session to restore."
    nameFilters: [ "JSON files (*.json)", "All files (*)" ]
    onAccepted: { StateSave.restoreState(JSON.parse(fileio.readByURI(sessRestoreDialog.fileUrls[0])));}
  }

  Button {
    tooltip: "Menu"
    Layout.fillHeight: true
    style: btnStyle

    menu: Menu {

      MenuItem {
          id: repeatedSweepItem
          text: "Repeated sweep"
          checkable: true
          checked: true
      }

      Menu {
        title: "Sample Time"
        MenuItem { exclusiveGroup: timeGroup; checkable: true;
          onTriggered: controller.sampleTime = 0.01; text: '10 ms' }
        MenuItem { exclusiveGroup: timeGroup; checkable: true; checked: true;
          onTriggered: controller.sampleTime = 0.1; text: '100 ms' }
        MenuItem { exclusiveGroup: timeGroup; checkable: true;
          onTriggered: controller.sampleTime = 1; text: '1 s' }
        MenuItem { exclusiveGroup: timeGroup; checkable: true;
          onTriggered: controller.sampleTime = 10; text: '10 s' }
      }

      MenuItem {
        id: plotsVisibleItem
        text: "X-Y Plots"
        checkable: true
      }

      MenuItem {
        id: contentVisibleItem
        text: "About"
        checkable: true
      }

      MenuItem {
        id: deviceMngrVisibleItem
        text: "Device Manager"
        checkable: true
      }

      MenuSeparator{}
      MenuItem {
        id: dataSaveVisibleItem
        text: "Export Data"
        onTriggered: dataDialog.visible = true
      }
      MenuItem {
	    id: sessionSaveVisibleItem
        text: "Save Session"
        onTriggered: sessSaveDialog.visible = true
      }
      MenuItem {
        id: sessionRestoreVisibleItem
        text: "Restore Session"
        onTriggered: sessRestoreDialog.visible = true
      }
      MenuSeparator{}
      MenuItem { text: "Exit"; onTriggered: Qt.quit() }
    }
    iconSource: 'qrc:/icons/gear.png'
  }

  Button {
    tooltip: "Start"
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignRight
    style: btnStyle
    iconSource: (controller.enabled & (session.availableDevices > 0)) ? 'qrc:/icons/pause.png' : 'qrc:/icons/play.png'

    onClicked: {
      if (session.availableDevices > 0) {
        controller.toggle()
      }
    }
  }
}
