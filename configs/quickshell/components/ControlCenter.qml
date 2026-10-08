import QtQuick
import "../theme"

Rectangle {
    id: root
    signal closeRequested()
    signal settingsRequested()
    property bool opened: false
    property real openProgress: opened ? 1 : 0
    onOpenedChanged: if (opened) Qt.callLater(forceActiveFocus)
    Behavior on openProgress {
        NumberAnimation { duration: Theme.animationReveal; easing.type: Theme.revealEasing }
    }
    readonly property real usableHeight: Math.max(1, height - 62)
    readonly property real performanceHeight: Math.min(288, Math.max(1, usableHeight-note.height-launcher.height-40))
    color: Theme.glass
    gradient: Gradient {
        GradientStop { position: 0; color: Qt.alpha(Theme.backgroundRaised, Theme.opacityPanel) }
        GradientStop { position: .55; color: Qt.alpha(Theme.background, Theme.opacityPanel) }
        GradientStop { position: 1; color: Qt.alpha(Theme.surface, Theme.opacityPanel) }
    }
    radius: Theme.cornerRadius
    border { width: Theme.borderWidth; color: Qt.alpha(Theme.primary, Theme.opacityBorder) }
    opacity: openProgress
    transform: Translate { x: root.width * (1 - root.openProgress) }
    HudBootFrame { anchors.fill: parent; z: 20 }
    Keys.onEscapePressed: root.closeRequested()
    Text { x: 14; y: 12; text: "SUSNIX / CONTROL CENTER"; color: Theme.textMuted; font { family: Theme.fontFamily; pixelSize: 10; letterSpacing: .7 } }
    PanelButton { objectName: "closeControlCenter"; anchors { right: parent.right; rightMargin: 8 } y: 6; width: 28; text: "×"; onClicked: root.closeRequested() }
    Column {
        x: 8; y: 36; width: parent.width - 16; spacing: 6
        AiPlaceholder { id: ai; objectName:"aiPlaceholder"; width: parent.width; height: Math.max(40, root.usableHeight-note.height-launcher.height-root.performanceHeight); compact: true }
        ScratchNote { id: note; objectName:"scratchNote"; width: parent.width; height: root.height < 570 ? 40 : Math.min(72, Math.max(46, root.usableHeight * .10)) }
        PerformancePanel {
            objectName:"performancePanel"
            width: parent.width
            height: root.performanceHeight
            fitMode: true
        }
        QuickLauncher {
            id: launcher
            objectName:"quickLauncher"
            width: parent.width
            height: 62
            compact: true
            onLaunched: root.closeRequested()
            onSettingsRequested: root.settingsRequested()
        }
    }
}
