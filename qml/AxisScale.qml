import QtQuick 2.0
import QtGraphicalEffects 1.0
import "axesutils.js" as AxesUtils

Item {
  id: axisScale
  property var signalParent
  property bool vertical
  property real min
  property real max
  property color textColor
  property int textSize: 14
  property bool withGrid: false

  property int gridticks: (vertical ? height : width) / 12
  property real scaleStep: AxesUtils.step(min, max, gridticks)
  property real start: Math.ceil(min / scaleStep)
  property real scale: vertical ? height / (max - min) : width / (max - min)
  property int txtHorizOffset: withGrid ? 5 : 0

  QtObject {
    id: priv
    function xToPx(x) { return (x - axisScale.min) * axisScale.scale }
    function yToPx(y) { return axisScale.height - (y - axisScale.min) * axisScale.scale }
    function pxToY(px) { return (axisScale.height - px) / axisScale.scale + axisScale.min }
    function pxToX(px) { return px / axisScale.scale + axisScale.min }
  }

  function valToPx(val) { return vertical ? priv.yToPx(val) : priv.xToPx(val) }
  function pxToVal(px) { return vertical ? priv.pxToY(px) : priv.pxToX(px) }

  Rectangle {
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      width: 1
      color: 'grey'
      visible: withGrid
  }

  // Build the values along the axis
  Repeater {
    model: gridticks
    Text {
      property real val: (start + index) * scaleStep
      visible: val <= max
      x: vertical ? txtHorizOffset : valToPx(val) - (paintedWidth /2)
      y: vertical ? valToPx(val) - (paintedHeight /2) : 0
      font.pixelSize: textSize
      color: textColor
      text: val
      rotation: vertical ? 0 : -90
    }
  }

  Repeater {
    model: gridticks
    Rectangle {
      property real val: (start + index) * scaleStep
      visible: val <= max && withGrid
      x: -6
      y: valToPx(val)
      height: 1
      width: 6
      color: 'grey'
    }
  }

  // Allow zomming in and out by pressing and holding the right mouse
  // button while moving the mouse cursor along the axis (dragging)
  MouseArea {
    anchors.fill: parent

    property var zoomParams
    acceptedButtons: Qt.RightButton
    onPressed: {
      if (mouse.button == Qt.RightButton) {
        zoomParams = {
          firstCoord : vertical ? mouse.y : mouse.x,
          prevCoord : vertical ? mouse.y : mouse.x,
        }
      } else {
        mouse.accepted = false;
      }
    }
    onReleased: {
      zoomParams = null
    }
    onPositionChanged: {
      if (zoomParams) {
        var delta = vertical ? mouse.y - zoomParams.prevCoord : -(mouse.x - zoomParams.prevCoord)
        zoomParams.prevCoord = vertical ? mouse.y : mouse.x
        var s = Math.pow(1.01, delta)
        var newVal = pxToVal(zoomParams.firstCoord);

        if (max - min < signalParent.resolution * 8 && s < 1) return;

        min = Math.max(newVal - s * (newVal - min), signalParent.min);
        max = Math.min(newVal - s * (newVal - max), signalParent.max);
      }
    }
  }
}
