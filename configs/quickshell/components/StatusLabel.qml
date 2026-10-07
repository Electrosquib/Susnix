import QtQuick
import "../theme"

Text {
    id: root
    property string slotText: ""
    width: slotText ? Math.ceil(metrics.advanceWidth(slotText)) : implicitWidth
    height: Math.ceil(metrics.height)
    horizontalAlignment: slotText ? Text.AlignRight : Text.AlignLeft
    clip: !!slotText
    color: Theme.textMuted
    font { family: Theme.fontFamily; pixelSize: Theme.fontSize }
    FontMetrics { id: metrics; font: root.font }
}
