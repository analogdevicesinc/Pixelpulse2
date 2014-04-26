import QtQuick 2.1
import QtQuick.Window 2.0
import Plot 1.0
import QtGraphicalEffects 1.0

Window {
	width: 300
    height: 200

    Item {
    	id: b
    	anchors.fill: parent
    	
    Rectangle {
    	anchors.fill: parent
    	color: 'black'
    }

    PhosphorRender {
        id: line
        anchors.fill: parent
        anchors.margins: 20

        SequentialAnimation on p {
            NumberAnimation { to: 1; duration: 60000; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 0; duration: 60000; easing.type: Easing.InOutQuad }
            loops: Animation.Infinite
        }
    }
	}

    FastBlur {
        anchors.fill: b
        source: b
        radius: 16
    }
}