import QtQuick 2.1

Item {
  width: 0
  height: 0
  default property alias content: rect.children

  property real value
  property var color
  property bool filled

  Text {
    anchors.verticalCenter: parent.verticalCenter
    anchors.right: parent.left
    anchors.rightMargin: 12
    text: value.toFixed(4)
    color: 'white'
  }

  Rectangle {
    id: rect
    width: 12
    height: width
    radius: width/2
    color: filled ? parent.color : "black"
    border.width: filled ? 0 : 3
    border.color: parent.color
    x: -height/2
    y: -width/2
  }
}
