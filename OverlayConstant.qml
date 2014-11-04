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

  DragDot {
    id: dragDot
    anchors.horizontalCenter: parent.horizontalCenter
    y: axes.yToPxClamped(value)

    value: signal.src.v1
    filled: signal.isOutput
    color: "blue"
  }
}
