import QtQuick
import "../theme"

Item {
    id: root
    property bool monitoring:true
    property bool compact: false
    property real maximumWidth: 600
    // Keep text/icons at native size. Drop secondary detail before shrinking.
    readonly property int detailLevel: maximumWidth >= 650 ? 0 : maximumWidth >= 460 ? 1
        : maximumWidth >= 390 ? 2 : maximumWidth >= 250 ? 3 : 4
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Row {
        id: content
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: root.detailLevel > 0 ? 5 : 12
        NetworkWidget { compact: root.compact || root.detailLevel > 0; anchors.verticalCenter: parent.verticalCenter }
        SectionDivider { visible: root.detailLevel < 3; anchors.verticalCenter: parent.verticalCenter }
        AudioWidget { compact: root.detailLevel >= 3; anchors.verticalCenter: parent.verticalCenter }
        SectionDivider { visible: root.detailLevel < 3; anchors.verticalCenter: parent.verticalCenter }
        Row {
            spacing: Theme.resourceGap
            anchors.verticalCenter: parent.verticalCenter
            GpuWidget { compact: root.detailLevel >= 2; visible: root.detailLevel < 4; anchors.verticalCenter: parent.verticalCenter }
            CpuWidget { compact: root.detailLevel >= 2; anchors.verticalCenter: parent.verticalCenter }
        }
        SectionDivider { visible: root.detailLevel < 3; anchors.verticalCenter: parent.verticalCenter }
        ClockWidget { monitoring:root.monitoring;compact: root.compact || root.detailLevel > 0; minimal: root.detailLevel >= 3; anchors.verticalCenter: parent.verticalCenter }
        Icon { name: "calendar"; color: Theme.secondary; anchors.verticalCenter: parent.verticalCenter; Accessible.name: "Calendar" }
    }
}
