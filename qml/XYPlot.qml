import QtQuick 2.1
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import Plot 1.0


Item {
  // keep plots slightly smaller than half the height
  Layout.preferredHeight: (parent.parent.height/2)-80
  property var vsignal
  property var isignal
  property var xsignal: vsignal;
  property var ysignal: isignal;
  property int textSpacing: 12

  Axes {
    id: axes

    anchors.fill: parent
    anchors.leftMargin: 64
    anchors.rightMargin: 32
    anchors.topMargin: 32
    anchors.bottomMargin: 32

    xmin: horizontalScale.min
    xmax: horizontalScale.max
    ymin: verticalScale.min
    ymax: verticalScale.max

    // Shift + scroll for Y-axis zoom
    MouseArea {
      anchors.fill: parent
      onPressed: {
        mouse.accepted = false
      }

      onWheel: {
        if (wheel.modifiers & Qt.ShiftModifier) {
          var s = Math.pow(1.15, -wheel.angleDelta.y/120);
          var y = verticalScale.pxToVal(wheel.y);

          if (verticalScale.max - verticalScale.min < ysignal.resolution * 8 && s < 1) return;

          verticalScale.min = Math.max(y - s * (y - verticalScale.min), ysignal.min);
          verticalScale.max = Math.min(y - s * (y - verticalScale.max), ysignal.max);
        }
		else {
          var s = Math.pow(1.15, -wheel.angleDelta.y/120);
          var x = horizontalScale.pxToVal(wheel.x);

          if (horizontalScale.max - horizontalScale.min < xsignal.resolution * 8 && s < 1) return;
          horizontalScale.min = Math.max(x - s * (x - horizontalScale.min), xsignal.min);
          horizontalScale.max = Math.min(x - s * (x - horizontalScale.max), xsignal.max);
		}
      }
    }

    gridColor: '#222'

    Rectangle {
      anchors.fill: parent
      color: '#0c0c0c'
      z: -1
    }

    PhosphorRender {
        id: line
        anchors.fill: parent
        clip: true

        xBuffer: xsignal.buffer
        buffer: ysignal.buffer
        pointSize: 2

        xmin: axes.xmin
        xmax: axes.xmax
        ymin: axes.ymin
        ymax: axes.ymax
    }
  }

  AxisScale {
    id: verticalScale
    signalParent: ysignal
    vertical: true
    min: ysignal.min
    max: ysignal.max
    textColor: '#fff'

    anchors.right: axes.left
    anchors.rightMargin: textSpacing * 2
    anchors.leftMargin: textSpacing
    anchors.top: axes.top
    anchors.bottom: axes.bottom
    width: textSpacing * 2
  }

  AxisScale {
    id: horizontalScale
    signalParent: xsignal
    vertical: false
    min: xsignal.min
    max: xsignal.max
    textColor: '#fff'

    anchors.left: axes.left
    anchors.right: axes.right
    anchors.top: axes.bottom
    anchors.bottomMargin: textSpacing * 2
    anchors.topMargin: textSpacing
    height: textSpacing * 2
  }

}
