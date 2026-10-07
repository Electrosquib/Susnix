pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property string task: ""
    property var taskState: ({task: "", completedTasks: []})
    readonly property bool taskPinned: taskState.taskPinned === true
    property bool hasTask: false
    property bool saving: false
    property string error: ""
    property var pendingState: null
    property var queuedState: null
    property var savedState: ({task: "", completedTasks: []})
    property string today: Qt.formatDateTime(new Date(), "yyyy-MM-dd")
    readonly property var futureTasks: taskState.futureTasks || []
    readonly property var completedToday: (taskState.completedTasks || []).map((entry, index) =>
        Object.assign({}, entry, {archiveIndex: index})).filter(entry =>
        entry && typeof entry.task === "string" && entry.completedAt &&
        Qt.formatDateTime(new Date(entry.completedAt), "yyyy-MM-dd") === today).slice().reverse()
    readonly property string statePath: Quickshell.env("HOME") + "/.local/state/susnix/task.json"

    function applyState(state: var): void {
        taskState = state;
        task = typeof state.task === "string" ? state.task.trim() : "";
        hasTask = task.length > 0;
    }

    function readTask(data: string): void {
        if (saving) return;
        try {
            const state = JSON.parse(data);
            if (!state || typeof state.task !== "string" ||
                (state.completedTasks !== undefined && !Array.isArray(state.completedTasks)) ||
                (state.futureTasks !== undefined && (!Array.isArray(state.futureTasks) ||
                    state.futureTasks.some(entry => !entry || typeof entry.task !== "string" || !entry.task.trim()))))
                throw new Error("invalid task state");
            savedState = state;
            error = "";
            applyState(state);
        } catch (failure) {
            error = "Invalid task state";
        }
    }

    function writeState(state: var): void {
        // FileView writes atomically. Serialize edits and completion into one file.
        applyState(state);
        error = "";
        if (saving) { queuedState = state; return; }
        if (JSON.stringify(state) === JSON.stringify(savedState)) return;
        pendingState = state;
        saving = true;
        taskFile.setText(JSON.stringify(state, null, 4) + "\n");
    }

    function setPinned(value: bool): void {
        const base = queuedState || pendingState || taskState;
        writeState(Object.assign({}, base, {taskPinned: value}));
    }

    function setTask(value: string): void {
        const base = queuedState || pendingState || taskState;
        const next = Object.assign({}, base, {task: value.trim(), completed: false});
        writeState(next);
    }

    function completeTask(value: string): void {
        const title = value.trim();
        if (!title) return;
        const base = queuedState || pendingState || taskState;
        const history = (base.completedTasks || []).slice();
        history.push({id: base.taskId || newId(), task: title, category: base.category || "dev", completedAt: new Date().toISOString()});
        writeState(advance(Object.assign({}, base, {completedTasks: history})));
    }

    function newId(): string {
        return Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 10);
    }

    function advance(state: var): var {
        const queue = (state.futureTasks || []).slice();
        const next = queue.shift();
        return Object.assign({}, state, {
            task: next ? next.task : "", taskId: next ? next.id || newId() : "",
            category: next ? next.category || "dev" : state.category || "dev",
            completed: false, futureTasks: queue
        });
    }

    function addFutureTask(value: string): void {
        const title = value.trim();
        if (!title) return;
        const base = queuedState || pendingState || taskState;
        const queue = (base.futureTasks || []).slice();
        queue.push({id: newId(), task: title, category: base.category || "dev"});
        const next = Object.assign({}, base, {futureTasks: queue});
        writeState(next.task.trim() ? next : advance(next));
    }

    function restoreCompleted(index: int): void {
        const base = queuedState || pendingState || taskState;
        const history = (base.completedTasks || []).slice();
        if (index < 0 || index >= history.length) return;
        const entry = history[index];
        if (!entry || typeof entry.task !== "string" || !entry.task.trim()) return;
        history.splice(index, 1);
        const queue = (base.futureTasks || []).slice();
        queue.push({id: entry.id || newId(), task: entry.task, category: entry.category || "dev"});
        const next = Object.assign({}, base, {completedTasks: history, futureTasks: queue});
        writeState(next.task.trim() ? next : advance(next));
    }

    Timer {
        interval: 30000; running: true; repeat: true
        onTriggered: root.today = Qt.formatDateTime(new Date(), "yyyy-MM-dd")
    }

    FileView {
        id: taskFile
        path: root.statePath
        watchChanges: true
        printErrors: false
        onLoaded: root.readTask(text())
        onFileChanged: reload()
        onLoadFailed: { root.error = "Task state unavailable"; }
        onSaved: {
            root.savedState = root.pendingState;
            root.pendingState = null;
            // Finish the FileView callback before starting the next operation.
            Qt.callLater(() => {
                root.saving = false;
                const next = root.queuedState;
                root.queuedState = null;
                if (next) root.writeState(next);
                else taskFile.reload();
            });
        }
        onSaveFailed: {
            root.saving = false;
            root.pendingState = null;
            root.queuedState = null;
            root.applyState(root.savedState);
            root.error = "Could not save task";
            console.warn("Susnix: could not save task state");
        }
    }

    Process {
        id: initialize
        command: ["bash", Qt.resolvedUrl("collect.sh").toString().replace(/^file:\/\//, ""), "init-task"]
        running: true
        onRunningChanged: {
            if (!running) taskFile.reload();
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim()) console.warn("Susnix task initialization: " + text.trim());
            }
        }
    }
    // Also recover when the state file is deleted/replaced by an external editor.
    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: {
            if (!taskFile.loaded && !initialize.running) initialize.running = true;
            taskFile.reload();
        }
    }
}
