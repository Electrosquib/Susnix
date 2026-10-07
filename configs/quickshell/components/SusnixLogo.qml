import QtQuick
import QtQuick.Controls
import "../theme"

AbstractButton {
    id: root
    signal glitchRequested()
    signal toggleRequested()
    property bool expanded: false
    readonly property alias toggleButton: root
    implicitWidth: 24
    implicitHeight: 24
    hoverEnabled: true
    Accessible.name: expanded ? "Close desktop themes" : "Expand desktop themes"
    onHoveredChanged: if (hovered) cube.triggerShock()
    onClicked: { root.toggleRequested(); root.glitchRequested(); }
    background: Rectangle {
        radius: Theme.cornerRadius
        color: root.hovered || root.expanded ? Qt.alpha(Theme.primary, Theme.opacityHover) : Theme.transparent
    }
    contentItem: Item {
        ThemeCube {
            id: cube
            anchors.fill: parent
            primary: Theme.primary
            secondary: Theme.secondary
            accent: Theme.accent
            multiColor: true
        }
    }
}
