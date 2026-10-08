import QtQuick
import Quickshell
import "../theme"

Row {
    id:root
    property bool monitoring:true
    property bool compact: false
    property bool minimal: false
    spacing: minimal ? 0 : 10
    SystemClock { id: clock; precision: root.monitoring ? SystemClock.Seconds : SystemClock.Minutes }
    StatusLabel {
        slotText: "MMM 00"
        visible: !parent.compact
        text: Qt.formatDateTime(clock.date, "MMM dd")
        anchors.verticalCenter: parent.verticalCenter
    }
    Icon { visible: !parent.minimal; name: "clock"; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
    StatusLabel {
        slotText: parent.minimal ? "00:00" : "00:00:00"
        text: Qt.formatDateTime(clock.date, parent.minimal ? "HH:mm" : "HH:mm:ss")
        color: Theme.primary
        font { family: Theme.fontFamily; pixelSize: 15 }
    }
}
