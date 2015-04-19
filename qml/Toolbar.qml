import QtQuick 2.1
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.1
import QtQuick.Dialogs 1.0
import "dataexport.js" as CSVExport

ToolbarStyle {
  ExclusiveGroup {
    id: timeGroup
  }

  property alias repeatedSweep: repeatedSweepItem.checked
  property alias plotsVisible: plotsVisibleItem.checked
  property alias contentVisible: contentVisibleItem.checked

  FileDialog {
    id: fileDialog
    selectExisting: false
    sidebarVisible: false
    title: "Please enter a location to save your data."
    nameFilters: [ "CSV files (*.csv)", "All files (*)" ]
    onAccepted: {
        var labels = [];
        var columns = [];
        if (session.devices) {
          while (session.active){};
          for (var i = 0; i < session.devices.length; i++) {
             for (var j = 0; j < session.devices[i].channels.length; j++) {
               for (var k = 0; k < session.devices[i].channels[i].signals.length; k++) {
                  var label = '' + i + session.devices[i].channels[j].label +"_"+ session.devices[i].channels[j].signals[k].label;
                  labels.push(label);
                  columns.push(session.devices[i].channels[j].signals[k].buffer.getData());
               };
             };
          };
        console.log('selected path: ', fileDialog.fileUrls[0]);
        fileio.writeToURL(fileDialog.fileUrls[0], CSVExport.dumpsample(columns, labels));
        };
    }
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
        MenuItem { exclusiveGroup: timeGroup; checkable: true;
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

      MenuSeparator{}
      MenuItem {
        id: dialogVisibleItem
        text: "Export Data"
        onTriggered: fileDialog.visible = true
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
