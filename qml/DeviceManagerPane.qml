import QtQuick 2.1
import QtQuick.Layouts 1.0
import QtQml.Models 2.1
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import "jsutils.js" as JSUtils

ColumnLayout {
  id: smpLayout
  spacing: 12

  function addProgModeDeviceToList()
  {
    devicesModel.insert(devicesModel.count,
                        {"name": "[Device In Programming Mode]",
                         "uid":"N/A",
                         "firmware_version": "N/A",
                         "hardware_version": "N/A",
                         "fw_updt_needed": true && devListView.latestVersion != '0.0',
                         "updt_in_progress": false,
                        });
  }

  function clearProgModeDeviceFromList()
  {
    for (var i = 0; i < devicesModel.count; i++) {
      if (devicesModel.get(i).name === "[Device In Programming Mode]") {
        devicesModel.remove(i, 1);
        break;
      }
    }
  }

  function programmingModeDeviceDetect()
  {
    var msg = bossac.deviceInformation();
    var deviceDetected = false;

    clearProgModeDeviceFromList();
    if (msg.substr(0, 19) === "Device found on COM") {
      deviceDetected = true;
      addProgModeDeviceToList();
    }

    return deviceDetected;
  }

  function deviceManagerListFill() {
    var showPane = false;

    if (devicesModel.count > 0) {
      var n;
      var updatingDevice = false;
      for (n = 0; n < devicesModel.count; n++) {
        if (devicesModel.get(n).updt_in_progress == true)
            break;
      }
      updatingDevice = n < devicesModel.count;

      if (updatingDevice) {
        var model = devicesModel.get(n);
        var modelCopy = {"name": model.name,
                         "uid": model.uid,
                         "firmware_version": model.firmware_version,
                         "hardware_version": model.hardware_version,
                         "fw_updt_needed": model.fw_updt_needed,
                         "updt_in_progress": model.updt_in_progress};
      }
      devicesModel.clear();
    }
    for (var i = 0; i < session.devices.length; i++) {
      var device = session.devices[i];
      var updt_needed = false;

      if (device.FWVer.indexOf('.') === -1)   // The firmware might be so old that won't provide the version in the 'major.minor' format
          updt_needed = true;
      else if (parseFloat(device.FWVer) < parseFloat(devListView.latestVersion.substring(1)))
        updt_needed = true;

      devicesModel.insert(devicesModel.count,
                          {"name": device.label,
                           "uid":device.UUID,
                           "firmware_version": device.FWVer,
                           "hardware_version": device.HWVer,
                           "fw_updt_needed": updt_needed,
                           "updt_in_progress": false,
                          });

      if (updt_needed === true)
         showPane = true;
    }

    if (updatingDevice) {
      modelCopy.updt_in_progress = false;
      devicesModel.insert(n, modelCopy);
    }

    if (showPane)
      deviceMngrVisible = true;
    if (!updatingDevice)
      programmingModeDeviceDetect();
  }

  ToolbarStyle {
    Layout.fillWidth: true
    Layout.minimumWidth: parent.Layout.minimumWidth
    Layout.maximumWidth: parent.Layout.maximumWidth
    height: toolbarHeight
  }

  Rectangle {
    id: devListRefreshBtn
    Layout.fillWidth: true
    Layout.minimumWidth: parent.Layout.minimumWidth
    Layout.maximumWidth: parent.Layout.maximumWidth
    height: 25
    color: '#333'

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - 2
      height: parent.height - 2
      color: 'black'

      Text {
        x: 5
        text: "Refresh Device List"
        font.pointSize: 10
        color: 'white'
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
      }

      MouseArea {
        property color lastColor: 'black'

        hoverEnabled: true
        anchors.fill: parent
        onClicked: {
          logOutput.text = "";
          deviceManagerListFill();
        }

        onEntered: parent.color = '#444'
        onExited: { lastColor = 'black'; parent.color = 'black' }
        onPressed: { lastColor = parent.color; parent.color =  '#888' }
        onReleased: parent.color = lastColor
      }
    }
  }

  Rectangle {
    id: devListView
    Layout.fillHeight: true
    Layout.fillWidth: true
    Layout.minimumWidth: parent.Layout.minimumWidth
    Layout.maximumWidth: parent.Layout.maximumWidth
    color: 'black'

    property string latestVersion: '0.0'

    Component.onCompleted: {
        JSUtils.checkLatestFw(function(ver){
            latestVersion = ver;
        });
    }

    onLatestVersionChanged: {
      console.log("latestVersion changed to: ", latestVersion);
      deviceManagerListFill();
      JSUtils.getFirmwareURL(function(url) {
        console.log("LOG URL: ", url);
        session.downloadFromUrl(url);
      });
    }

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
                visible: fw_updt_needed === true

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
                    visible: !updt_in_progress

                    hoverEnabled: true
                    anchors.fill: parent
                    onClicked: {
                      var ret;
                      if (name === "[Device In Programming Mode]") {
                        logOutput.text = "";
                        ret = bossac.flashByFilename("firmware.bin");
                        if (ret) {
                          devicesModel.setProperty(index, "firmware_version", devListView.latestVersion);
                          logOutput.text = "Firmware updated succesfully. Please disconnect the device.";
                        } else {
                          logOutput.text = "Failed to load firmware.";
                        }
                      } else if (!programmingModeDeviceDetect()) {
                        logOutput.text = "";
                        devicesModel.setProperty(index, "updt_in_progress", true);
                        session.devices[index].ctrl_transfer(0xBB, 0, 0);
                        ret = bossac.flashByFilename("firmware.bin");
                        if (ret) {
                          devicesModel.setProperty(index, "firmware_version", devListView.latestVersion);
                          logOutput.text = "Firmware updated succesfully. Please disconnect the device.";
                        } else {
                          logOutput.text = "Failed to load firmware.";
                        }
                        devicesModel.setProperty(index, "fw_updt_needed", false);
                        // TO DO: Now the user needs to unplug the device. App should monitor the COM port to check if the device has been disconnected
                        // and remove the item in the device list. The monitoring should be done in a separate thread.

                      } else {
                          logOutput.text = "A device is already in programming mode and needs to be programmed first!";
                      }
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
            visible: false
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
    Layout.minimumWidth: parent.Layout.minimumWidth
    Layout.maximumWidth: parent.Layout.maximumWidth
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
