import QtQuick 2.1

Item {
  id: dot
  width: 0
  height: 0
  default property alias content: rect.children

  property real value
  property var color
  property bool filled

  property var dragOn
  signal drag(variant pos)
  signal pressed(variant mouse)
  signal released()

  property bool label: true

  Text {
    anchors.verticalCenter: parent.verticalCenter
    anchors.right: parent.left
    anchors.rightMargin: 12
    text: label ? value.toFixed(4):""
    color: 'white'
    visible: parent.x <= 50 ? false : true;
  }

  Text {
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.right
    anchors.leftMargin: 12
    text: label ? value.toFixed(4):""
    color: 'white'
    visible: parent.x <= 50 ? true : false;
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

    MouseArea {
      id: mouse_area
      visible: !!dragOn
      anchors.fill: parent
      anchors.margins: -4
      onPressed: {
        dot.pressed(mouse)
      }
      onPositionChanged: {
        var pos = this.mapToItem(dragOn, mouse.x, mouse.y)
        pos.modifiers = mouse.modifiers
        dot.drag(pos, x, y)
      }
      onReleased: { dot.released() }
    }
  }
}
