import QtQuick
import QtQuick.Controls
import "../theme"
import "../services"

Item {
    id: root
    signal interacted()
    required property var taskData
    property bool archived: false
    implicitHeight: Math.max(30, title.implicitHeight + 12)
    CheckBox {
        id: restore
        objectName: "restoreTask-" + root.taskData.archiveIndex
        visible: root.archived
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        width: 24; height: 26
        checked: true
        Accessible.name: "Restore task: " + root.taskData.task
        onClicked: { TaskService.restoreCompleted(root.taskData.archiveIndex); root.interacted(); }
        background: Item {}
        indicator: Rectangle {
            x: 5; y: 6; width: 14; height: 14
            radius: Theme.cornerRadius
            color: restore.hovered ? Qt.alpha(Theme.success, Theme.opacityHover) : Theme.transparent
            border { width: Theme.borderWidth; color: Theme.success }
            Text { anchors.centerIn: parent; text: "✓"; color: Theme.success; font.pixelSize: 11 }
        }
    }
    Rectangle {
        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
        visible: !root.archived
        width: 3; height: 12
        color: Theme.categoryColor(root.taskData.category || "dev")
    }
    Text {
        id: title
        anchors { left: parent.left; leftMargin: root.archived ? 30 : 20; right: stamp.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        text: root.taskData.task
        wrapMode: Text.Wrap
        color: root.archived ? Theme.textMuted : Theme.text
        font { family: Theme.fontFamily; pixelSize: Theme.fontSize }
    }
    Text {
        id: stamp
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        text: root.archived ? Qt.formatDateTime(new Date(root.taskData.completedAt), "HH:mm") : ""
        color: Theme.textMuted
        font { family: Theme.fontFamily; pixelSize: 10 }
    }
}
