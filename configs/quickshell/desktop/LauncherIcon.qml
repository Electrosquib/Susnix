pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import Quickshell
import "../components"
import "../services"
import "../theme"

// Shared browse/search/drag glyph, rasterized at the monitor's pixel density.
Item {
    id:root
    implicitWidth:24;implicitHeight:24
    required property var item
    readonly property bool folder:item.kind==="folder"||!!item.isDir||item.id==="susnix:files"
    readonly property bool themed:!folder&&!!item.icon&&Quickshell.hasThemeIcon(item.icon)
    Image {
        anchors.fill:parent;visible:root.themed
        source:root.themed&&width>0&&height>0?Quickshell.iconPath(root.item.icon):""
        sourceSize:Qt.size(Math.ceil(width*Math.max(2,Window.window?Window.window.devicePixelRatio:1)),Math.ceil(height*Math.max(2,Window.window?Window.window.devicePixelRatio:1)))
        fillMode:Image.PreserveAspectFit;asynchronous:true
    }
    NeonFolder {anchors.fill:parent;visible:root.folder;effectsEnabled:false;tint:root.item.kind==="folder"?Theme.secondary:Theme.primary}
    Icon {
        anchors.fill:parent;visible:!root.folder&&!root.themed;effectsEnabled:false
        name:root.item.kind==="file"?"document":root.item.fallback||root.item.icon||"apps"
        color:LauncherModel.tint(root.item.category||"System")
    }
}
