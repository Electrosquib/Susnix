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
    implicitHeight: 96
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
        text: root.duration > 0 ? root.timestamp(root.elapsed) + " / " + root.timestamp(root.duration) : root.player ? root.player.identity : "NO PLAYER"
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
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 65; spacing: 8
        PanelButton {
            objectName: "previousTrack"; width: 34; height: 22; text: "|◀"; tint: Theme.media
            enabled: root.player !== null && root.player.canGoPrevious
            onClicked: root.player.previous()
        }
        PanelButton {
            objectName: "togglePlayback"; width: 46; height: 22; text: root.player && root.player.isPlaying ? "Ⅱ" : "▶"; tint: Theme.media
            enabled: root.player !== null && root.player.canTogglePlaying
            onClicked: root.player.togglePlaying()
        }
        PanelButton {
            objectName: "nextTrack"; width: 34; height: 22; text: "▶|"; tint: Theme.media
            enabled: root.player !== null && root.player.canGoNext
            onClicked: root.player.next()
        }
    }
    Rectangle {
        x: 12; y: root.height-5; width: parent.width-24; height: 2
        color: Qt.alpha(Theme.media, Theme.opacityGlow)
        Rectangle {
            width: parent.width*(root.duration > 0 ? Math.max(0,Math.min(1,root.elapsed/root.duration)) : 0)
            height: parent.height; color: Theme.media
        }
    }
}
