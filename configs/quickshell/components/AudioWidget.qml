import QtQuick
import "../services"
import "../theme"

Row {
    property bool compact: false
    spacing: 5
    Icon {
        id: audio
        name: SystemStats.muted ? "muted" : "audio"
        color: Theme.media
        anchors.verticalCenter: parent.verticalCenter
    }
    StatusLabel {
        visible: !parent.compact
        slotText: "Muted"
        text: SystemStats.volume < 0 ? "N/A" : SystemStats.muted ? "Muted" : SystemStats.volume + "%"
        anchors.verticalCenter: parent.verticalCenter
    }
    Connections {
        target: SystemStats
        function onVolumeChanged(): void { audio.pulse(); }
        function onMutedChanged(): void { audio.pulse(); }
    }

}
