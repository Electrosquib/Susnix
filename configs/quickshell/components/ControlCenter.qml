import QtQuick
import "../theme"
import "../services"

Item {
    id: root
    signal closeRequested()
    signal settingsRequested()
    property bool opened: false
    property real openProgress: opened ? 1 : 0
    onOpenedChanged: {
        if (opened) Qt.callLater(forceActiveFocus); else requestedSession="";
    }
    property string requestedSession: ""
    Behavior on openProgress {
        NumberAnimation { duration: Theme.animationReveal; easing.type: Theme.revealEasing }
    }
    readonly property real usableHeight: Math.max(1, height - 62)
    readonly property real performanceHeight: Math.min(288, Math.max(1, usableHeight-note.height-launcher.height-music.height-controls.height-70))
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
    Keys.onEscapePressed: {
        if (DesktopService.details) DesktopService.details="";
        else if (requestedSession) requestedSession="";
        else root.closeRequested();
    }
    Text { x: 14; y: 12; text: "SUSNIX / CONTROL CENTER"; color: Theme.textMuted; font { family: Theme.fontFamily; pixelSize: 10; letterSpacing: .7 } }
    PanelButton { objectName: "closeControlCenter"; anchors { right: parent.right; rightMargin: 8 } y: 6; width: 28; text: "×"; onClicked: root.closeRequested() }
    Column {
        x: 8; y: 36; width: parent.width - 16; spacing: 6
        enabled: !DesktopService.details && !root.requestedSession
        DesktopControls {
            id:controls; compact:root.height<800;objectName:"desktopControls"; width:parent.width; height:implicitHeight
            onSessionRequested: action => {
                if (action === "lock") DesktopService.session(action);
                else root.requestedSession=action;
            }
        }
        AiPlaceholder { id: ai; objectName:"aiPlaceholder"; width: parent.width; height: Math.max(40, root.usableHeight-note.height-launcher.height-root.performanceHeight-music.height-controls.height-12); compact: true }
        MusicPlayer { id: music;compact:root.height<800; objectName: "musicPlayer"; width: parent.width; height: implicitHeight; monitoring: root.opened }
        ScratchNote { id: note; objectName:"scratchNote"; width: parent.width; height: root.height < 570 ? 40 : Math.min(72, Math.max(46, root.usableHeight * .10)) }
        PerformancePanel {
            objectName:"performancePanel"
            width: parent.width
            height: root.performanceHeight
            fitMode: true
            monitoring:root.opened
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
    DeviceSheet {
        objectName:"deviceSheet"
        visible:DesktopService.details!==""
        x:8;y:36;width:parent.width-16;height:Math.min(parent.height-y-8,420);z:30
    }
    PanelCard {
        visible:root.requestedSession!==""
        x:8;y:36;width:parent.width-16;height:128;z:30
        Text {x:12;y:16;width:parent.width-24;text:root.requestedSession==="logout"?"Log out of Susnix?":root.requestedSession==="reboot"?"Restart your computer?":"Shut down your computer?";color:Theme.text;font {family:Theme.fontFamily;pixelSize:11} }
        Text {x:12;y:44;text:"Save your work before continuing.";color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:10} }
        Row {x:12;y:78;spacing:8
            PanelButton {text:"Cancel";onClicked:root.requestedSession=""}
            PanelButton {text:"Confirm";tint:Theme.danger;enabled:!DesktopService.busy;onClicked:{DesktopService.session(root.requestedSession);root.requestedSession="";} }
        }
    }
    PanelCard {
        visible:DesktopService.error!=="" && DesktopService.details===""
        anchors {left:parent.left;right:parent.right;bottom:parent.bottom;margins:8}
        height:64;z:40
        Text {x:10;y:10;width:parent.width-46;text:DesktopService.error;wrapMode:Text.Wrap;color:Theme.danger;font {family:Theme.fontFamily;pixelSize:10} }
        PanelButton {anchors.right:parent.right;anchors.rightMargin:6;y:6;width:24;text:"×";onClicked:DesktopService.error=""}
    }

}
