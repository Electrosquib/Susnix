import QtQuick
import QtQuick.Controls
import "../theme"
import "../services"

Item {
    id: root
    signal glitchRequested()
    property real activationPhase: 1
    property bool historyOpen: false
    readonly property bool pinned: TaskService.taskPinned
    readonly property alias shimmerTimer: minuteShimmer
    readonly property bool editing: editor.activeFocus
    readonly property color categoryColor: Theme.categoryColor(TaskService.taskState.category || "dev")
    implicitWidth: 300
    implicitHeight: 26
    TaskFrame {
        anchors.fill: parent
        categoryColor: root.categoryColor
        hovered: hover.hovered || root.editing
        opacity: hover.hovered || root.editing ? 1 : Theme.opacityInactive
    }
    Timer {
        id: minuteShimmer
        objectName: "taskShimmerTimer"
        interval: 60000; running: root.visible; repeat: true
        onTriggered: root.glitchRequested()
    }

    AbstractButton {
        id: complete
        objectName: "taskCheckbox"
        anchors { left: parent.left; leftMargin: 5; verticalCenter: parent.verticalCenter }
        width: 26; height: 24
        focusPolicy: Qt.NoFocus
        hoverEnabled: true
        enabled: editor.text.trim().length > 0
        opacity: enabled ? 1 : Theme.opacityDisabled
        Accessible.name: "Complete and archive current task"
        onClicked: { TaskService.completeTask(editor.text); editor.text = TaskService.task; root.glitchRequested(); }
        background: Item {}
        contentItem: Item {
            Rectangle {
                anchors.centerIn: parent
                width: 14; height: 14; radius: Math.min(2, Theme.cornerRadius)
                color: complete.hovered ? Qt.alpha(Theme.success, Theme.opacityHover) : Theme.transparent
                border { width: Theme.borderWidth; color: complete.hovered ? Theme.success : root.categoryColor }
                Text {
                    anchors.centerIn: parent
                    text: complete.down ? "✓" : ""
                    color: complete.hovered ? Theme.success : root.categoryColor
                    font.pixelSize: 11
                    opacity: complete.hovered ? 1 : Theme.opacityInactive
                }
            }
        }
    }
    Rectangle {
        x: complete.x + complete.width / 2 - width / 2
        y: (root.height - height) / 2
        width: 16 + root.activationPhase * 4; height: width; radius: width / 2
        visible: activation.running
        color: Theme.transparent
        border { width: Theme.borderWidth; color: Qt.alpha(root.categoryColor, (1-root.activationPhase) * Theme.opacityBorder) }
    }
    NumberAnimation { id: activation; target: root; property: "activationPhase"; from: 0; to: 1; duration: Theme.animationFast; easing.type: Easing.OutCubic }
    TextField {
        id: editor
        objectName: "taskTitle"
        anchors.centerIn: parent
        anchors.alignWhenCentered: false
        width: Math.max(0, root.width - 118)
        height: 24
        padding: 0
        text: TaskService.task
        placeholderText: TaskService.error || "Set a task…"
        placeholderTextColor: Theme.textMuted
        horizontalAlignment: TextInput.AlignHCenter
        color: Theme.text
        selectionColor: Qt.alpha(root.categoryColor, Theme.opacityBorder)
        selectedTextColor: Theme.text
        font { family: Theme.fontFamily; pixelSize: Theme.fontSize }
        background: Item {}
        Accessible.name: "Current task"
        onActiveFocusChanged: if (activeFocus) activation.restart()
        onAccepted: { TaskService.setTask(text); focus = false; }
        onEditingFinished: TaskService.setTask(text)
        Keys.onEscapePressed: event => { text = TaskService.task; focus = false; event.accepted = true; }
    }
    AbstractButton {
        id: pin
        objectName: "taskLockButton"
        anchors { right: arrow.left; rightMargin: 0; verticalCenter: parent.verticalCenter }
        width: 20; height: 24
        hoverEnabled: true
        focusPolicy: Qt.NoFocus
        onHoveredChanged: if (hovered) pinIcon.triggerShock()
        Accessible.name: root.pinned ? "Unlock task auto-hide" : "Lock task display open"
        onClicked: { TaskService.setPinned(!root.pinned); root.glitchRequested(); }
        background: Rectangle {
            radius: Theme.cornerRadius
            color: pin.hovered || root.pinned ? Qt.alpha(Theme.primary, Theme.opacityHover) : Theme.transparent
        }
        contentItem: Item {
            Icon { id: pinIcon; anchors.centerIn: parent; width: 12; height: 12; name: root.pinned ? "lock" : "unlock"; color: root.pinned ? Theme.primary : Theme.textMuted }
        }
    }
    AbstractButton {
        id: arrow
        objectName: "taskHistoryButton"
        anchors { right: parent.right; rightMargin: 5; verticalCenter: parent.verticalCenter }
        width: 24; height: 24
        hoverEnabled: true
        focusPolicy: Qt.NoFocus
        onHoveredChanged: if (hovered) arrowIcon.triggerShock()
        Accessible.name: "Show task queue and completed tasks"
        onClicked: { TaskService.setTask(editor.text); root.historyOpen = !root.historyOpen; }
        background: Rectangle {
            radius: Theme.cornerRadius
            color: arrow.hovered || root.historyOpen ? Qt.alpha(Theme.secondary, Theme.opacityHover) : Theme.transparent
        }
        contentItem: Item {
            Icon { id: arrowIcon; anchors.centerIn: parent; width: 12; height: 12; name: "chevron"; color: Theme.secondary; rotation: root.historyOpen ? 180 : 0 }
        }
    }
    EdgeSweep { id: edge; anchors.fill: parent; tint: root.categoryColor }
    HoverHandler { id: hover; onHoveredChanged: if (hovered) edge.trigger() }
    Connections {
        target: TaskService
        function onTaskChanged(): void { if (!editor.activeFocus || !TaskService.hasTask) editor.text = TaskService.task; }
        function onErrorChanged(): void { if (TaskService.error) editor.text = TaskService.task; }
    }
}
