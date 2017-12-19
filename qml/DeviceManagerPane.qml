import QtQuick 2.1
import QtQuick.Layouts 1.0
import QtQml.Models 2.1
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import "jsutils.js" as JSUtils

ColumnLayout {
  id: smpLayout
  spacing: 12

  property bool updateNeeded: false
  property bool justUpdated: false
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
     var deviceExists = false;
        if(session.programmingModeDeviceExists() > 0)
            deviceExists = true;

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
    console.log(programmingModeDeviceDetect()+" detected devices");
    if(programmingModeDeviceDetect()){
        if(!justUpdated){
            updateNeeded = true;
        }
        justUpdated = false;
        console.log("update needded: " + updateNeeded);
    }
    for (var i = 0; i < session.devices.length; i++) {
      var device = session.devices[i];
      var updt_needed = false;

      if (device.FWVer.indexOf('.') === -1)   // The firmware might be so old that won't provide the version in the 'major.minor' format
      {
          updt_needed = true;
          updateNeeded = true;
      }

      else if (parseFloat(device.FWVer) < parseFloat(devListView.latestVersion.substring(1))){
        updt_needed = true;
          updateNeeded = true;
      }

      console.log("Right before dev insert \n");
      devicesModel.insert(devicesModel.count,
                          {"name": device.label,
                           "uid":device.UUID,
                           "firmware_version": device.FWVer,
                           "hardware_version": device.HWVer,
                           "fw_updt_needed": updt_needed && devListView.latestVersion != 'v0.0',
                           "updt_in_progress": false,
                           "status": (!updt_needed && (devListView.latestVersion != 'v0.0')) ? 'fw_ok' : "n/a"
                          });

      if (updt_needed === true)
         showPane = true;
    }

    if (updatingDevice) {
      modelCopy.updt_in_progress = false;
      devicesModel.insert(n, modelCopy);
    }

    if (!updatingDevice)
      if(programmingModeDeviceDetect()){
          showPane = true;
      }

    if (showPane)
      deviceMngrVisible = true;
  }

  function checkFWversion()
  {
    JSUtils.checkLatestFw(
      function(ver) {
        devListView.latestVersion = ver;
      },
      function(err) {
        if (err === JSUtils.GIT_RATE_LIMIT_EXCEEDED) {
          logOutput.appendMessage('Failed to get the latest firmware version. ' +
              'Number of requests to GIT was exceeded. A new request will be possible in an hour.');
        } else {
          logOutput.appendMessage('Failed to get the latest firmware version. ' +
              'Check your internet connection and then click the "Refresh" button.');
        }
      }
    ); // end JSUtils.checkLatestFw()
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
                                 'fw_ok': 'Firmware is up to date.',
                                 'n/a': '' }
      property variant statesColor: { 'ok': 'green',
                                      'error': 'red',
                                      'prog': 'blue',
                                      'fw_ok': 'white',
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
                color: 'black'
                visible: fw_updt_needed === true

                  Text {
                    x: 5
                    text: "Update Firmware"
                    font.pointSize: 10
                    color: 'steelblue'
                    anchors.verticalCenter: parent.verticalCenter
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
    id: updateBtn
    anchors { right: parent.right;
              bottom: logCleanBtn.top;
              bottomMargin: 5;
              rightMargin: 5 }
    height: 25
    width: 145
    radius: 4
    color: 'grey'
    visible: updateNeeded === true

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
        anchors.horizontalCenter: parent.horizontalCenter
      }

      MouseArea {
        hoverEnabled: true
        anchors.fill: parent
        onClicked: {
            var firmwareFilePath = session.getTmpPathForFirmware() + "/firmware.bin";
            var ret;

            session.closeAllDevices();
            devicesModel.clear();
            justUpdated = true;
            updateNeeded = false;
            ret = session.flash_firmware(firmwareFilePath);

            if (ret.length === 0) {
                logOutput.appendMessage("All devices were succesfully updated. Disconnect devices");
            } else {
              logOutput.appendMessage(ret);
            }
        }

        onPressed: updateBtn.color = 'black'
        onReleased: updateBtn.color = 'grey'
      }
    }
  }


  Rectangle {
    id: logCleanBtn
    anchors { right: parent.right;
              bottom: logOutput.top;
              bottomMargin: 5;
              rightMargin: 5 }
    height: 25
    width: 85
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
    implicitHeight: 70

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
