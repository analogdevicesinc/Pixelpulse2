import QtQuick 2.1
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0

ApplicationWindow {
	width: 1024
	height: 768
	title: "signalspec"
	visible: true

	Rectangle {
		anchors.fill: parent
		color: '#0c0c0c'
	}

	RowLayout {
		anchors.fill: parent

		Item {
			// The entire signal + timeline pane
			id: timelinePane
			Layout.fillHeight: true
			Layout.fillWidth: true

			ColumnLayout {
				anchors.fill: parent
				id: signals_column

				spacing: 2

				RowLayout {
					Layout.fillWidth: true
					Layout.minimumHeight: 56
					Layout.maximumHeight: 56

					spacing: 2

					Toolbar {
						id: toolbar
						width: 320
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
					color: '#666'

					ColumnLayout {
						anchors.fill: parent

						Repeater {
							model: session.devices
							DeviceRow {
								Layout.fillHeight: true
								Layout.fillWidth: true
								device: model
							}
						}
					}
				}
			}

			TimelineFlickable {
				id: timeline_xaxis
				anchors.fill: parent
				anchors.leftMargin: toolbar.width + 2
				anchors.rightMargin: 2

				Component.onCompleted: {
					setBounds(0, 1)
					setVisible(0, 0.5)
				}
			}
		}
	}
}
