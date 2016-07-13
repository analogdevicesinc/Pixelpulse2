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
  flags: Qt.Window | Qt.WindowSystemMenuHint | Qt.WindowCloseButtonHint | Qt.WindowTitleHint

  property real timeDelay: delay.value
  property bool showStatusBar: toggleStatusBar.checked

  property real timeDelayOld: 0;

  function delayToSamples(delayVal)
  {
    var timeInSeconds = delayVal / 1000.0;
    var sampleCount = Math.floor(controller.sampleRate * timeInSeconds + 0.5);

    return sampleCount;
  }

  function samplesToSecondsDelay(samplesCount)
  {
    return (samplesCount / controller.sampleRate);
  }

  function onContinuousModeChanged(continuous)
  {
    if (continuous) {
      timeDelayOld = timeDelay;
      delay.value = 0;
    } else {
      delay.value = timeDelayOld;
    }

    delay.enabled = !continuous;
  }

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
          maximumValue: 1000
          minimumValue: 0
          decimals: 2
          stepSize: 0.01

          onValueChanged: {
            var sampleCount = delayToSamples(delay.value);

            if (sampleCount !== controller.delaySampleCount) {
              controller.delaySampleCount = sampleCount;
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
