import QtQuick 2.1
import QtQuick.Layouts 1.0
import QtQml.Models 2.1
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import "jsutils.js" as JSUtils

ColumnLayout {
  id: smpLayout
  spacing: 12

  function deviceManagerListFill() {
    var showPane = false;
    if (devicesModel.count > 0)
       devicesModel.clear();
    JSUtils.checkLatestFw(function(ver) {
        console.log('fw=', ver);

    for (var i = 0; i < session.devices.length; i++) {
      var device = session.devices[i];
      var updt_needed = "true"; // This needs to be replace with something like this: var updt_needed = device.NeedsFWupdate.


          devicesModel.insert(devicesModel.count,
                              {"name": device.label,
                               "uid":device.UUID,
                               "firmware_version": device.FWVer,
                               //"hardware_version": device.HWVer,
                               "hardware_version": ver,
                               "fw_updt_needed": updt_needed
                              });

           if (updt_needed == "true")
             showPane = true;
     }
     if (showPane)
       deviceMngrVisible = true;
    });
    }

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
        height: 80
        color: 'black'
        Column {
          height: parent.height
          width: parent.width

          Item {
            width: parent.width
            height: 20
            Text { text: "Device: " + name;
                   font.pointSize: 10;
                   color: 'white';
                   anchors.verticalCenter: parent.verticalCenter}
          }
          Item {
            width: parent.width
            height: 20
            Text { text: "Serial Number: " + uid;
                   font.pointSize: 10;
                   color: 'white';
                   anchors.verticalCenter: parent.verticalCenter}
          }
          Item {
            width: parent.width
            height: 20
            Row {
              anchors.fill: parent
              spacing: 10
              Text { text: "Firmware Version: " + firmware_version;
                     font.pointSize: 10;
                     color: 'white';
                     anchors.verticalCenter: parent.verticalCenter}
              Rectangle {
                height: parent.height
                width: 115
                color: 'white'
                visible: fw_updt_needed == "true"

                Rectangle {
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width - 2
                  height: parent.height - 2
                  color: 'black'

                  Text {
                    x: 5
                    text: "Update Firmware"
                    font.pointSize: 10
                    color: 'white'
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  MouseArea {
                    property color lastColor: 'black'

                    hoverEnabled: true
                    anchors.fill: parent
                    onClicked: {
                      // do stuff ...
                        JSUtils.getFirmware();
                    }

                    onEntered: parent.color = '#444'
                    onExited: { lastColor = 'black'; parent.color = 'black' }
                    onPressed: { lastColor = parent.color; parent.color =  '#888' }
                    onReleased: parent.color = lastColor
                  }
                }
              }
            }
          }
          Item {
            width: parent.width
            height: 20
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
        deviceManagerListFill();
        session.downloadFromUrl("https://github-cloud.s3.amazonaws.com/releases/26525695/3fe901bc-7d73-11e5-8c12-7b3a65a3415a.bin?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAISTNZFOVBIJMK3TQ/20151123/us-east-1/s3/aws4_request&X-Amz-Date=20151123T131406Z&X-Amz-Expires=300&X-Amz-Signature=4e2d82283185ccbb1bbbe956c79dac60686eac55acda4c55fe9a3fbcee68348d&X-Amz-SignedHeaders=host&actor_id=3383080&response-content-disposition=attachment; filename=m1000.bin&response-content-type=application/octet-stream");
      }
    }

    Connections {
     target: session
       onDevicesChanged: {
           deviceManagerListFill();
       }
    }
  }

  TextArea {
    id: logOutput
    readOnly: true;
    Layout.fillWidth: true
    backgroundVisible: false
    selectByKeyboard: true
    selectByMouse: true

    implicitHeight: 51

    style: TextAreaStyle {
      textColor: "#fff"
      selectionColor: "steelblue"
      selectedTextColor: "#eee"
      backgroundColor: "#eee"
    }
  }
}
