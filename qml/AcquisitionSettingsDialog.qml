import QtQuick 2.0
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.1

Window {
  title: "Acquisition Settings"
  minimumWidth: 400
  minimumHeight: 180
  maximumWidth: minimumWidth
  maximumHeight: minimumHeight
  modality: Qt.NonModal
  flags: Qt.Dialog

  property real timeDelay: delay.value
  property bool showStatusBar: toggleStatusBar.checked

  Rectangle {
    id: rectangle
    anchors.fill: parent
    color: '#222'

    ColumnLayout {
      anchors.fill: parent
      anchors.leftMargin: 25
      anchors.rightMargin: 25
      anchors.topMargin: 35
      anchors.bottomMargin: 35
      spacing: 0

      Text {
        text: "Amount of time the received data should be delayed with:"
        color: 'white'
        font.pixelSize: 14
      }

      RowLayout {
        spacing: 15

        Text {
          id: delayLabel
          text: "Delay (ms)"
          color: 'white'
          font.pixelSize: 14
        }

        SpinBox {
          id: delay
          maximumValue: 50
          minimumValue: 0
          decimals: 2
          stepSize: 0.01

          onValueChanged: {
            var timeInSeconds = delay.value / 1000.0;
            var sampleCount = controller.sampleRate * timeInSeconds;

            if (sampleCount !== controller.delaySampleCount) {
              controller.delaySampleCount = sampleCount;
              for (var i = 0; i < session.devices.length; i++) {
                for (var j = 0; j < session.devices[i].channels.length; j++) {
                  session.devices[i].channels[j].signals[0].buffer.setIgnoredFirstSamplesCount(sampleCount);
                  session.devices[i].channels[j].signals[1].buffer.setIgnoredFirstSamplesCount(sampleCount);
                }
              }
            }
          }
          Keys.onPressed: {
            switch (event.key) {
            case Qt.Key_PageDown:
              delay.value -= 0.5;
              break;
            case Qt.Key_PageUp:
              delay.value += 0.5;
              break;
            }
          }
        } // SpinBox
      } // RowLayout

      CheckBox {
        id: toggleStatusBar
        style: CheckBoxStyle {
          label: Label {
                  color: 'white';
                  text: 'Show delay value on main window'
                  font.pixelSize: 14
                }
        }
      } // Checkbox
    } // ColumnLayout
  } // Rectangle
} // Window
