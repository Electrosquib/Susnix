import QtQuick
import "../theme"

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
        if (oldText && visible && Theme.animationFast > 0) blend.restart();
    }
    FontMetrics { id: metrics; font: current.font }
    StatusLabel { anchors.fill: parent; slotText: root.slotText; text: root.oldText; opacity: 1-root.progress }
    StatusLabel { id: current; anchors.fill: parent; slotText: root.slotText; text: root.text; opacity: root.progress }
    NumberAnimation { id: blend; target: root; property: "progress"; from: 0; to: 1; duration: Theme.animationFast; easing.type: Easing.OutCubic }
}
