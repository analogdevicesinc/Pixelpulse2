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
                         "fw_updt_needed": true && devListView.latestVersion != 'v0.0',
                         "updt_in_progress": false,
                         "status": "prog"
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

  function programmingModeDeviceExists()
  {
     var msg = bossac.deviceInformation();
     var deviceExists = false;

      if (msg.substr(0, 19) === "Device found on COM") {
        deviceExists = true;
      }

      return deviceExists;
  }

  function programmingModeDeviceDetect()
  {
    var ret;
    clearProgModeDeviceFromList();
    ret = programmingModeDeviceExists();
    if (ret)
      addProgModeDeviceToList();

    return ret;
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
                         "updt_in_progress": model.updt_in_progress,
                         "status": model.status};
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
                           "fw_updt_needed": updt_needed && devListView.latestVersion != 'v0.0',
                           "updt_in_progress": false,
                           "status": "n/a"
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

  function checkFWversion()
  {
    JSUtils.checkLatestFw(function(ver){
          devListView.latestVersion = ver;
          if (ver === 'v0.0')
            logOutput.appendMessage('Failed to get the latest firmware version.' +
                             'Check your internet connection and then click the "Refresh" button.');
    });
  }

  ToolbarStyle {
    Layout.fillWidth: true
    Layout.minimumWidth: parent.Layout.minimumWidth
    Layout.maximumWidth: parent.Layout.maximumWidth
    height: toolbarHeight
  }

  Rectangle {
    id: devListRefreshBtn
    anchors { left: parent.left;
              right: parent.right;
              leftMargin: 5;
              rightMargin: 5 }
    height: 25
    radius: 4
    color: 'grey'

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - 2
      height: parent.height - 2
      radius: 4
      gradient: Gradient {
        GradientStop { position: 0.0; color: '#565666' }
        GradientStop { position: 0.15; color: '#6a6a7d' }
        GradientStop { position: 0.5; color: '#5a5a6a' }
        GradientStop { position: 1.0; color: '#585868' }
      }

      Text {
        x: 5
        text: "Refresh Device List"
        font.pointSize: 10
        color: 'white'
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
      }

      MouseArea {
        hoverEnabled: true
        anchors.fill: parent
        onClicked: {
          if (devListView.latestVersion == 'v0.0')
            checkFWversion();
          deviceManagerListFill();
          logOutput.clearLog();
        }

        onPressed: devListRefreshBtn.color = 'black'
        onReleased: devListRefreshBtn.color = 'grey'
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

    property string latestVersion: 'v0.0'

    Component.onCompleted: {
        checkFWversion();
    }

    onLatestVersionChanged: {
      console.log("latestVersion changed to: ", latestVersion);
      if (latestVersion === 'v0.0')
        return;

      deviceManagerListFill();
      JSUtils.getFirmwareURL(function(url) {
        console.log("LOG URL: ", url);
        session.downloadFromUrl(url);
      });
    }

    ListModel {
      id: devicesModel
      property variant states: { 'ok': 'Succesfully updated. Disconnect device.',
                                 'error': 'Failed to load firmware.',
                                 'prog': 'In programming mode.',
                                 'n/a': '' }
      property variant statesColor: { 'ok': 'green',
                                      'error': 'red',
                                      'prog': 'blue',
                                      'n/a': 'white' }
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
                id: devUpdateBtn
                height: parent.height
                width: 115
                radius: 4
                color: 'grey'
                visible: fw_updt_needed === true

                Rectangle {
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width - 2
                  height: parent.height - 2
                  radius: 4
                  gradient: Gradient {
                    GradientStop { position: 0.0; color: '#565666' }
                    GradientStop { position: 0.15; color: '#6a6a7d' }
                    GradientStop { position: 0.5; color: '#5a5a6a' }
                    GradientStop { position: 1.0; color: '#585868' }
                  }

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
                      var err;

                      if (name === "[Device In Programming Mode]") {
                        // Devices in programming mode can be disconnected without us to know about it, so check if the device is still there.
                        if (!programmingModeDeviceExists()) {
                          clearProgModeDeviceFromList();
                          return;
                        }

                        ret = bossac.flashByFilename("firmware.bin");
                        if (ret.length === 0) {
                          devicesModel.setProperty(index, "firmware_version", devListView.latestVersion);
                          devicesModel.setProperty(index,"status", "ok");
                        } else {
                          devicesModel.setProperty(index,"status", "error");
                          logOutput.appendMessage(ret);
                        }
                      } else if (!programmingModeDeviceDetect()) {
                        devicesModel.setProperty(index, "updt_in_progress", true);
                        session.devices[index].ctrl_transfer(0xBB, 0, 0);
                        ret = bossac.flashByFilename("firmware.bin");
                        if (ret.length === 0) {
                          devicesModel.setProperty(index, "firmware_version", devListView.latestVersion);
                          devicesModel.setProperty(index,"status", "ok");
                        } else {
                          devicesModel.setProperty(index,"status", "error");
                          logOutput.appendMessage(ret);
                        }
                        devicesModel.setProperty(index, "fw_updt_needed", false);
                        // TO DO: Now the user needs to unplug the device. App should monitor the COM port to check if the device has been disconnected
                        // and remove the item in the device list. The monitoring should be done in a separate thread.

                      } else {
                          logOutput.appendMessage("A device is already in programming mode and needs to be programmed first!");
                      }
                    }

                    onPressed: devUpdateBtn.color = 'black'
                    onReleased: devUpdateBtn.color = 'grey'
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
          Item {
            width: parent.width
            height: 20
            visible: status !== 'n/a'
            Row {
              Text { text: "Status: ";
                     font.pointSize: 10;
                     color: 'white';
                     anchors.verticalCenter: parent.verticalCenter}
              Text { text: devicesModel.states[status]
                     font.pointSize: 10;
                     color: devicesModel.statesColor[status];
                     anchors.verticalCenter: parent.verticalCenter}
            }
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

  Rectangle {
    id: logCleanBtn
    anchors { right: parent.right;
              bottom: logOutput.top;
              rightMargin: 5 }
    height: 20
    width: 70
    radius: 4
    color: 'grey'

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - 2
      height: parent.height - 2
      radius: 4
      gradient: Gradient {
        GradientStop { position: 0.0; color: '#565666' }
        GradientStop { position: 0.15; color: '#6a6a7d' }
        GradientStop { position: 0.5; color: '#5a5a6a' }
        GradientStop { position: 1.0; color: '#585868' }
      }

      Text {
        x: 5
        text: "Clean Log"
        font.pointSize: 10
        color: 'white'
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
      }

      MouseArea {
        hoverEnabled: true
        anchors.fill: parent
        onClicked: {
          logOutput.clearLog();
        }

        onPressed: logCleanBtn.color = 'black'
        onReleased: logCleanBtn.color = 'grey'
      }
    }
  }

  TextArea {
    property int logId: 0

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

    TextEdit {
      id: textEdit
    }

    function appendMessage(message)
    {
      logOutput.append(logId.toString() + ': ' + message + '\n');
      logId ++;
    }
    function clearLog()
    {
        logOutput.cursorPosition = 0;
        logOutput.text = "";
        logId = 0;
    }
  }
}
