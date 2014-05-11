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

            buffer: FloatBuffer{}

            Component.onCompleted: {
                this.buffer.fill_sine(0.0001, 5, 1);
            }

            xmin: 0
            xmax: 1
            ymin: -1
            ymax: 1
        }
	}

    /*FastBlur {
        anchors.fill: b
        source: b
        radius: 16
    }*/
}