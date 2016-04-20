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
  property int ygridticks: axes.ygridticks;
  property int xgridticks: axes.xgridticks;

  Axes {
    id: axes

    anchors.fill: parent
    anchors.leftMargin: 94
    anchors.rightMargin: 32
    anchors.topMargin: 32
    anchors.bottomMargin: 32

    xmin: xsignal.min
    xmax: xsignal.max
    ymin: ysignal.min
    ymax: ysignal.max
    yleft: true
    yright: false
    xbottom: true

    // Shift + scroll for Y-axis zoom
    MouseArea {
      anchors.fill: parent
      onPressed: {
        mouse.accepted = false
      }

      onWheel: {
        if (wheel.modifiers & Qt.ShiftModifier) {
          var s = Math.pow(1.15, -wheel.angleDelta.y/120);
          var y = axes.pxToY(wheel.y);

          if (axes.ymax - axes.ymin < ysignal.resolution * ygridticks * 8 && s < 1) return;

          axes.ymin = Math.max(y - s * (y - axes.ymin), ysignal.min);
          axes.ymax = Math.min(y - s * (y - axes.ymax), ysignal.max);
        }
		else {
          var s = Math.pow(1.15, -wheel.angleDelta.y/120);
          var x = axes.pxToX(wheel.x);

          if (axes.xmax - axes.xmin < xsignal.resolution * xgridticks && s < 1) return;
          axes.xmin = Math.max(x - s * (x - axes.xmin), xsignal.min);
          axes.xmax = Math.min(x - s * (x - axes.xmax), xsignal.max);
		}
      }
    }
    gridColor: window.gridAxesColor
    textColor: '#fff'

    Rectangle {
      id: axesBackground
      anchors.fill: parent
      color: window.xyplotColor
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

  Item {
      id: vertAxisScale

      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.left: parent.lefts
      anchors.bottomMargin: axes.anchors.bottomMargin
      width: axes.anchors.leftMargin

      MouseArea {
        anchors.fill: parent
        property var zoomParams
        acceptedButtons: Qt.RightButton
        onPressed: {
          if (mouse.button == Qt.RightButton) {
            zoomParams = {
              firstY : mouse.y,
              prevY : mouse.y,
            }
          } else {
            mouse.accepted = false
          }
        }
        onReleased: {
          zoomParams = null;
        }
        onPositionChanged: {
          if (zoomParams) {
            var delta = (mouse.y - zoomParams.prevY)
            zoomParams.prevY = mouse.y
            var s = Math.pow(1.01, delta)
            var y = axes.pxToY((zoomParams.firstY))

            if (axes.ymax - axes.ymin < ysignal.resolution * ygridticks * 8 && s < 1) return;

            axes.ymin = Math.max(y - s * (y - axes.ymin), ysignal.min);
            axes.ymax = Math.min(y - s * (y - axes.ymax), ysignal.max);
          }
        }
      }
  }

  Item {
      id: horizAxisScale

      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: axes.anchors.leftMargin
      anchors.rightMargin: axes.anchors.rightMargin
      height: axes.anchors.bottomMargin

      MouseArea {
        anchors.fill: parent
        property var zoomParams
        acceptedButtons: Qt.RightButton
        onPressed: {
          if (mouse.button == Qt.RightButton) {
            zoomParams = {
              firstX : mouse.x,
              prevX : mouse.x,
            }
          } else {
            mouse.accepted = false
          }
        }
        onReleased: {
          zoomParams = null;
        }
        onPositionChanged: {
          if (zoomParams) {
            var delta = -(mouse.x - zoomParams.prevX)
            zoomParams.prevX = mouse.x
            var s = Math.pow(1.01, delta)
            var x = axes.pxToX((zoomParams.firstX))

            if (axes.xmax - axes.xmin < xsignal.resolution * xgridticks  && s < 1) return;

            axes.xmin = Math.max(x - s * (x - axes.xmin), xsignal.min);
            axes.xmax = Math.min(x - s * (x - axes.xmax), xsignal.max);
          }
        }
      }
  }
}
