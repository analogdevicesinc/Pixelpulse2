import QtQuick 2.1

MouseArea {
  anchors.top: parent.top
  anchors.horizontalCenter: parent.right
  anchors.bottom: parent.bottom
  width: 16

  cursorShape: Qt.SizeVerCursor

  function set(mouse) {
    channel.mode = signal.label == 'Voltage' ? 1 : 2; // TODO: `sourceMode` in signalInfo
    signal.src.v1 = Math.min(Math.max(axes.pxToY(mouse.y), signal.min), signal.max)
  }

  onPositionChanged: set(mouse)
  onClicked: set(mouse)

  Item {
    id: dragDot
    anchors.horizontalCenter: parent.horizontalCenter
    width: 0
    height: 0

    property real value: signal.src.v1
    y: axes.yToPx(value)

    Text {
      anchors.verticalCenter: parent.verticalCenter
      anchors.right: parent.left
      anchors.rightMargin: 12
      text: dragDot.value.toFixed(2)
      color: 'white'
    }

    Rectangle {
      width: 12
      height: width
      radius: width/2
      color: signal.isOutput ? "blue" : "black"
      border.width: signal.isOutput ? 0 : 3
      border.color: "blue"
      x: -height/2
      y: -width/2
    }
  }
}
