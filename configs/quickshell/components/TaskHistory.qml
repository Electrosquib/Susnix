pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../theme"
import "../services"

PanelCard {
    id: root
    signal glitchRequested()
    implicitWidth: 360
    implicitHeight: Math.min(380, 156 + (TaskService.futureTasks.length + TaskService.completedToday.length) * 36)
    radius: Theme.cornerRadius

    function addTask(): void {
        if (!newTask.text.trim()) return;
        TaskService.addFutureTask(newTask.text);
        root.glitchRequested();
        newTask.clear();
        newTask.forceActiveFocus();
    }

    Text {
        anchors { left: parent.left; leftMargin: 12; top: parent.top; topMargin: 10 }
        text: "TASK QUEUE"
        color: Theme.textMuted
        font { family: Theme.fontFamily; pixelSize: 10; letterSpacing: 0.6 }
    }
    TextField {
        id: newTask
        objectName: "futureTaskInput"
        anchors { left: parent.left; leftMargin: 12; right: add.left; rightMargin: 6; top: parent.top; topMargin: 30 }
        height: 30
        placeholderText: "Add a future task…"
        placeholderTextColor: Theme.textMuted
        color: Theme.text
        selectionColor: Qt.alpha(Theme.primary, Theme.opacityBorder)
        selectedTextColor: Theme.text
        font { family: Theme.fontFamily; pixelSize: Theme.fontSize }
        onAccepted: root.addTask()
        background: Rectangle { radius: Theme.cornerRadius; color: Theme.surface; border { width: Theme.borderWidth; color: Qt.alpha(Theme.border, Theme.opacityBorder) } }
        Accessible.name: "Future task"
    }
    Button {
        id: add
        objectName: "addFutureTask"
        anchors { right: parent.right; rightMargin: 12; top: newTask.top }
        width: 30; height: 30
        focusPolicy: Qt.NoFocus
        enabled: newTask.text.trim().length > 0
        onClicked: root.addTask()
        Accessible.name: "Add future task"
        background: Rectangle { radius: Theme.cornerRadius; color: Qt.alpha(Theme.primary, Theme.opacityHover) }
        contentItem: Text { text: "+"; color: Theme.primary; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 18 }
    }
    Flickable {
        anchors { left: parent.left; right: parent.right; top: newTask.bottom; bottom: parent.bottom; margins: 12; topMargin: 10 }
        clip: true
        contentWidth: width
        contentHeight: rows.height
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: rows
            width: parent.width
            spacing: 4
            Text { text: "UP NEXT · " + TaskService.futureTasks.length; color: Theme.textMuted; font { family: Theme.fontFamily; pixelSize: 10 } }
            Text { visible: TaskService.futureTasks.length === 0; text: "No upcoming tasks."; color: Theme.textMuted; font { family: Theme.fontFamily; pixelSize: 11 } }
            Repeater {
                model: TaskService.futureTasks
                delegate: TaskQueueRow { required property var modelData; width: rows.width; taskData: modelData }
            }
            Item { width: 1; height: 6 }
            Text { text: "COMPLETED TODAY · " + TaskService.completedToday.length; color: Theme.textMuted; font { family: Theme.fontFamily; pixelSize: 10 } }
            Text { visible: TaskService.completedToday.length === 0; text: "No completed tasks today."; color: Theme.textMuted; font { family: Theme.fontFamily; pixelSize: 11 } }
            Repeater {
                model: TaskService.completedToday
                delegate: TaskQueueRow { required property var modelData; width: rows.width; taskData: modelData; archived: true; onInteracted: root.glitchRequested() }
            }
        }
    }
}
