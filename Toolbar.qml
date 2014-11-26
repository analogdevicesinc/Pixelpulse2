import QtQuick 2.1
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.1

ToolbarStyle {
  ExclusiveGroup {
    id: timeGroup
  }

  ExclusiveGroup {
    id: rateGroup
  }

  property alias plotsVisible: plotsVisibleItem.checked
  property alias contentVisible: contentVisibleItem.checked

  Button {
    tooltip: "Menu"
    Layout.fillHeight: true
    style: btnStyle

    menu: Menu {
      Menu {
        title: "Sample Rate"
        MenuItem { exclusiveGroup: rateGroup; checkable: true;
          onTriggered: controller.sampleRate = 1000; text: '1 kHz' }
        MenuItem { exclusiveGroup: rateGroup; checkable: true;
          onTriggered: controller.sampleRate = 4000; text: '4 kHz' }
        MenuItem { exclusiveGroup: rateGroup; checkable: true;
          onTriggered: controller.sampleRate = 10000; text: '10 kHz' }
        MenuItem { exclusiveGroup: rateGroup; checkable: true;
          onTriggered: controller.sampleRate = 40000; text: '40 kHz' }
        MenuItem { exclusiveGroup: rateGroup; checkable: true;
          onTriggered: controller.sampleRate = 100000; text: '100 kHz' }
      }
      Menu {
        title: "Sample Time"
        MenuItem { exclusiveGroup: timeGroup; checkable: true;
          onTriggered: controller.sampleTime = 0.01; text: '10 ms' }
        MenuItem { exclusiveGroup: timeGroup; checkable: true;
          onTriggered: controller.sampleTime = 0.1; text: '100 ms' }
        MenuItem { exclusiveGroup: timeGroup; checkable: true;
          onTriggered: controller.sampleTime = 1; text: '1 s' }
        MenuItem { exclusiveGroup: timeGroup; checkable: true;
          onTriggered: controller.sampleTime = 10; text: '10 s' }
      }

      MenuItem {
        id: plotsVisibleItem
        text: "Plots"
        checkable: true
      }

      MenuItem {
        id: contentVisibleItem
        text: "Documentation"
        checkable: true
      }

      MenuSeparator{}
      MenuItem { text: "About" }
      MenuItem { text: "Exit"; onTriggered: Qt.quit() }
    }
    iconSource: './icons/gear.png'
  }

  Button {
    tooltip: "Start"
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignRight
    style: btnStyle
    iconSource: controller.enabled ? './icons/pause.png' : './icons/play.png'

    onClicked: {
      controller.toggle()
    }
  }
}
