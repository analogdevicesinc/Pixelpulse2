import QtQuick 2.1

Item {
  id: overlay
  anchors.fill: parent

  property real sampleTick: 1/controller.sampleRate
  property real period: signal.src.period * sampleTick
  property real phase: (signal.src.phase % signal.src.period) * sampleTick

  function phaseZeroNearCenter() {
    if (dragging && relX != null) return relX
    var center = (xaxis.visibleMin + xaxis.visibleMax) / 2;
    var offset = Math.round((center + phase) / period);
    return offset * period - phase;
  }
  function periodDivisor() {
    return ( (signal.src.src == 'square' || signal.src.src == 'sawtooth' || signal.src.src == 'stairstep') ? 1: 2)
    }

  property var dragging: null
  property var relX: 0

  function dragStart(id) {
    dragging = id
    relX = null
    relX = phaseZeroNearCenter()
  }

  function dragEnd() {
    dragging = null;
  }

  function constrainInterval(value, center, radius){
    if (Math.abs(value) < radius){
      if (value < center){ value = -radius; }
      if (value >= center) { value = radius; }
    }
    return value;
  }

  function mapY(pos) {
    var y = Math.min(Math.max(axes.pxToY(pos.y), signal.min), signal.max);
    if (pos.modifiers & Qt.AltModifier) {
      y = axes.snapy(y);
    }
    return y;
  }

  DragDot {
    id: d1
    value: signal.src.v1
    filled: signal.isOutput
    color: "blue"

    x: constrainValue(xaxis.xToPx(phaseZeroNearCenter() + period/periodDivisor()), xaxis.xToPx(xaxis.visibleMin), xaxis.xToPx(xaxis.visibleMax))
    y: axes.yToPxClamped(value)

    dragOn: overlay
    onPressed: overlay.dragStart('d1')
    onReleased: {
      //50000 -> maximum frequency value
      signal.src.period = constrainInterval(signal.src.period, 0, controller.sampleRate / 50000);
      overlay.dragEnd();
    }
    onDrag: {
      var lx = xaxis.pxToX(Math.max(0, Math.min(pos.x, xaxis.width)));
      var oldPeriod = signal.src.period;
      var newPeriod = (lx - relX) / sampleTick * periodDivisor();
      if (pos.modifiers & Qt.ControlModifier) {
        newPeriod = axes.snapx(newPeriod)
        if ( newPeriod == 0 ) {
          newPeriod = 1
        }
      }
      signal.src.period = newPeriod;
      signal.src.v1 = overlay.mapY(pos);
      // Adjust phase so the signal stays in the same position relative to the other dot
      signal.src.phase = -relX/sampleTick;
    }
  }

  DragDot {
    id: d2
    value: signal.src.v2
    filled: signal.isOutput
    color: "blue"

    x: constrainValue(xaxis.xToPx(phaseZeroNearCenter()), xaxis.xToPx(xaxis.visibleMin), xaxis.xToPx(xaxis.visibleMax))
    y: axes.yToPxClamped(value)

    dragOn: overlay
    onPressed: overlay.dragStart('d2')
    onReleased: overlay.dragEnd()
    onDrag: {
      var lx = xaxis.pxToX(Math.max(0, Math.min(pos.x, xaxis.width)));
      relX = lx;
      if (pos.modifiers & Qt.ControlModifier) {
        signal.src.phase = axes.snapx(-relX/sampleTick)
      } else {
        signal.src.phase = -relX/sampleTick
      }
      signal.src.v2 = overlay.mapY(pos)
    }
  }

  DragDot {
    id: d3
    value: Math.round(100*signal.src.duty)
    filled: signal.isOutput
    color: "blue"
    visible: signal.src.src == 'square'
    x: constrainValue(xaxis.xToPx(phaseZeroNearCenter() + signal.src.duty*period), xaxis.xToPx(xaxis.visibleMin), xaxis.xToPx(xaxis.visibleMax))
    y: axes.yToPxClamped((signal.src.v2 + signal.src.v1)/2)
    z: -1

    dragOn: overlay
    onPressed: overlay.dragStart('d3')
    onReleased: overlay.dragEnd()
    onDrag: {
      var lx = xaxis.pxToX(Math.max(0, Math.min(pos.x, xaxis.width)));
      var duty = (lx - relX) / period
      if (pos.modifiers & Qt.ControlModifier) {
        duty = Math.round(duty*20)/20
      }
      signal.src.duty = Math.min(Math.max(duty, 0), 1);
    }
  }

}
