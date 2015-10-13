import QtQuick 2.1
import QtQuick.Window 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import "sesssave.js" as StateSave

ApplicationWindow {
	width: 1024
	height: 768
	title: "Pixelpulse2"
	visible: true
	property var toolbarHeight: 56
	id: window

	property alias repeatedSweep: toolbar.repeatedSweep
	property alias plotsVisible: toolbar.plotsVisible
	property alias contentVisible: toolbar.contentVisible
	property alias lockAxes: toolbar.lockVertAxes
	property var deviceList: frontend.deviceList
	property var channelList: frontend.channelList
	property var voltageList: frontend.voltageList.list
	property var currentList: frontend.currentList.list
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

					RowLayout {
						anchors.fill: parent
						anchors.bottomMargin: 10
						spacing: 0

						DeviceRow {
							id: deviceSelect
							width: timelinePane.spacing
							Layout.fillHeight: true
							color: '#222'
							visible: deviceList.labelCount > 0
							list: deviceList
						}

						ChannelRow {
							id: channelSelect
							width: timelinePane.spacing
							Layout.fillHeight: true
							color: '#333'
							visible: channelList.labelCount > 0
							list: channelList
							channel: channelList.crtChannel
						}

						ColumnLayout {
							width: timelinePane.spacing
							spacing: 0
							visible: channelList.labelCount > 0
							SignalRow {
								id: voltageSignalRow
								Layout.fillHeight: true
								Layout.fillWidth: true

								channel: channelList.crtChannel
								signal: channelList.crtChannel ? channelList.crtChannel.signals[0] : null
								allsignals: voltageList
								xaxis: timeline_xaxis
								signal_type: 0
							}

							SignalRow {
								id: currentSignalRow
								Layout.fillHeight: true
								Layout.fillWidth: true

								channel: channelList.crtChannel
								signal: channelList.crtChannel ? channelList.crtChannel.signals[1] : null
								allsignals: currentList
								xaxis: timeline_xaxis
								signal_type: 1
							}
						}
					}
				}
			}

			TimelineFlickable {
				id: timeline_xaxis
				anchors.fill: parent
				anchors.leftMargin: toolbar.width
				anchors.rightMargin: 28 + voltageSignalRow.vertScalesWidth

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
	}
}
