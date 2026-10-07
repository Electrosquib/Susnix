import QtQuick
import QtQuick.Window
import "../theme"

// Vector facets work with software rendering; light derives from the palette.
Image {
    id: root
    property color primary: Theme.primary
    property color secondary: Theme.secondary
    property color accent: Theme.accent
    property bool multiColor: false
    readonly property bool shockActive: shock.active
    function triggerShock(): void { shock.trigger(); }
    sourceSize.width: Math.ceil(width * Math.max(2, Window.window ? Window.window.devicePixelRatio : 1))
    sourceSize.height: Math.ceil(height * Math.max(2, Window.window ? Window.window.devicePixelRatio : 1))
    source: "data:image/svg+xml," + encodeURIComponent(
        "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 28 28'>" +
        "<defs><linearGradient id='top' x1='0' y1='0' x2='1' y2='1'><stop stop-color='" + primary + "'/><stop offset='.45' stop-color='" + Theme.text + "'/><stop offset='1' stop-color='" + secondary + "'/></linearGradient>" +
        "<linearGradient id='side' x1='0' y1='0' x2='1' y2='1'><stop stop-color='" + secondary + "'/><stop offset='1' stop-color='" + primary + "'/></linearGradient></defs>" +
        "<path d='M14 4L24 10V20L14 26L4 20V10Z' fill='none' stroke='" + primary + "' stroke-opacity='" + Theme.opacityGlow + "' stroke-width='3'/>" +
        "<path d='M14 6L22 11L14 16L6 11Z' fill='url(#top)' fill-opacity='" + Theme.opacityBorder + "' stroke='" + primary + "' stroke-width='.8'/>" +
        "<path d='M6 11L14 16V24L6 19Z' fill='url(#side)' fill-opacity='" + Theme.opacityBorder + "' stroke='" + (multiColor ? secondary : primary) + "' stroke-width='.8'/>" +
        "<path d='M14 16L22 11V19L14 24Z' fill='" + (multiColor ? accent : primary) + "' fill-opacity='" + Theme.opacityHover + "' stroke='" + (multiColor ? accent : primary) + "' stroke-width='.8'/>" +
        "<path d='M14 6L22 11M14 16V24' fill='none' stroke='" + primary + "' stroke-width='1.3'/>" +
        "<path d='M9 10L14 7L19 10M14 16L18 13' fill='none' stroke='" + Theme.text + "' stroke-opacity='" + Theme.opacityBorder + "' stroke-width='.8'/>" +
        "</svg>")
    ElectricShock {
        id: shock
        anchors.fill: parent
        viewBox: "0 0 28 28"
        paths: "<path d='M14 6L22 11V19L14 24L6 19V11Z M6 11L14 16L22 11 M14 16V24'/>"
        tint: root.primary
    }
    HoverHandler { onHoveredChanged: if (hovered) root.triggerShock() }
}
