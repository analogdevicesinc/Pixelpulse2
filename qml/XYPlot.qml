import QtQuick 2.1
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import Plot 1.0


Item {
  Layout.fillWidth: true
  Layout.fillHeight: true

  property var vsignal
  property var isignal
  property var xsignal: vsignal;
  property var ysignal: isignal;

  Axes {
    id: axes

    anchors.fill: parent
    anchors.leftMargin: 64
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

          if (axes.ymax - axes.ymin < ysignal.resolution * 8 && s < 1) return;

          axes.ymin = Math.max(y - s * (y - axes.ymin), ysignal.min);
          axes.ymax = Math.min(y - s * (y - axes.ymax), ysignal.max);
        }
		else {
          var s = Math.pow(1.15, -wheel.angleDelta.y/120);
          var x = axes.pxToX(wheel.x);

          if (axes.xmax - axes.xmin < xsignal.resolution * 8 && s < 1) return;
          axes.xmin = Math.max(x - s * (x - axes.xmin), xsignal.min);
          axes.xmax = Math.min(x - s * (x - axes.xmax), xsignal.max);
		}
      }
    }
    gridColor: '#222'
    textColor: '#fff'

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
}
