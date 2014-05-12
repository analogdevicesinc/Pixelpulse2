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
                this.buffer.fill_sine(1/533/1000, 533, 1);
                for (var i=0; i<0; i++) {
                    this.buffer.jitter(0.01);
                }
            }

            pointSize: sizeSlider.value

            xmin: timeline_flickable.xwin_min
            xmax: timeline_flickable.xwin_max
            ymin: -1
            ymax: 1
        }

         MouseArea {
            anchors.fill: parent
            anchors.margins: 20

            onWheel: {
                var s = Math.pow(1.15, wheel.angleDelta.y/120)
                timeline_flickable.xscale *= s
                timeline_flickable.contentX = s * (timeline_flickable.contentX + wheel.x) - wheel.x
            }

            Flickable {
                id: timeline_flickable

                flickableDirection: Flickable.HorizontalFlick
                contentWidth: xscale

                property real xscale: 10 * 640
                property real xwin_min: contentX / xscale
                property real xwin_max: (contentX + width) / xscale

                anchors.fill: parent
            }
        }

	}

     Slider {
        id: sizeSlider

        Layout.fillWidth: true

        maximumValue: 100
        minimumValue: 0
        value: 2
    }

    RowLayout {
        Text { text: timeline_flickable.xwin_min }
        Text { text: timeline_flickable.xwin_max }
    }
}

    /*FastBlur {
        anchors.fill: b
        source: b
        radius: 16
    }*/
}