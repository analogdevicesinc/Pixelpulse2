import QtQuick 2.1
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0

Item {
  id: axes

  property bool xbottom: true
  property bool yleft: true
  property bool yright: true

  property real xmin: 0
  property real xmax: 1

  property real ymin: 0
  property real ymax: 1

  property real textSpacing: 4

  property int xgridticks: width  / 64
  property int ygridticks: height / 32

  property var gridColor: '#ccc'
  property var textColor: '#444'
  property var textSize: 14

  function step(min, max, count) {
    // Inspired by d3.js
    var span = max - min;
    var step = Math.pow(10, Math.floor(Math.log(span / count) / Math.LN10));
    var err = count / span * step;

	  // Filter ticks to get closer to the desired count.
	       if (err <= .35) step *= 10
	  else if (err <= .75) step *= 5
	  else if (err <= 1.0) step *= 2

    return step
  }

  property real xstep: step(xmin, xmax, xgridticks)
  property real xstart: Math.ceil(xmin / xstep)

  property real ystep: step(ymin, ymax, ygridticks)
  property real ystart: Math.ceil(ymin / ystep)

  property real yscale: height / (ymax - ymin)
  function yToPx(y) { return height - (y - ymin) * yscale }
  function yToPxClamped(y) { return Math.min(Math.max(yToPx(y), 0), height) }
  function pxToY(px) { return (height - px) / yscale + ymin }

  property real xscale: width / (xmax - xmin)
  function xToPx(x) { return (x - xmin) * xscale }

  Repeater {
    model: ygridticks

    Rectangle {
      property real yval: (ystart + index) * ystep
      visible: yval <= ymax
      x: 0
      y: yToPx(yval)
      width: axes.width
      height: 1
      color: gridColor

      Text {
        visible: yleft
        anchors.right: parent.left
        anchors.rightMargin: textSpacing
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: textSize
        color: textColor
        text: yval
      }

      Text {
        visible: yright
        anchors.left: parent.right
        anchors.leftMargin: textSpacing
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: textSize
        color: textColor
        text: yval
      }
    }
  }

  Repeater {
    model: xgridticks

    Rectangle {
      property real xval: (xstart + index) * xstep
      visible: xval <= xmax
      x: xToPx(xval)
      y: 0
      width: 1
      height: axes.height
      color: gridColor

      Text {
        visible: xbottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: textSpacing
        font.pixelSize: textSize
        color: textColor
        text: xval
      }
    }
  }
}
