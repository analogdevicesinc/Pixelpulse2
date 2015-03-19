import QtQuick 2.1

Rectangle {
  id: timeline
  anchors.top: parent.top
  color: "#424242"
  clip: true

  gradient: Gradient {
    GradientStop { position: 0.0; color: '#404040' }
    GradientStop { position: 0.15; color: '#5a5a5a' }
    GradientStop { position: 0.5; color: '#444444' }
    GradientStop { position: 1.0; color: '#424242' }
  }

  property var xaxis
  property real min_spacing: 70
  property real pow: Math.floor(Math.log(min_spacing * 100 / xaxis.xscale) / Math.LN10)
  property real majorStep: Math.pow(10, pow)
  property real step: majorStep / 10
  property real start: Math.floor(xaxis.visibleMin / step)

  property real unitPow: (pow - 2) % 3 + 1
  property real unitScale: Math.pow(10, unitPow)
  property string unit: unitFor(pow)

  function unitFor(pow) {
    switch (Math.floor(pow / 3) * 3) {
      case 0: return ' s'
      case -3: return ' ms'
      case -6: return ' us'
      case -9: return ' ns'
      case -12: return ' ps'
      default: return ''
    }
  }

  Repeater {
    model: timeline.width / min_spacing + 1
    Rectangle {
        property real n: start + index
        property real xval: n * step
        property real rel: ((n % 10 + 10) % 10)
        property bool isMajor: rel == 0
        property real relVal: rel * unitScale

        visible: xval >= xaxis.boundMin && xval <= xaxis.boundMax

        x: xaxis.xToPx(xval)
        y: timeline.height-height
        width: 1
        height: isMajor ? 40 : 12

        Text {
          text: isMajor ? (xval.toFixed(Math.max(-pow, 0)) + ' s') : ('+' + relVal.toFixed((unitPow==-1)?1:0) + unit)
          color: 'white'
          anchors.left: parent.left
          anchors.leftMargin: isMajor ? 6 : -4
          anchors.bottomMargin: isMajor ? -12 : -1
          anchors.bottom: parent.top
        }
    }
  }

  MouseArea {
    id: timelineheader_mouse_area
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
        mouse.accepted = false;
      }
    }
    onReleased: {
      zoomParams = null
    }
    onPositionChanged: {
      if (zoomParams) {
        var delta = (mouse.x - zoomParams.prevX)
        zoomParams.prevX = mouse.x
        var s = Math.pow(1.005, delta)
        var oldScale = xaxis.xscale
        var minScale = xaxis.timelineflickable.width/(xaxis.boundMax - xaxis.boundMin)
        xaxis.xscale = Math.min(Math.max(xaxis.xscale*s, minScale), xaxis.maxScale)

        xaxis.timelineflickable.contentX = (xaxis.xscale / oldScale) * (xaxis.timelineflickable.contentX + zoomParams.firstX) - zoomParams.firstX
        xaxis.timelineflickable.returnToBounds()
      }
    }
  }
}
