import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.1
import QtQuick.Dialogs 1.0
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0

Dialog {
  title: "Acquisition Settings"
  width: 300
  height: 200
  modality: Qt.NonModal

  contentItem:
    Rectangle{
      id: rectangle
      anchors.fill: parent
      color: '#222'

      RowLayout {
        anchors.fill: parent
        anchors.topMargin: 40
        anchors.bottomMargin: 40
        anchors.leftMargin: 40
        anchors.rightMargin: 40
        spacing: 25

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
          activeFocusOnPress: true
          activeFocusOnTab: true

          implicitWidth: 75

//          style: SpinBoxStyle {
//            background: Rectangle {
//              //anchors.fill: parent
//              implicitWidth: 100
//              implicitHeight: 30
//              color: rectangle.color
//            }
//            textColor: 'white'
//          }

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
        }
      }
    }
}
