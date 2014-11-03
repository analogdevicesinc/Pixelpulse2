import QtQuick 2.1
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0

ApplicationWindow {
	width: 1024
	height: 768
	title: "Pixelpulse"
	visible: true

	Controller {
		id: controller
	}

	Rectangle {
		anchors.fill: parent
		color: '#000'
	}

	RowLayout {
		anchors.fill: parent

		Item {
			// The entire signal + timeline pane
			id: timelinePane
			Layout.fillHeight: true
			Layout.fillWidth: true

			// spacing between rows
			property real vspacing: 20

			// column width
			property real hspacing: 40

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
						width: timelinePane.hspacing * 3
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
						anchors.topMargin: timelinePane.vspacing / 2
						anchors.bottomMargin: timelinePane.vspacing / 2
						spacing: timelinePane.vspacing

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
				anchors.leftMargin: toolbar.width
				anchors.rightMargin: 48

				boundMin: 0
				boundMax: controller.sampleTime

				Component.onCompleted: {
					this.setVisible(boundMin, boundMax)
				}
			}
		}
	}
}
