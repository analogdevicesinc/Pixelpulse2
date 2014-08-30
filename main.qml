import QtQuick 2.1
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import SMU 1.0

ApplicationWindow {
	width: 1024
	height: 768
	title: "signalspec"

	Session {
		id: session

		Component.onCompleted: {
			session.openAllDevices()
			console.log(session.devices.length)
			console.log(session.devices[0].channels.length)
			console.log(session.devices[0].channels[0].signals.length)
		}
	}

	Rectangle {
		anchors.fill: parent
		color: '#0c0c0c'
	}

	RowLayout {
		anchors.fill: parent

		Item {
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

				ColumnLayout {
					Layout.fillHeight: true
					Layout.fillWidth: true

					Repeater {
						model: session.devices

						Repeater {
							model: channels

							Repeater {
								model: modelData.signals

								SignalRow {
									xaxis: timeline_xaxis
									test: 'triangle'
									Layout.fillHeight: true
									Layout.fillWidth: true
								}
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
				/*Rectangle {
					anchors.fill: parent
					color: "blue"
					opacity: 0.5
				}*/

				Component.onCompleted: {
					setBounds(0, 1)
					setVisible(0, 0.5)
				}
			}
		}
	}
}
