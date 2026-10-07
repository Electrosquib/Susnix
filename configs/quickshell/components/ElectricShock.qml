import QtQuick
import QtQuick.Window
import "../theme"

// Short broken strokes travel on the icon's actual vector outline, not its box.
Item {
    id: root
    property string paths: ""
    property string viewBox: "0 0 24 24"
    property color tint: Theme.primary
    property real phase: 1
    readonly property bool active: discharge.running
    readonly property int frame: Math.floor(phase * 8)
    visible: active && Theme.glowStrength > 0
    function trigger(): void {
        if (Theme.glowStrength > 0 && Theme.animationFast > 0) discharge.restart();
    }
    Image {
        anchors.fill: parent
        sourceSize.width: Math.ceil(width * Math.max(2, Window.window ? Window.window.devicePixelRatio : 1))
        sourceSize.height: Math.ceil(height * Math.max(2, Window.window ? Window.window.devicePixelRatio : 1))
        opacity: Theme.glowStrength * (root.frame % 3 === 1 ? 0.5 : 1) * (1 - root.phase * 0.6)
        source: "data:image/svg+xml," + encodeURIComponent(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='" + root.viewBox + "' fill='none' stroke-linecap='square' stroke-linejoin='miter'>" +
            "<g stroke='" + root.tint + "' stroke-width='2.2' stroke-dasharray='3 17 1 11' stroke-dashoffset='" + (-root.frame * 9) + "'>" + root.paths + "</g>" +
            "<g stroke='" + Theme.text + "' stroke-width='.8' stroke-dasharray='1 31' stroke-dashoffset='" + (-root.frame * 9 - 2) + "'>" + root.paths + "</g>" +
            "<g stroke='" + Theme.secondary + "' stroke-width='1.2' stroke-dasharray='2 27' stroke-dashoffset='" + (-root.frame * 9 + 4) + "'>" + root.paths + "</g></svg>")
    }
    NumberAnimation {
        id: discharge
        target: root; property: "phase"; from: 0; to: 1
        duration: Theme.animationFast
        easing.type: Easing.Linear
    }
}
