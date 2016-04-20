import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.1
import QtQuick.Dialogs 1.0
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0

Dialog {
    title: "Color control panel"
    width: 300
    height: 300
    modality: Qt.NonModal
    contentItem:
        RowLayout {
        id: layout

        Rectangle{
            id: rectangle
            color: '#333'
            anchors.fill: parent
            Layout.preferredWidth: 300
            Layout.preferredHeight: 300
            Layout.maximumHeight: 300
            Layout.maximumWidth: Layout.preferredWidth
            Layout.minimumHeight: Layout.maximumHeight
            Layout.minimumWidth: Layout.maximumWidth
            property var lastModified;
            property color intermPlotColor: '#0c0c0c';
            property color intermPlotAxes: '#222';
            property color intermSignalColor: '#0c0c0c';
            property color intermSignalAxes: '#222';


            CheckBox {
                id: signalCheckBox
                checked: true;
                focus: true
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.topMargin: 50
                anchors.leftMargin:15/100 * parent.width
                style: CheckBoxStyle {
                    label: Text {
                        color: "white"
                        text: 'Signal Row'
                        font.pixelSize: 14
                    }
                }
                onClicked: sliderContrast.valueHasChanged(signalCheckBox)
            }
            CheckBox {
                id: plotsCheckBox
                checked: toolbar.plotsVisible ? true : false;
                focus: true
                anchors.top: parent.top
                anchors.left: signalCheckBox.right
                anchors.topMargin: 50
                anchors.leftMargin: 30
                y: 0
                x: 150
                style: CheckBoxStyle {
                    label: Text {
                        color: "white"
                        text: 'XYPlot'
                        font.pixelSize: 14
                    }
                }
                onClicked: { sliderContrast.valueHasChanged(plotsCheckBox) }
            }

            Text{
                id: brightLabel
                visible: true
                text: 'Brightness'
                font.pixelSize: 14
                color: 'white'
                anchors.top: plotsCheckBox.bottom
                anchors.left: signalCheckBox.left
                anchors.topMargin: 50
            }
            Slider {
                id: sliderBrightness
                focus: true
                anchors.top: brightLabel.bottom
                anchors.topMargin: 20
                anchors.left: signalCheckBox.left
                value: 0.0
                minimumValue: 0.0
                maximumValue: 1.0
                stepSize: 0.01
                width: 70/100 * parent.width
                activeFocusOnPress: true
                activeFocusOnTab: true
                updateValueWhileDragging: true
                property real factor;
                property real oldValue: 0.0

                function valueHasChanged(obj){
                    factor = (sliderBrightness.value)
                    if (plotsCheckBox.checked && (obj !== signalCheckBox)) {
                        var rPlot = parent.intermPlotColor.r + (100 * factor) / 255
                        var rAxes = parent.intermPlotAxes.r + (100 * factor) / 255
                        window.xyplotColor = Qt.rgba(rPlot, rPlot,  rPlot, 1.0)
                        window.gridAxesColor = Qt.rgba(rAxes, rAxes, rAxes, 1.0)
                    }

                    if (signalCheckBox.checked && (obj !== plotsCheckBox)){
                        rPlot = parent.intermSignalColor.r + (100 * factor) / 255
                        rAxes = parent.intermSignalAxes .r + (100 * factor) / 255
                        window.signalRowColor = Qt.rgba(rPlot, rPlot,  rPlot, 1.0)
                        window.signalAxesColor = Qt.rgba(rAxes, rAxes, rAxes, 1.0)
                    }
                    if(signalCheckBox.checked && plotsCheckBox.checked){
                        oldValue = value
                    }
                }
                style: StyleSlider { }
                onValueChanged: valueHasChanged(sliderBrightness)

            }

            Text{
                id: contrastLabel
                visible: true
                text: 'Contrast'
                font.pixelSize: 14
                color: 'white'
                anchors.top: sliderBrightness.bottom
                anchors.left: signalCheckBox.left
                anchors.topMargin: 50
            }
            Slider {
                id: sliderContrast
                anchors.top: contrastLabel.bottom
                anchors.topMargin: 20
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 50
                anchors.left: signalCheckBox.left
                value: 0.0
                minimumValue: 0.0
                focus: true
                maximumValue: 1.0
                stepSize: 0.01
                width: 70/100 * parent.width
                activeFocusOnTab: true
                activeFocusOnPress: true
                updateValueWhileDragging: true
                property real factor;
                property real oldValue: 0.0;
                property color plotC: '#0c0c0c'
                property color gridC: '#222'

                function valueHasChanged(obj){
                    factor = (sliderContrast.value)
                    var rPlot = plotC.r - (100 * factor) / 255
                    var rAxes = gridC.r + (100 * factor) / 255

                    if (plotsCheckBox.checked && (obj !== signalCheckBox)) {
                        parent.intermPlotAxes = Qt.rgba(rAxes, rAxes, rAxes, 1.0)
                        parent.intermPlotColor = Qt.rgba(rPlot, rPlot,  rPlot, 1.0)
                        if (factor === 1.0) {parent.intermPlotAxes = '#fdfdfd'}
                    }
                    if (signalCheckBox.checked && (obj !== plotsCheckBox)){
                        parent.intermSignalAxes = Qt.rgba(rAxes, rAxes, rAxes, 1.0)
                        parent.intermSignalColor = Qt.rgba(rPlot, rPlot,  rPlot, 1.0)
                        if (factor === 1.0) {parent.intermSignalAxes = '#fdfdfd' }
                    }
                    if(signalCheckBox.checked && plotsCheckBox.checked){
                        oldValue = value
                    }
                    /* Check for value updates in brightness slider */
                    sliderBrightness.valueHasChanged(sliderContrast)
                }
                style: StyleSlider { }
                onValueChanged: sliderContrast.valueHasChanged(sliderContrast)
            }
        }
    }
    onAccepted: {close()}


}
