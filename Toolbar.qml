import QtQuick 2.1
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.1

Rectangle {
  radius: 2

  gradient: Gradient {
    GradientStop { position: 0.0; color: '#565666' }
    GradientStop { position: 0.15; color: '#6a6a7d' }
    GradientStop { position: 0.5; color: '#5a5a6a' }
    GradientStop { position: 1.0; color: '#585868' }
  }

  Component {
    id: btnStyle
    ButtonStyle {
      background: Rectangle {
        implicitWidth: 56
        opacity: control.pressed ? 0.3 : control.checked ? 0.2 : 0.01
        color: 'white'
      }
    }
  }

  RowLayout {
    anchors.fill: parent

    ExclusiveGroup {
      id: timeGroup
    }

    ExclusiveGroup {
      id: rateGroup
    }

    Button {
      tooltip: "Menu"
      Layout.fillHeight: true
      style: btnStyle

      menu: Menu {
        Menu {
          title: "Sample Rate"
          MenuItem { exclusiveGroup: rateGroup; checkable: true;
            onTriggered: controller.sampleRate = 1000; text: '1 kHz' }
          MenuItem { exclusiveGroup: rateGroup; checkable: true;
            onTriggered: controller.sampleRate = 4000; text: '4 kHz' }
          MenuItem { exclusiveGroup: rateGroup; checkable: true;
            onTriggered: controller.sampleRate = 10000; text: '10 kHz' }
          MenuItem { exclusiveGroup: rateGroup; checkable: true;
            onTriggered: controller.sampleRate = 40000; text: '40 kHz' }
          MenuItem { exclusiveGroup: rateGroup; checkable: true;
            onTriggered: controller.sampleRate = 100000; text: '100 kHz' }
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
        MenuSeparator{}
        MenuItem { text: "About" }
        MenuItem { text: "Exit"; onTriggered: Qt.quit() }
      }
      iconSource: './icons/gear.png'
    }

  /*
    ColumnLayout {
      visible: false
      Layout.maximumWidth: 96
      ComboBox {
        model: ['1kHz', '10kHz', '20kHz', '40kHz', '80kHz', '100kHz']
        Layout.fillWidth: true
      }
      SpinBox {
        Layout.fillWidth: true
        suffix: "s"
        decimals: 3
        stepSize: 1
        minimumValue: 0.001
        maximumValue: 100
        onValueChanged: {
          controller.sampleTime = value
        }
      }
    }
    */

    Button {
      tooltip: "Start"
      Layout.fillHeight: true
      Layout.alignment: Qt.AlignRight
      style: btnStyle
      iconSource: controller.enabled ? './icons/pause.png' : './icons/play.png'

      onClicked: {
        controller.toggle()
      }
    }
  }


}
