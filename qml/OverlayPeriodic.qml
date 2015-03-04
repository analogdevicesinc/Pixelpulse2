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

    x: xaxis.xToPx(phaseZeroNearCenter() + period/periodDivisor())
    y: axes.yToPxClamped(value)

    dragOn: overlay
    onPressed: overlay.dragStart('d1')
    onReleased: overlay.dragEnd()
    onDrag: {
      var oldPeriod = signal.src.period;
      var newPeriod = (xaxis.pxToX(pos.x) - relX) / sampleTick * periodDivisor();
      if (pos.modifiers & Qt.ControlModifier) {
        newPeriod = axes.snapx(newPeriod)
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

    x: xaxis.xToPx(phaseZeroNearCenter())
    y: axes.yToPxClamped(value)

    dragOn: overlay
    onPressed: overlay.dragStart('d2')
    onReleased: overlay.dragEnd()
    onDrag: {
      relX = xaxis.pxToX(pos.x)
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
    value: signal.src.duty
    filled: signal.isOutput
    color: "blue"
    visible: signal.src.src == 'square'
    x: xaxis.xToPx(phaseZeroNearCenter() + signal.src.duty*period)
    y: axes.yToPxClamped((signal.src.v2 + signal.src.v1)/2)
    z: -1

    dragOn: overlay
    onPressed: overlay.dragStart('d3')
    onReleased: overlay.dragEnd()
    onDrag: {
      var duty = (xaxis.pxToX(pos.x) - relX) / period
      if (pos.modifiers & Qt.ControlModifier) {
        duty = Math.round(duty*20)/20
      }
      signal.src.duty = Math.min(Math.max(duty, 0), 1);
    }
  }

}
