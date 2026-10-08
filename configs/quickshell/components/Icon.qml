import QtQuick
import QtQuick.Window
import "../theme"

// Inline vector paths stay crisp and inherit semantic colors without an icon font.
Item {
    id: root
    property string name: ""
    property bool effectsEnabled: true
    // Qt serializes alpha as #AARRGGBB; SVG requires RGB plus opacity.
    readonly property color strokeColor: Qt.rgba(color.r, color.g, color.b, 1)
    property color color: Theme.primary
    readonly property var paths: {
        "apps": "<rect x='3' y='3' width='7' height='7'/><rect x='14' y='3' width='7' height='7'/><rect x='3' y='14' width='7' height='7'/><rect x='14' y='14' width='7' height='7'/>",
        "download": "<path d='M12 3V16M6 10L12 16L18 10M4 17V21H20V17'/>",
        "document": "<path d='M6 2H15L20 7V22H6ZM15 2V8H20M9 12H17M9 16H17'/>",
        "picture": "<rect x='2' y='3' width='20' height='18' rx='1'/><path d='M2 17L8 11L13 16L17 12L22 17'/><circle cx='16' cy='8' r='2'/>",
        "play": "<path d='M8 4L21 12L8 20Z'/>",
        "bluetooth": "<path d='M8 5L18 15L12 21V3L18 9L8 19'/>",
        "brightness": "<circle cx='12' cy='12' r='4'/><path d='M12 2V5M12 19V22M2 12H5M19 12H22M5 5L7 7M17 17L19 19M5 19L7 17M17 7L19 5'/>",
        "controls": "<path d='M4 6H20M4 12H20M4 18H20'/><circle cx='9' cy='6' r='2'/><circle cx='15' cy='12' r='2'/><circle cx='8' cy='18' r='2'/>",
        "terminal": "<rect x='2' y='4' width='20' height='16' rx='2'/><path d='M6 8L10 12L6 16M13 16H18'/>",
        "folder": "<path d='M2 7V20H22V7H12L9 4H2Z M2 10H22'/>",
        "browser": "<circle cx='12' cy='12' r='9'/><ellipse cx='12' cy='12' rx='4' ry='9'/><path d='M3 12H21M5 6H19M5 18H19'/>",
        "ai": "<path d='M12 2L21 7V17L12 22L3 17V7Z M3 7L12 12L21 7M12 12V22'/><circle cx='12' cy='7' r='2'/>",
        "editor": "<path d='M4 20L5 15L17 3L21 7L9 19Z M14 6L18 10M4 20H20'/>",
        "settings": "<circle cx='12' cy='12' r='4'/><path d='M9 2H15L16 5L19 6L22 9V15L19 16L18 19L15 22H9L8 19L5 18L2 15V9L5 8L6 5Z'/>",
        "logo": "<path d=\"M3 4H21L12 21Z M7 7H17L12 16Z\"/>",
        "wifi": "<path d=\"M2 8Q12 0 22 8M5 12Q12 6 19 12M8 16Q12 12 16 16\"/><circle cx=\"12\" cy=\"20\" r=\"1\"/>",
        "network": "<rect x=\"3\" y=\"3\" width=\"18\" height=\"12\" rx=\"1\"/><path d=\"M12 15V21M7 21H17M7 7H17M7 10H17\"/>",
        "audio": "<path d=\"M3 9H7L12 5V19L7 15H3ZM16 8Q20 12 16 16M19 5Q25 12 19 19\"/>",
        "muted": "<path d=\"M3 9H7L12 5V19L7 15H3ZM16 9L22 15M22 9L16 15\"/>",
        "cpu": "<rect x=\"6\" y=\"6\" width=\"12\" height=\"12\" rx=\"1\"/><rect x=\"9\" y=\"9\" width=\"6\" height=\"6\"/><path d=\"M8 2V6M12 2V6M16 2V6M8 18V22M12 18V22M16 18V22M2 8H6M2 12H6M2 16H6M18 8H22M18 12H22M18 16H22\"/>",
        "gpu": "<rect x=\"2\" y=\"5\" width=\"20\" height=\"13\" rx=\"1\"/><circle cx=\"11\" cy=\"11.5\" r=\"4\"/><path d=\"M11 8V15M7.5 11.5H14.5M5 18V21M8 18V21M11 18V21M17 8H19M17 11H19\"/>",
        "clock": "<circle cx=\"12\" cy=\"12\" r=\"9\"/><path d=\"M12 6V12L16 14\"/>",
        "calendar": "<rect x=\"3\" y=\"5\" width=\"18\" height=\"16\" rx=\"2\"/><path d=\"M7 2V8M17 2V8M3 10H21M7 14H9M12 14H14M17 14H18M7 18H9M12 18H14\"/>",
        "lock": "<rect x=\"5\" y=\"10\" width=\"14\" height=\"11\" rx=\"1\"/><path d=\"M8 10V6a4 4 0 0 1 8 0v4M12 14v3\"/>",
        "unlock": "<rect x=\"5\" y=\"10\" width=\"14\" height=\"11\" rx=\"1\"/><path d=\"M8 10V6a4 4 0 0 1 8 0M12 14v3\"/>",
        "chevron": "<path d=\"M5 9L12 16L19 9\"/>"
    }
    function triggerShock(): void { if (effectsEnabled) shock.trigger(); }
    readonly property bool shockActive: shock.active
    property real ringPhase: 1
    function pulse(): void { if (visible && Theme.glowStrength > 0) rings.restart(); }
    transform: Translate {
        y: root.effectsEnabled && hover.hovered ? -1 : 0
        Behavior on y { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }
    }
    implicitWidth: 16
    implicitHeight: 16
    Image {
        id: glyph
        anchors.fill: parent
        source: "data:image/svg+xml," + encodeURIComponent("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='" + root.strokeColor + "' stroke-opacity='" + root.color.a + "' stroke-width='1.4' stroke-linecap='round' stroke-linejoin='round'>" + (root.paths[root.name] || "") + "</svg>")
        opacity: hover.hovered ? 1 : 1 - Theme.opacityGlow
        Behavior on opacity { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }
        sourceSize.width: Math.ceil(width * Math.max(2, Window.window ? Window.window.devicePixelRatio : 1))
        sourceSize.height: Math.ceil(height * Math.max(2, Window.window ? Window.window.devicePixelRatio : 1))
    }
    ElectricShock { id: shock; anchors.fill: parent; paths: root.paths[root.name] || ""; tint: root.color }
    HoverHandler { id: hover; onHoveredChanged: if (hovered) root.triggerShock() }
    Rectangle {
        anchors.centerIn: parent
        visible: rings.running
        width: root.width + root.ringPhase * 6; height: width
        radius: width / 2
        color: Theme.transparent
        border { width: Theme.borderWidth; color: Qt.alpha(root.color, (1-root.ringPhase) * Theme.glowStrength * Theme.opacityBorder) }
    }
    NumberAnimation { id: rings; target: root; property: "ringPhase"; from: 0; to: 1; duration: Theme.animationFast; easing.type: Easing.OutCubic }

}
