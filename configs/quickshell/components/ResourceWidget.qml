import QtQuick
import "../theme"

// Shared geometry keeps CPU/GPU cards equal and independent of value length.
Rectangle {
    id: root
    property bool compact: false
    property string label: ""
    property string iconName: ""
    property string value: "—"
    implicitWidth: Math.ceil(metrics.advanceWidth("GPU")) + Math.ceil(metrics.advanceWidth("100%"))
        + Theme.resourceSpacing + 2 * Theme.resourcePadding
        + (compact ? 0 : 16 + Theme.resourceSpacing)
    implicitHeight: 22
    radius: Math.min(2, Theme.cornerRadius)
    color: Qt.alpha(Theme.surfaceRaised, Theme.opacityGlass)
    border { width: Theme.borderWidth; color: Qt.alpha(Theme.system, Theme.opacityBorder) }
    Accessible.name: label + " " + value
    FontMetrics { id: metrics; font { family: Theme.fontFamily; pixelSize: Theme.fontSize } }
    Row {
        anchors.centerIn: parent
        spacing: Theme.resourceSpacing
        Icon {
            visible: !root.compact
            name: root.iconName
            color: Theme.system
            anchors.verticalCenter: parent.verticalCenter
        }
        StatusLabel {
            slotText: "GPU"
            text: root.label
            horizontalAlignment: Text.AlignLeft
            color: Theme.textMuted
            anchors.verticalCenter: parent.verticalCenter
        }
        AnimatedValue {
            slotText: "100%"
            text: root.value
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
