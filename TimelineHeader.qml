import QtQuick 2.1

Rectangle {
  id: timeline
	anchors.top: parent.top
	height: 56
	color: "#424242"
	clip: true
	
	gradient: Gradient {
		GradientStop { position: 0.0; color: '#404040' }
		GradientStop { position: 0.15; color: '#5a5a5a' }
		GradientStop { position: 0.5; color: '#444444' }
		GradientStop { position: 1.0; color: '#424242' }
	}
	
  /*
	Item {
		x: xaxis.xToPx(0)
		y: 0
		height: parent.height
		
		Rectangle {
			width: 1
			height: parent.height
			
			gradient: Gradient {
				GradientStop {position: 0.3; color: '#00eeeeee'}
				GradientStop {position: 0.5; color: '#aaeeeeee'}
				GradientStop {position: 1.0; color: '#ffeeeeee'}
			}
		}
    
		
		Text {
			text: '0'
			color: 'white'
			y: 16
			anchors.left: parent.left
			anchors.leftMargin: 4
		}
	}*/
  
  property real pow: Math.floor(Math.log(7000 / xaxis.xscale) / Math.LN10)
  property real majorStep: Math.pow(10, pow)
	property real step: majorStep / 10
	property real start: Math.ceil(xaxis.visibleMin / step)
  
  property real unitScale: Math.pow(10, (pow - 2) % 3 + 1)
  property string unit: unitFor(pow)
  
  function unitFor(pow) {
    switch (Math.floor(pow / 3) * 3) {
      case 0: return ' s'
      case -3: return ' ms'
      case -6: return ' us'
      case -9: return ' ns'
      case -12: return ' ps'
    }
  }

	Repeater {
		model: (xaxis.visibleMax - xaxis.visibleMin) / step
    Rectangle {
        property real n: start + index
        property real xval: n * step
        property real rel: ((n % 10 + 10) % 10)
        property bool isMajor: rel == 0
        property real relVal: rel * unitScale
        
        x: xaxis.xToPx(xval)
        y: timeline.height-height
        width: 1
        height: isMajor ? 40 : 12
        
        Text {
          text: isMajor ? (xval + ' s') : ('+' + relVal.toPrecision(2) + unit)
          color: 'white'
          anchors.left: parent.left
          anchors.leftMargin: isMajor ? 6 : -4
          anchors.bottom: isMajor ? undefined : parent.top
          anchors.top: isMajor ? parent.top : undefined
        }
    }
	}
}
