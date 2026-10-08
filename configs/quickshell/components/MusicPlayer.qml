import QtQuick
import Quickshell.Services.Mpris
import "../theme"

PanelCard {
    id: root
    property bool monitoring: true
    // Prefer playing media; keep paused players available for resuming playback.
    readonly property var players: Mpris.players.values
    property MprisPlayer player: players.find(candidate => candidate.isPlaying) || players[0] || null
    property real elapsed: player && player.positionSupported ? player.position : 0
    readonly property real duration: player && player.lengthSupported ? player.length : 0
    implicitHeight: 132
    function timestamp(seconds: real): string {
        const total = Math.max(0, Math.floor(seconds));
        return Math.floor(total/60) + ":" + (total%60).toString().padStart(2,"0");
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.monitoring && root.player !== null && root.player.isPlaying && root.player.positionSupported
        onTriggered: root.elapsed = root.player.position
    }
    onPlayerChanged: elapsed = player && player.positionSupported ? player.position : 0
    onMonitoringChanged: if (monitoring) elapsed = player && player.positionSupported ? player.position : 0
    Connections {
        target: root.player
        function onPositionChanged(): void { root.elapsed = root.player.position; }
        function onTrackTitleChanged(): void { root.elapsed = root.player.positionSupported ? root.player.position : 0; }
    }
    Text {
        x: 12; y: 8
        text: "MUSIC"
        color: Theme.media
        font { family: Theme.fontFamily; pixelSize: 10; letterSpacing: 1 }
    }
    Text {
        anchors { right: parent.right; rightMargin: 12 }
        y: 8
        text: root.player ? root.player.isPlaying ? "PLAYING" : "PAUSED" : "NO PLAYER"
        width: parent.width-90; elide: Text.ElideRight; horizontalAlignment: Text.AlignRight
        color: Theme.textMuted
        font { family: Theme.fontFamily; pixelSize: 9 }
    }
    Rectangle {
        id: artwork
        x: 12; y: 28; width: 32; height: 32
        radius: Theme.cornerRadius
        color: Qt.alpha(Theme.media, Theme.opacityGlow)
        border { width: Theme.borderWidth; color: Qt.alpha(Theme.media, Theme.opacityBorder) }
        Image {
            id: cover
            anchors.fill: parent; anchors.margins: 1
            source: root.player ? root.player.trackArtUrl : ""
            asynchronous: true; fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
        }
        Text { anchors.centerIn: parent; visible: !cover.visible; text: "♫"; color: Theme.media; font.pixelSize: 21 }
    }
    Text {
        x: 54; y: 28; width: parent.width-x-12
        text: root.player ? root.player.trackTitle || "Unknown track" : "Nothing playing"
        elide: Text.ElideRight
        color: Theme.text
        font { family: Theme.fontFamily; pixelSize: 11 }
    }
    Text {
        x: 54; y: 45; width: parent.width-x-12
        text: root.player ? root.player.trackArtist || root.player.identity : "Play music in your favorite app"
        elide: Text.ElideRight
        color: Theme.textMuted
        font { family: Theme.fontFamily; pixelSize: 9 }
    }
    Item {
        id: track
        objectName: "trackIndicator"
        x: 12; y: 63; width: parent.width-24; height: 16
        readonly property real fraction: root.duration > 0 ? Math.max(0,Math.min(1,root.elapsed/root.duration)) : 0
        readonly property bool seekable: root.player !== null && root.player.canSeek && root.player.positionSupported && root.duration > 0
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width; height: 6; radius: height/2
            color: Theme.surfaceRaised
            border { width: Theme.borderWidth; color: Qt.alpha(Theme.media,Theme.opacityBorder) }
            Rectangle {
                width: parent.width*track.fraction; height: parent.height; radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.media }
                    GradientStop { position: 1; color: Theme.primary }
                }
            }
        }
        Rectangle {
            visible: root.duration > 0
            x: Math.max(0,Math.min(parent.width-width,parent.width*track.fraction-width/2))
            anchors.verticalCenter: parent.verticalCenter
            width: 8; height: 8; radius: 4
            color: Theme.text
            border { width: Theme.borderWidth; color: Theme.media }
        }
        MouseArea {
            anchors.fill: parent
            enabled: track.seekable
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                root.player.position = root.duration*Math.max(0,Math.min(1,mouse.x/width));
                root.elapsed = root.player.position;
            }
        }
    }
    Text {
        x: 12; y: 79; text: root.timestamp(root.elapsed)
        color: Theme.textMuted
        font { family: Theme.fontFamily; pixelSize: 9 }
    }
    Text {
        anchors { right: parent.right; rightMargin: 12 }
        y: 79; text: root.duration > 0 ? root.timestamp(root.duration) : "--:--"
        color: Theme.textMuted
        font { family: Theme.fontFamily; pixelSize: 9 }
    }
    component PlaybackButton: PanelButton {
        id: control
        width: 46; height: 30; tint: Theme.media
        opacity: enabled ? 1 : Math.max(.55,Theme.opacityDisabled)
        background: Rectangle {
            radius: Theme.cornerRadius
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.surfaceRaised }
                GradientStop { position: 1; color: Theme.backgroundRaised }
            }
            Rectangle {
                anchors.fill: parent; radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.alpha(control.tint,control.hovered ? Theme.opacityBorder : Theme.opacityHover) }
                    GradientStop { position: .45; color: Qt.alpha(control.tint,Theme.opacityGlow) }
                    GradientStop { position: 1; color: Theme.transparent }
                }
                border { width: Theme.borderWidth; color: Qt.alpha(control.tint,Theme.opacityBorder) }
            }
            Rectangle {
                x: 3; y: 2; width: parent.width-6; height: 1
                color: Qt.alpha(Theme.text,control.down ? Theme.opacityGlow : Theme.opacityHover)
            }
        }
        contentItem: Text {
            text: control.text
            color: control.enabled ? Theme.text : Theme.textMuted
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            font { family: Theme.fontFamily; pixelSize: 16 }
            y: control.down ? 1 : 0
        }
    }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 96; spacing: 10
        PlaybackButton {
            objectName: "previousTrack"; text: "|◀"
            enabled: root.player !== null && root.player.canGoPrevious
            onClicked: root.player.previous()
        }
        PlaybackButton {
            objectName: "togglePlayback"; width: 62; text: root.player && root.player.isPlaying ? "Ⅱ" : "▶"
            enabled: root.player !== null && root.player.canTogglePlaying
            onClicked: root.player.togglePlaying()
        }
        PlaybackButton {
            objectName: "nextTrack"; text: "▶|"
            enabled: root.player !== null && root.player.canGoNext
            onClicked: root.player.next()
        }
    }
}
