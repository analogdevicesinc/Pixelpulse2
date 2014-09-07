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

    Button {
      tooltip: "Menu"
      Layout.fillHeight: true
      style: btnStyle

      menu: Menu {
        MenuItem { text: "About" }
        MenuItem { text: "Exit" }
      }
      iconSource: './icons/gear.png'
    }

    Button {
      tooltip: "Start"
      Layout.fillHeight: true
      Layout.alignment: Qt.AlignRight
      style: btnStyle
      iconSource: session.active ? './icons/pause.png' : './icons/play.png'

      onClicked: {
        session.sampleRate = 10000
        session.sampleCount = 10000
        session.start();
      }
    }
  }


}
