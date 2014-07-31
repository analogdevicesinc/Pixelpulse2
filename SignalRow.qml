import QtQuick 2.1
import QtQuick.Layouts 1.0
import Plot 1.0

RowLayout {
  Layout.fillHeight: true
  property var xaxis
  property var test
  
  Rectangle {
    width: 320
    Layout.fillHeight: true
    
    color: '#444444'
  }
  
  PhosphorRender {
      Layout.fillHeight: true
      Layout.fillWidth: true
      
      Rectangle {
        color: 'green'
        opacity: 0.1
        anchors.fill: parent
      }
      
      id: line
      anchors.margins: 20

      buffer: FloatBuffer{}

      Component.onCompleted: {
          if (test == 'sine') {
            this.buffer.fillSine(1/533/1000, 533, 1);
          } else {
            this.buffer.fillSawtooth(1/533/1000, 333, 1);
          }
          for (var i=0; i<0; i++) {
              this.buffer.jitter(0.01);
          }
      }

      pointSize: 2

      xmin: xaxis.visibleMin
      xmax: xaxis.visibleMax
      ymin: -1.1
      ymax: 1.1
  }
}
