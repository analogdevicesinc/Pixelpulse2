import QtQuick 2.0

Item {
  property bool enabled: false
  property string mode: "repeat"
  property real sampleRate: 100000
  property real sampleTime: 0.1
  readonly property int sampleCount: sampleTime * sampleRate

  function trigger() {
    session.sampleRate = sampleRate
    session.sampleCount = sampleCount
    session.start();
  }

  Timer {
    id: timer
    interval: 10
    onTriggered: { trigger() }
  }

  function toggle() {
    if (!enabled) {
      trigger();
      enabled = true;
    } else {
      enabled = false;
    }
  }

  Connections {
    target: session
    onFinished: {
      if (mode == "one") {
        enabled = false;
      } else if (mode == "repeat") {
        if (enabled) {
          timer.start();
        }
      }
    }
  }
}
