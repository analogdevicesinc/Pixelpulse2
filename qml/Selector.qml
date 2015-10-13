import QtQuick 2.0
import QtQuick.Layouts 1.0

Rectangle {
  id: selector
  property var itemLabel
  property bool enableArrows
  property bool minReached
  property bool maxReached

  color: parent.color
  visible: itemLabel

  signal nextItem()
  signal prevItem()

  Rectangle {
    id: upperArrow
    anchors.top: parent.top
    width: timelinePane.spacing; height: timelinePane.spacing
    color: parent.color
    visible: enableArrows
    Arrow {
      directionUp: true
      onClicked: selector.prevItem()
      active: !minReached
    }
  }

  Text {
    id: itemName
    text: itemLabel
    color: "white"
    font.pixelSize: 18
    rotation: -90
    transformOrigin: Item.TopLeft
    y: width + upperArrow.height
    x: (timelinePane.spacing - height) / 2
  }

  Rectangle {
    id: lowerArrow
    anchors.top: itemName.top
    width: timelinePane.spacing; height: timelinePane.spacing
    color: parent.color
    visible: enableArrows
    Arrow {
      directionUp: false
      onClicked: selector.nextItem()
      active: !maxReached
    }
  }
}
