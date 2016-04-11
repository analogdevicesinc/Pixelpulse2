import QtQuick 2.1
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
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

    property alias repeatedSweep: toolbar.repeatedSweep
    property alias plotsVisible: toolbar.plotsVisible
    property alias contentVisible: toolbar.contentVisible
    property alias deviceMngrVisible: toolbar.deviceMngrVisible
    property var lastConfig: {}

    Controller {
        id: controller
        continuous: !repeatedSweep
    }

    Rectangle {
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
                    color: '#111'

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
