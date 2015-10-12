import QtQuick 2.1
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import "axesutils.js" as AxesUtils

Item {
  id: axes

  property real xmin: 0
  property real xmax: 1

  property real ymin: 0
  property real ymax: 1

  property int xgridticks: width  / 12
  property int ygridticks: height / 12

  property var gridColor: '#fff'

  property int zHorizontalGrid: 0
  property int zVerticalGrid: 0

  property real xstep: AxesUtils.step(xmin, xmax, xgridticks)
  property real xstart: Math.ceil(xmin / xstep)

  property real ystep: AxesUtils.step(ymin, ymax, ygridticks)
  property real ystart: Math.ceil(ymin / ystep)

  property real yscale: height / (ymax - ymin)
  function yToPx(y) { return height - (y - ymin) * yscale }
  function yToPxClamped(y) { return Math.min(Math.max(yToPx(y), 0), height) }
  function pxToY(px) { return (height - px) / yscale + ymin }
  function pxToX(px) { return px / xscale + xmin }
  function snapx(x) { return Math.round(x / (timeline_header.step/(1/controller.sampleRate))) * (timeline_header.step/(1/controller.sampleRate)) }
  function snapy(y) { return Math.round(y / ystep)*ystep }
  property real xscale: width / (xmax - xmin)
  function xToPx(x) { return (x - xmin) * xscale }

  Repeater {
    model: ygridticks

    Rectangle {
      property real yval: (ystart + index) * ystep
      visible: yval <= ymax
      x: 0
      y: yToPx(yval)
      z: zHorizontalGrid
      width: axes.width
      height: 1
      color: gridColor
    }
  }

  Repeater {
    model: xgridticks

    Rectangle {
      property real xval: (xstart + index) * xstep
      visible: xval <= xmax
      x: xToPx(xval)
      y: 0
      z: zVerticalGrid
      width: 1
      height: axes.height
      color: gridColor
    }
  }
}
