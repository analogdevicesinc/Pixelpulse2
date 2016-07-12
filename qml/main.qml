import QtQuick 2.1
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtGraphicalEffects 1.0
import "sesssave.js" as StateSave

ApplicationWindow {
    width: 1024
    height: 768
    minimumHeight: 600
    minimumWidth: 800
    title: "Pixelpulse2"
    visible: true
    property var toolbarHeight: 56
    id: window
    property real  brightness: 3.0

    property alias repeatedSweep: toolbar.repeatedSweep
    property alias plotsVisible: toolbar.plotsVisible
    property alias contentVisible: toolbar.contentVisible
    property alias deviceMngrVisible: toolbar.deviceMngrVisible
    property var lastConfig: {}
/*Color control properties*/
    property color xyplotColor: Qt.rgba(0.12, 0.12, 0.12, 0.0 )
    property color gridAxesColor: '#222'
    //signal row
    property color signalRowColor: '#0c0c0c'
    property color signalAxesColor: '#222'
    //Phosphor render
    property color dotSignalCurrent: Qt.rgba(0.2, 0.2, 0.03, 1);
    property color dotSignalVoltage: Qt.rgba(0.03, 0.3, 0.03, 1);
    property color dotPlotsCurrent: Qt.rgba(0.2, 0.2, 0.03, 1);
    property color dotPlotsVoltage: Qt.rgba(0.03, 0.3, 0.03, 1);
    //Dot size
    property real dotSizeSignal: 0.1;
    property real dotSizePlots: 0.1;

    Controller {
        id: controller
        continuous: !repeatedSweep
    }


    Rectangle {
        id: background
        anchors.fill: parent
        color: '#000'
    }

    SplitView {
        anchors.fill: parent

        Item {
            // The entire signal + timeline pane
            id: timelinePane
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.minimumWidth: 0.4*window.width

            // column width
            property real spacing: 40

            ColumnLayout {
                anchors.fill: parent
                id: signals_column

                spacing: 0

                Rectangle {
                    id: signalBackground
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: timeline_xaxis.width + signalsPane.width
                    color: window.signalRowColor;
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.minimumHeight: toolbarHeight
                    Layout.maximumHeight: toolbarHeight

                    spacing: 0

                    Toolbar {
                        id: toolbar
                        width: timelinePane.spacing * 3
                        Layout.fillHeight: true
                    }

                    TimelineHeader {
                        id: timeline_header
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        xaxis: timeline_xaxis
                    }
                }

                Rectangle {
                    // The signals column to the left of the timeline plots. The plots are
                    // contained within this, but positioned to the right of the width
                    // specified here.
                    id: signalsPane
                    Layout.fillHeight: true
                    width: toolbar.width
                    color: '#000'

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.bottomMargin: 10
                        spacing: 0

                        Repeater {
                            id: deviceRepeater
                            model: session.devices
                            DeviceRow {
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                device: model
                                currentIndex: index
                            }
                            onItemAdded: {
                                if ( lastConfig ) {
                                    if ((Object.keys(lastConfig).length) > 0) {
                                        StateSave.restoreState(lastConfig);
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    id: statusBar
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 30
                    visible: toolbar.acqusitionDialog.showStatusBar

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        Rectangle {
                            id: hiddenBar
                            Layout.fillWidth: true
                            height: 5
                            color: '#000'
                        }
                        Rectangle {
                            id: statusBarRect
                            Layout.fillWidth: true
                            height: 25
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: '#404040' }
                                GradientStop { position: 0.15; color: '#5a5a5a' }
                                GradientStop { position: 0.5; color: '#444444' }
                                GradientStop { position: 1.0; color: '#424242' }
                            }

                            // Left vertical separator
                            Rectangle {
                                id: leftSeparator
                                height: parent.height
                                width: 1
                                color: '#333333'
                                x: signalsPane.width
                            }

                            Text {
                                id: delayText
                                text: "Delay: " + toolbar.acqusitionDialog.timeDelay.toFixed(2) + " ms"
                                color: 'white'
                                anchors.left: leftSeparator.right
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Right vertical separator
                            Rectangle {
                                id: rightSeparator
                                height: parent.height
                                width: 1
                                color: '#333333'
                                x: signalsPane.width + timeline_xaxis.width
                            }
                        }
                    }
                }
            }

            TimelineFlickable {
                id: timeline_xaxis
                anchors.fill: parent
                anchors.leftMargin: toolbar.width
                anchors.rightMargin: 78

                boundMin: 0
                boundMax: controller.sampleTime
            }
        }

        PlotPane {
            id: xyPane
            visible: plotsVisible
            width: 360
            Layout.minimumWidth: 0.2*window.width
            Layout.maximumWidth: 0.4*window.width
        }

        ContentPane {
            id: contentPane
            visible: contentVisible
            width: 360
            Layout.minimumWidth: 0.2*window.width
            Layout.maximumWidth: 0.4*window.width
        }

        DeviceManagerPane {
            id: deviceMngrPane
            visible: deviceMngrVisible
            width: 360
            Layout.minimumWidth: 0.2*window.width
            Layout.maximumWidth: 0.4*window.width
        }
    }
}
