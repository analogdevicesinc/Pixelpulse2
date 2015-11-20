import QtQuick 2.1
import QtQuick.Layouts 1.0
import QtQml.Models 2.1

ColumnLayout {
  id: smpLayout
  spacing: 12

  ToolbarStyle {
    Layout.fillWidth: true
    height: toolbarHeight
  }

  Rectangle {
    Layout.fillHeight: true
    Layout.fillWidth: true
    color: 'black'

    ListModel {
      id: devicesModel
    }

    Component {
      id: devDelegate

      Rectangle {
        anchors { left: parent.left; right: parent.right;
                  leftMargin: 15; rightMargin: 15}
        height: 60
        color: 'black'
        Column {
          height: parent.height
          width: parent.width
          spacing: 4

          Item {
            width: parent.width
            height: 10
            Text { text: "Device: " + name;
                   font.pointSize: 10;
                   color: 'white';
                   anchors.verticalCenter: parent.verticalCenter}
          }
          Item {
            width: parent.width
            height: 10
            Text { text: "Serial Number: " + uid;
                   font.pointSize: 10;
                   color: 'white';
                   anchors.verticalCenter: parent.verticalCenter}
          }
          Item {
            width: parent.width
            height: 10
            Text { text: "Firmware Version: " + firmware_version;
                   font.pointSize: 10;
                   color: 'white';
                   anchors.verticalCenter: parent.verticalCenter}
          }
          Item {
            width: parent.width
            height: 10
            Text { text: "Hardware Version: " + hardware_version;
                   font.pointSize: 10;
                   color: 'white';
                   anchors.verticalCenter: parent.verticalCenter}
          }
        }
      }
    }

    ListView {
      id: view
      anchors.fill: parent

      orientation: ListView.Vertical
      interactive: false
      spacing: 10

      model: devicesModel
      delegate: devDelegate

      Component.onCompleted: {
        if (devicesModel.count > 0)
          devicesModel.clear();
        for (var i = 0; i < session.devices.length; i++) {
          var device = session.devices[i];
          devicesModel.insert(devicesModel.count,
                              { "name": device.label,
                                "uid":device.UUID,
                                "firmware_version": device.FWVer,
                                "hardware_version": device.HWVer
                              });
        }
      }
    }

    Connections {
     target: session
       onDevicesChanged: {
         if (devicesModel.count > 0)
            devicesModel.clear();
          for (var i = 0; i < session.devices.length; i++) {
            var device = session.devices[i];
            devicesModel.insert(devicesModel.count,
                                {"name": device.label,
                                 "uid":device.UUID,
                                 "firmware_version": device.FWVer,
                                 "hardware_version": device.HWVer
                                });
          }
       }
    }
  }

}


