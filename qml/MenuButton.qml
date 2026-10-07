import QtQuick 2.2
import QtQuick.Controls 1.2

Button {
    id: button
    property Menu popupMenu: null

    // Controls 1's Button.menu opens on press. On macOS the native menu can
    // consume the release, leaving the original button as the mouse grabber.
    // Keep the inherited menu unset and open from the release-triggered click.
    onClicked: {
        if (popupMenu) {
            // Use the same Controls 1 positioning as Button.menu, so keyboard
            // activation and right-to-left layouts still anchor to the button.
            popupMenu.__visualItem = button
            popupMenu.__minimumWidth = button.width
            popupMenu.__popup(Qt.rect(Qt.application.layoutDirection === Qt.RightToLeft ? button.width : 0,
                                     button.height, 0, 0), 0)
        }
    }

    // Retain the pressed appearance while the dropdown is visible.
    __effectivePressed: __behavior.effectivePressed || (popupMenu && popupMenu.__popupVisible)
}
