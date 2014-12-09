import QtQuick 2.1
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.1

Rectangle {
  gradient: Gradient {
    GradientStop { position: 0.0; color: '#565666' }
    GradientStop { position: 0.15; color: '#6a6a7d' }
    GradientStop { position: 0.5; color: '#5a5a6a' }
    GradientStop { position: 1.0; color: '#585868' }
  }

  property alias btnStyle: btnStyle
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

  default property alias data: inner.data
  RowLayout {
    anchors.fill: parent
    id: inner
  }
}
