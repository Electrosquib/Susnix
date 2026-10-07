import QtQuick
import "../services"
import "../theme"

Row {
    id: root
    property bool compact: false
    Accessible.name: "Network: " + SystemStats.network
    spacing: 5
    readonly property bool online: ["WiFi", "Wired", "Online"].includes(SystemStats.network)
    Icon {
        id: networkIcon
        name: SystemStats.network === "WiFi" ? "wifi" : "network"
        color: root.online ? Theme.primary : Theme.textMuted
        anchors.verticalCenter: parent.verticalCenter
    }
    StatusLabel {
        visible: !root.compact
        slotText: "Unavailable"
        horizontalAlignment: Text.AlignLeft
        text: SystemStats.network
        anchors.verticalCenter: parent.verticalCenter
    }
    Connections {
        target: SystemStats
        function onNetworkActivitySerialChanged(): void { if (root.online) networkIcon.pulse(); }
    }

}
