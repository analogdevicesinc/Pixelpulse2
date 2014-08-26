import QtQuick 2.1
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0

ApplicationWindow {
	width: 1024
	height: 768
	title: "signalspec"

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

					spacing: 2

					Rectangle {
						id: toolbar
						width: 320
						height: 56

						radius: 2

						gradient: Gradient {
							GradientStop { position: 0.0; color: '#565666' }
							GradientStop { position: 0.15; color: '#6a6a7d' }
							GradientStop { position: 0.5; color: '#5a5a6a' }
							GradientStop { position: 1.0; color: '#585868' }
						}

						ToolButton {
							text: "Config"
						}
						ToolButton {
							text: "Start"
						}
					}

					TimelineHeader {
						id: timeline_header
						Layout.fillWidth: true
					}
				}

				ColumnLayout {
					Layout.fillHeight: true
					Layout.fillWidth: true

					SignalRow {
						xaxis: xaxis
						test: 'triangle'
						Layout.fillHeight: true
						Layout.fillWidth: true
					}

					SignalRow {
						xaxis: xaxis
						test: 'sine'
						Layout.fillHeight: true
						Layout.fillWidth: true
					}
				}
			}

			TimelineFlickable {
				id: xaxis
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
