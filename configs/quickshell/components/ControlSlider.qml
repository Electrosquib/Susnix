import QtQuick
import QtQuick.Controls
import "../theme"

Slider {
    id: root
    property color tint: Theme.primary
    from: 0; to: 100; stepSize: 1
    implicitHeight: 28
    opacity: enabled ? 1 : Theme.opacityDisabled
    background: Rectangle {
        x: root.leftPadding; y: (root.height-height)/2
        width: root.availableWidth; height: 5; radius: height/2
        color: Theme.surfaceRaised
        border { width: Theme.borderWidth; color: Qt.alpha(root.tint,Theme.opacityBorder) }
        Rectangle { width: root.visualPosition*parent.width; height: parent.height; radius: parent.radius; color: root.tint }
    }
    handle: Rectangle {
        x: root.leftPadding+root.visualPosition*(root.availableWidth-width)
        y: (root.height-height)/2
        width: 13; height: 13; radius: 4
        color: root.pressed ? root.tint : Theme.text
        border { width: Theme.borderWidth; color: root.tint }
    }
}
