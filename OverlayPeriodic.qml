import QtQuick 2.1

MouseArea {
  id: plotArea
  anchors.fill: parent

  property real sampleTick: 1/controller.sampleRate
  property real period: signal.src.period * sampleTick
  property real phase: (signal.src.phase % signal.src.period) * sampleTick

  function phaseZeroNearCenter() {
    if (pressed &&  relX != null) return relX
    var center = (xaxis.visibleMin + xaxis.visibleMax) / 2;
    var offset = Math.round((center + phase) / period);
    return offset * period - phase;
  }

  property var dragging: null
  property var relX: 0

  function near(s,t,r) {
    return (s.x > t.x - r
         && s.x < t.x + r
         && s.y > t.y - r
         && s.y < t.y + r);
  }

  onPressed: {
    if (near(mouse, d1, 10)) {
      dragging = 'd1'
    } else if (near(mouse, d2, 10)) {
      dragging = 'd2'
    } else if (near(mouse, d3, 10)) {
      dragging = 'd3'
    } else {
      mouse.accepted = false
      return;
    }
    relX = null
    relX = phaseZeroNearCenter()
  }

  onPositionChanged: {
    var y = Math.min(Math.max(axes.pxToY(mouse.y), signal.min), signal.max)
    if (dragging == 'd1') {
      var oldPeriod = signal.src.period;
      var newPeriod = (xaxis.pxToX(mouse.x) - relX) / sampleTick * 2
      signal.src.period = (xaxis.pxToX(mouse.x) - relX) / sampleTick * ( (signal.src.src == 'square' || signal.src.src == 'sawtooth') ? 1: 2)
      signal.src.phase = -relX/sampleTick
      signal.src.v1 = y;
    } else if (dragging == 'd2') {
      relX = xaxis.pxToX(mouse.x)
      signal.src.phase = -relX/sampleTick
      signal.src.v2 = y;
    } else if (dragging == 'd3') {
      var duty = (xaxis.pxToX(mouse.x) - relX) / period
	  signal.src.duty = duty;
      signal.src.v2 = y;
  }
  }

  DragDot {
    id: d1
    value: signal.src.v1
    filled: signal.isOutput
    color: "blue"

    x: xaxis.xToPx(phaseZeroNearCenter() +( (signal.src.src == 'square' || signal.src.src == 'sawtooth') ? period : period/2))
    y: axes.yToPxClamped(value)
  }

  DragDot {
    id: d2
    value: signal.src.v2
    filled: signal.isOutput
    color: "blue"

    x: xaxis.xToPx(phaseZeroNearCenter())
    y: axes.yToPxClamped(value)
  }

  DragDot {
    id: d3
    value: signal.src.v2
    filled: signal.isOutput
    color: "blue"
	visible: signal.src.src == 'square'
    x: xaxis.xToPx(phaseZeroNearCenter() + signal.src.duty*period)
    y: axes.yToPxClamped(value)
  }

}
