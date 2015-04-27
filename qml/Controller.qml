import QtQuick 2.0
import "sesssave.js" as StateSave

Item {
  id: controlItem
  property bool enabled: false
  property bool continuous: false
  property bool repeat: true
  property bool changingMode: false
  // TODO: should be queried from libsmu / device
  // property real sampleRate: 100000 // presently invalid
  property real sampleRate: 125000/2 // current default
  property real sampleTime: 0.1
  readonly property int sampleCount: sampleTime * sampleRate

  function trigger() {
    session.sampleRate = sampleRate
    session.sampleCount = sampleCount
    session.start(continuous);
    if ( session.devices.length > 0 ) {
      lastConfig = StateSave.saveState();
    }
  }

  Timer {
    id: timer
    interval: 100
    onTriggered: { trigger() }
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
      else {
        if (changingMode) {
            trigger();
            changingMode = false;
            console.log("changing mode");
        }
        else {
          enabled = false
        }
      }
    }
    onDetached: {
      enabled = false;
      continuous = false;
    }
  }
}
