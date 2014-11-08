import QtQuick 2.1

MouseArea {
    z: -1
    property real boundMin: 0
    property real boundMax: 1

    property real maxScale: 100000000
    property real xscale: 100 // pixels per unit

    readonly property real visibleMin: boundMin + timeline_flickable.contentX / xscale
    readonly property real visibleMax: boundMin + (timeline_flickable.contentX + timeline_flickable.width) / xscale

    function xToPx(x) {
      return xscale * (x - boundMin) - timeline_flickable.contentX
    }

    function pxToX(px) {
      return boundMin + (timeline_flickable.contentX + px) / xscale
    }

    function setVisible(min, max) {
      xscale = timeline_flickable.width / (max - min)
      timeline_flickable.contentX = xscale*(min - boundMin)
    }

    function setBounds(min, max) {
      boundMin = min
      boundMax = max
    }

    onBoundMaxChanged: {
      if (boundMax < visibleMax || timeline_flickable.atXEnd) {
        setVisible(visibleMin, boundMax)
      }
    }

    onWheel: {
        var s = Math.pow(1.15, wheel.angleDelta.y/120)
        var oldScale = xscale
        var minScale = timeline_flickable.width/(boundMax - boundMin)
        xscale = Math.min(Math.max(xscale*s, minScale), maxScale)

        timeline_flickable.contentX = (xscale / oldScale) * (timeline_flickable.contentX + wheel.x) - wheel.x
        timeline_flickable.returnToBounds()
    }

    onWidthChanged: {
        var minScale = timeline_flickable.width/(boundMax - boundMin)
        xscale = Math.min(Math.max(xscale, minScale), maxScale)
        timeline_flickable.returnToBounds()
    }

    Flickable {
        id: timeline_flickable

        flickableDirection: Flickable.HorizontalFlick
        contentWidth: parent.xscale * (parent.boundMax - parent.boundMin)

        anchors.fill: parent
    }
}
