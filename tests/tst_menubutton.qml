import QtQuick 2.2
import QtQuick.Controls 1.2
import QtTest 1.2
import "../qml" as Pixelpulse

Item {
    width: 400
    height: 200
    property int firstOpened: 0
    property int secondOpened: 0
    property int otherClicked: 0

    Pixelpulse.MenuButton {
        id: first
        x: 10; y: 10; width: 100; height: 40
        text: "First"
        popupMenu: Menu {
            id: firstMenu
            MenuItem { text: "Channel mode" }
            onAboutToShow: { firstOpened++; closeFirst.start() }
        }
    }
    Pixelpulse.MenuButton {
        id: second
        x: 150; y: 10; width: 100; height: 40
        text: "Second"
        popupMenu: Menu {
            id: secondMenu
            MenuItem { text: "Waveform" }
            onAboutToShow: { secondOpened++; closeSecond.start() }
        }
    }
    Button {
        id: other
        x: 10; y: 100; width: 100; height: 40
        text: "Other action"
        onClicked: otherClicked++
    }
    Timer { id: closeFirst; interval: 100; onTriggered: firstMenu.__dismissMenu() }
    Timer { id: closeSecond; interval: 100; onTriggered: secondMenu.__dismissMenu() }

    TestCase {
        name: "MenuButton"
        when: windowShown

        function test_releaseBeforePopup() {
            mousePress(first, 50, 20)
            wait(50)
            compare(firstOpened, 0, "A press alone must not open the native menu")
            mouseRelease(first, 50, 20)
            tryCompare(parent, "firstOpened", 1)
            tryCompare(firstMenu, "__popupVisible", false)

            mouseClick(second, 50, 20)
            tryCompare(parent, "secondOpened", 1)
            tryCompare(secondMenu, "__popupVisible", false)
            compare(firstOpened, 1, "Clicking the second button must not reopen the first menu")

            mouseClick(other, 50, 20)
            compare(otherClicked, 1)
            compare(firstOpened, 1)
            compare(secondOpened, 1)

            mouseClick(first, 50, 20)
            tryCompare(parent, "firstOpened", 2)
            tryCompare(firstMenu, "__popupVisible", false)

            first.forceActiveFocus()
            keyClick(Qt.Key_Space)
            tryCompare(parent, "firstOpened", 3)
            tryCompare(firstMenu, "__popupVisible", false)

            mousePress(first, 50, 20)
            mouseMove(first, 120, 70)
            mouseRelease(first, 120, 70)
            wait(50)
            compare(firstOpened, 3, "Dragging off the button must cancel the click")
        }
    }
}
