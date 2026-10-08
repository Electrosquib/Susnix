import QtQuick
import "../theme"
import "../services"

// Two text layers crossfade inside one permanent, measured numeric slot.
Item {
    id: root
    property string text: ""
    property string slotText: "100%"
    property string lastText: ""
    property string oldText: ""
    property real progress: 1
    implicitWidth: Math.ceil(metrics.advanceWidth(slotText))
    implicitHeight: Math.ceil(metrics.height)
    onTextChanged: {
        oldText = lastText;
        lastText = text;
        if (oldText && visible && SystemStats.visualActive && Theme.animationFast > 0) blend.restart();
        else { blend.stop(); progress=1; }
    }
    FontMetrics { id: metrics; font: current.font }
    StatusLabel { anchors.fill: parent; slotText: root.slotText; text: root.oldText; opacity: 1-root.progress }
    StatusLabel { id: current; anchors.fill: parent; slotText: root.slotText; text: root.text; opacity: root.progress }
    NumberAnimation { id: blend; target: root; property: "progress"; from: 0; to: 1; duration: Theme.animationFast; easing.type: Easing.OutCubic }
}
