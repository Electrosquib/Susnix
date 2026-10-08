import QtQuick
import QtQuick.Window
import "../theme"
import "../components"

// Vector glass folder: no icon font, raster scaling, or live shadow passes.
Item {
    id: root
    property color tint: Theme.primary
    property string emblem: ""
    property bool effectsEnabled: true
    implicitWidth: 48
    implicitHeight: 44
    Image {
        anchors.fill: parent
        sourceSize.width: Math.ceil(width * Math.max(2, Window.window ? Window.window.devicePixelRatio : 1))
        sourceSize.height: Math.ceil(height * Math.max(2, Window.window ? Window.window.devicePixelRatio : 1))
        source: root.visible && width>0 && height>0 ? "data:image/svg+xml," + encodeURIComponent(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 56'>" +
            "<defs><linearGradient id='body' x2='.7' y2='1'><stop stop-color='" + root.tint + "' stop-opacity='.5'/><stop offset='.45' stop-color='" + Theme.surfaceRaised + "'/><stop offset='1' stop-color='" + root.tint + "' stop-opacity='.18'/></linearGradient>" +
            "<linearGradient id='edge' x2='1' y2='1'><stop stop-color='" + Theme.text + "'/><stop offset='.3' stop-color='" + root.tint + "'/><stop offset='1' stop-color='" + Theme.secondary + "'/></linearGradient></defs>" +
            "<path d='M6 16V9Q6 6 9 6H26L32 12H55Q58 12 58 16V44H6Z' fill='" + root.tint + "' opacity='.25'/>" +
            "<path d='M6 18H58V45Q58 49 54 49H10Q6 49 6 45Z' fill='url(#body)' stroke='" + root.tint + "' stroke-width='6' stroke-opacity='.09'/>" +
            "<path d='M6 18H58V45Q58 49 54 49H10Q6 49 6 45Z' fill='url(#body)' stroke='url(#edge)' stroke-width='1.5'/>" +
            "<path d='M8 20H56M10 47H22M50 47H54' stroke='" + root.tint + "' opacity='.65'/><path d='M9 20H28L14 33H9Z' fill='" + Theme.text + "' opacity='.13'/></svg>") : ""
    }
    Icon { anchors.centerIn:parent; anchors.verticalCenterOffset:root.height*.11; width:Math.min(20,root.width*.42);height:width; effectsEnabled:root.effectsEnabled; name:root.emblem; color:root.tint; visible:root.emblem.length>0 }
}
