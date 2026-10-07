import QtQuick
import "../theme"

Rectangle {
    id: root
    signal closeRequested()
    signal settingsRequested()
    property real openProgress: 1
    property real bootProgress: 1
    function modulePhase(offset: real): real { return Math.max(0, Math.min(1, (bootProgress-offset)/(1-offset))); }
    readonly property real usableHeight: Math.max(1, height - 62)
    readonly property real performanceHeight: Math.min(288, Math.max(1, usableHeight-note.height-launcher.height-40))
    function unfoldNow(): void { openProgress = 0; bootProgress = 0; unfold.restart(); boot.restart(); forceActiveFocus(); }
    color: Theme.glass
    gradient: Gradient {
        GradientStop { position: 0; color: Qt.alpha(Theme.backgroundRaised, Theme.opacityPanel) }
        GradientStop { position: .55; color: Qt.alpha(Theme.background, Theme.opacityPanel) }
        GradientStop { position: 1; color: Qt.alpha(Theme.surface, Theme.opacityPanel) }
    }
    radius: Theme.cornerRadius
    border { width: Theme.borderWidth; color: Qt.alpha(Theme.primary, Theme.opacityBorder) }
    opacity: openProgress
    transform: Translate { x: 8 * (1 - root.openProgress) }
    NumberAnimation { id: unfold; target: root; property: "openProgress"; from: 0; to: 1; duration: Theme.animationFast; easing.type: Easing.OutQuart }
    NumberAnimation { id: boot; target: root; property: "bootProgress"; from: 0; to: 1; duration: Theme.animationDropdown; easing.type: Easing.Linear }
    HudBootFrame { anchors.fill: parent; progress: root.bootProgress; poweredRail: true; z: 20 }
    Keys.onEscapePressed: root.closeRequested()
    Text { x: 14; y: 12; text: "SUSNIX / CONTROL CENTER"; color: Theme.textMuted; font { family: Theme.fontFamily; pixelSize: 10; letterSpacing: .7 } }
    PanelButton { objectName: "closeControlCenter"; anchors { right: parent.right; rightMargin: 8 } y: 6; width: 28; text: "×"; onClicked: root.closeRequested() }
    Column {
        x: 8; y: 36; width: parent.width - 16; spacing: 6
        AiPlaceholder { initialization: root.modulePhase(0); id: ai; objectName:"aiPlaceholder"; width: parent.width; height: Math.max(40, root.usableHeight-note.height-launcher.height-root.performanceHeight); compact: true }
        ScratchNote { initialization: root.modulePhase(.07); id: note; objectName:"scratchNote"; width: parent.width; height: root.height < 570 ? 40 : Math.min(72, Math.max(46, root.usableHeight * .10)) }
        PerformancePanel {
            initialization: root.modulePhase(.14)
            objectName:"performancePanel"
            width: parent.width
            height: root.performanceHeight
            fitMode: true
        }
        QuickLauncher {
            id: launcher
            initialization: root.modulePhase(.21)
            objectName:"quickLauncher"
            width: parent.width
            height: 62
            compact: true
            onLaunched: root.closeRequested()
            onSettingsRequested: root.settingsRequested()
        }
    }
}
