import QtQuick 2.0
import "sesssave.js" as StateSave

Item {
  property bool enabled: session.active
  property bool continuous: false
  property bool repeat: true
  property real sampleRate: session.devices.length ? session.devices[0].DefaultRate : 0
  property real maxOutSignalFreq: sampleRate / 5 // A period of a signal should contain at least 5 samples
  property real sampleTime: 0.1
  readonly property int sampleCount: sampleTime * sampleRate + delaySampleCount
  property bool restartAfterStop: false
  property int delaySampleCount: 0

  property bool dlySmplCntChanged: false

//  function trigger() {
//    session.sampleRate = sampleRate
//    session.sampleCount = sampleCount

//      if (dlySmplCntChanged) {
//          for (var i = 0; i < session.devices.length; i++) {
//            for (var j = 0; j < session.devices[i].channels.length; j++) {
//              session.devices[i].channels[j].signals[0].buffer.setIgnoredFirstSamplesCount(delaySampleCount);
//              session.devices[i].channels[j].signals[1].buffer.setIgnoredFirstSamplesCount(delaySampleCount);
//            }
//          }
//          dlySmplCntChanged = false;
//      }

//    session.start(continuous);
//    if ( session.devices.length > 0 ) {
//      lastConfig = StateSave.saveState();
//    }
//  }

//  onSampleTimeChanged: {
//    if (continuous && enabled) {
//      enabled = false;
//      restartAfterStop = true;
//      session.cancel();
//      enabled = true;
//    }
//  }

//  Timer {
//    id: timer
//    interval: 100
//    onTriggered: { trigger() }
//  }

//  function toggle() {
//    if (!enabled) {
//      trigger();
//      enabled = true;
//    } else {
//      enabled = false;
//      if (continuous || sampleTime > 0.1) {
//        session.cancel();
//      }
//    }
//  }

  function toggle() {
      if (!session.active) {
          session.sampleRate = sampleRate
          session.sampleCount = sampleCount
          session.start(continuous);
      } else {
          session.cancel();
      }
  }
  onSampleCountChanged: {
        console.log("onSampleCountChanged");
        console.log(sampleCount);
        session.sampleCount = sampleCount;
  }

//  Timer {
//    id: updateMeasurementsTimer
//    interval: 50
//    repeat: true
//    running: enabled && continuous
//    onTriggered: session.updateMeasurements()
//  }

//  Timer {
//    id: updateLabelsTimer
//    interval: 500
//    repeat: true
//    running: enabled
//    onTriggered: session.updateAllMeasurements()
//  }

  onContinuousChanged: {
    // Restart the session so the new sampling mode takes effect
    //restartAfterStop = true;
    //session.cancel();
    console.log("onContinuousChanged",continuous);
    //console.log("session cont",session.
    //session.restart();
    if(session.active){
        session.cancel();
        session.start(continuous);
        toolbar.acqusitionDialog.onContinuousModeChanged(continuous);
    }
  }

//  onDelaySampleCountChanged: {
//      dlySmplCntChanged = true;
//  }

//  Connections {
//    target: session

//    onFinished: {
//      if (enabled && restartAfterStop) {
//        restartAfterStop = false;
//        timer.start()
//        return;
//      }

//      if (!continuous && repeat && enabled) {
//        timer.start();
//      }
//    }

//    onDetached: {
//      enabled = false;
//      continuous = false;
//    }
//  }

  Repeater {
    model: session.devices
    Item {
      Repeater {
        model: modelData.channels
        Item {
          Connections {
            target: modelData
            onModeChanged: {
                session.restart();
            }
          }
        }
      }
    }
  }
}
