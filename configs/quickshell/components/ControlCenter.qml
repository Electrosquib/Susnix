import QtQuick
import "../theme"

Item {
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
    readonly property real performanceHeight: Math.min(288, Math.max(1, usableHeight-note.height-launcher.height-music.height-64))
    property real topJoinOffset: -18
    opacity: openProgress
    transform: Translate { x: root.width * (1 - root.openProgress) }
    HudBootFrame {
        anchors.fill: parent
        fillBackground: true
        topJoinOffset: root.topJoinOffset
        topJoinDepth: Theme.barHeight-Theme.barSideHeight
        z: -1
    }
    Keys.onEscapePressed: root.closeRequested()
    Text { x: 14; y: 12; text: "SUSNIX / CONTROL CENTER"; color: Theme.textMuted; font { family: Theme.fontFamily; pixelSize: 10; letterSpacing: .7 } }
    PanelButton { objectName: "closeControlCenter"; anchors { right: parent.right; rightMargin: 8 } y: 6; width: 28; text: "×"; onClicked: root.closeRequested() }
    Column {
        x: 8; y: 36; width: parent.width - 16; spacing: 6
        AiPlaceholder { id: ai; objectName:"aiPlaceholder"; width: parent.width; height: Math.max(40, root.usableHeight-note.height-launcher.height-root.performanceHeight-music.height-6); compact: true }
        MusicPlayer { id: music; objectName: "musicPlayer"; width: parent.width; height: 96; monitoring: root.opened }
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
