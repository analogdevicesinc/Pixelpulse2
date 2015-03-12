import QtQuick 2.0

Item {
  property bool enabled: false
  property bool continuous: false
  property bool repeat: true
  property real sampleRate: 100000
  property real sampleTime: 0.1
  readonly property int sampleCount: sampleTime * sampleRate

  function trigger() {
    session.sampleRate = sampleRate
    session.sampleCount = sampleCount
    session.start(continuous);
  }

  Timer {
    id: timer
    interval: 100
    onTriggered: { trigger() }
  }
  
  Timer {
    id: timer_callhome
    interval: 100
    running: true
    repeat: false
    onTriggered: { phonehome.callHome(); }
  }

  function toggle() {
    if (!enabled) {
      trigger();
      enabled = true;
    } else {
      enabled = false;
      if (continuous || sampleTime > 0.1) {
        session.cancel();
      }
    }
  }

  Connections {
    target: session
    onFinished: {
      if (!continuous) {
        if (repeat) {
            if (enabled) {
                timer.start();
            } else {
                enabled = false;
            }
        }
      }
    }
  }
}
