import QtQuick 2.1
import QtQuick.Window 2.0
import Plot 1.0
import QtGraphicalEffects 1.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0

Window {
	
    width: 640
    height: 640

    ColumnLayout {
        anchors.fill: parent
    Item {
    	id: b

        Layout.fillWidth: true
        Layout.fillHeight: true

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

            pointSize: sizeSlider.value

            xmin: 0
            xmax: 1
            ymin: -1
            ymax: 1
        }
	}

     Slider {
        id: sizeSlider

        Layout.fillWidth: true

        maximumValue: 10
        minimumValue: 0
        value: 1.8
    }

}

    /*FastBlur {
        anchors.fill: b
        source: b
        radius: 16
    }*/
}