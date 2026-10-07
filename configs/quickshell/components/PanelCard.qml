import QtQuick
import "../theme"
Rectangle {
    id: card
    // All content retains its original geometry inside a full-size reveal layer.
    default property alias contentData: body.data
    property real initialization: 1
    readonly property real fillPhase: Math.max(0, Math.min(1, (initialization-.12)/.24))
    readonly property real contentPhase: Math.max(0, Math.min(1, (initialization-.3)/.35))
    color: Qt.alpha(Theme.surface, Theme.opacityGlass * fillPhase)
    gradient: Gradient {
        GradientStop { position: 0; color: Qt.alpha(Theme.surfaceRaised, Theme.opacityGlass*card.fillPhase) }
        GradientStop { position: .18; color: Qt.alpha(Theme.backgroundRaised, Theme.opacityGlass*card.fillPhase) }
        GradientStop { position: .72; color: Qt.alpha(Theme.surface, Theme.opacityGlass*card.fillPhase) }
        GradientStop { position: 1; color: Qt.alpha(Theme.surfaceRaised, Theme.opacityGlass*card.fillPhase) }
    }
    radius: Theme.cornerRadius
    border { width: Theme.borderWidth; color: Qt.alpha(Theme.border, Theme.opacityBorder * Math.min(1, initialization*4)) }
    children: [
        Item {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: card.height * Math.min(1, card.initialization*1.4)
            clip: card.initialization < 1
            Item { id: body; width: parent.width; height: card.height; opacity: card.contentPhase }
        },
        HudBootFrame { anchors.fill: parent; progress: card.initialization; z: 10 }
    ]
}
