import QtQuick 2.0

Canvas {
  property int arrowWidth: 24
  property int arrowHeight: 18
  property color strokeStyle: "white"
  property color fillStyle: "white"
  property int lineWidth: 2
  property bool fill: true
  property bool stroke: true
  property real alpha: 1.0
  property bool directionUp
  property bool active: true

  id: arrow
  anchors.horizontalCenter: parent.horizontalCenter
  anchors.verticalCenter: parent.verticalCenter
  width: arrowWidth
  height: arrowHeight
  antialiasing: true

  states: [
    State {
      name: "pressed"; when: mArea.pressed && arrow.active
      PropertyChanges {
        target: arrow; fill: false;
      }
    }
  ]

  onFillChanged:requestPaint();
  onStrokeChanged:requestPaint();
  onActiveChanged: requestPaint();

  signal clicked()

  onPaint: {
    var ctx = getContext("2d");
    ctx.save();
    ctx.clearRect(0,0,arrow.width, arrow.height);
    ctx.strokeStyle = arrow.strokeStyle;
    ctx.lineWidth = arrow.lineWidth
    ctx.fillStyle = arrow.fillStyle
    ctx.globalAlpha = arrow.alpha
    ctx.lineJoin = "round";
    ctx.beginPath();
    ctx.translate( (width/2 - arrowWidth/2), (height/2 - arrowHeight/2))
    var x0, y0, x1, y1;
    if (directionUp) {
      x0 = arrowWidth/2;
      y0 = 0;
      x1 = 0;
      y1 = arrowHeight;
    } else {
      x0 = arrowWidth/2;
      y0 = arrowHeight;
      x1 = 0;
      y1 = 0;
    }

    ctx.moveTo(x0, y0);
    ctx.lineTo(x1, y1);
    ctx.lineTo(x1 + arrowWidth, y1);
    ctx.closePath();
    if (arrow.fill && arrow.active)
      ctx.fill();
    if (arrow.stroke)
      ctx.stroke();
    ctx.restore();
  }
  MouseArea{
    id: mArea
    anchors.fill: parent
    onClicked: parent.clicked()
  }
}
