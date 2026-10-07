import QtQuick
import "../theme"
Item {
    id: root
    implicitWidth: 7
    implicitHeight: 16
    property real ignition: 0
    Rectangle {
        anchors.centerIn: parent
        width: Theme.borderWidth; height: 12
        color: Qt.alpha(Theme.primary, Theme.opacityGlow + root.ignition * Theme.opacityBorder)
    }
    HoverHandler { onHoveredChanged: if (hovered) spark.restart() }
    NumberAnimation { id: spark; target: root; property: "ignition"; from: 1; to: 0; duration: Theme.animationFast; easing.type: Easing.OutCubic }
}
