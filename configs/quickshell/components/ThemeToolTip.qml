import QtQuick
import QtQuick.Controls
import "../theme"
ToolTip {
    id:root
    delay:150
    background:PanelCard {border.color:Qt.alpha(Theme.primary,Theme.opacityBorder)}
    contentItem:Text {text:root.text;color:Theme.text;font {family:Theme.fontFamily;pixelSize:10} wrapMode:Text.Wrap}
}
