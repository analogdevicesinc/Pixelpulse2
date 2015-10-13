import QtQuick 2.1
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0

Rectangle {
  property var list

  Rectangle {
    id: dummyDevRect
    anchors.top: parent.top;
    anchors.left: parent.left
    width: timelinePane.spacing
    height: timelinePane.spacing
    color: parent.color
  }

  Selector {
    anchors.top: dummyDevRect.bottom
    itemLabel: list.crtLabel
    enableArrows: list.labelCount > 1
    onNextItem: list.crtLabelPos++
    onPrevItem: list.crtLabelPos--
    minReached: list.posAtLowest
    maxReached: list.posAtHighest
  }
}
