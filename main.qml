import QtQuick 2.1
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0

ApplicationWindow {
	width: 1024
	height: 768
	title: "signalspec"

	RowLayout {
		anchors.fill: parent

		Item {
			Layout.fillHeight: true
			Layout.fillWidth: true

			ColumnLayout {
				anchors.fill: parent
				id: signals_column

				RowLayout {
					Layout.fillWidth: true

					Rectangle {
						id: toolbar
						width: 320
						height: 48
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

				Rectangle {
					Layout.fillHeight: true
					Layout.fillWidth: true
					color: "red"
				}
			}

			Flickable {
				id: timeline_flickable
				anchors.fill: parent
				anchors.leftMargin: toolbar.width + 4
				anchors.rightMargin: 4
				Rectangle {
					anchors.fill: parent
					color: "blue"
					opacity: 0.5
				}
			}
		}
	}
}
