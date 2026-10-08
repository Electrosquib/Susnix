import QtQuick
import QtQuick.Controls
import "../theme"
Dialog {
    font.family:Theme.fontFamily
    font.pixelSize:11
    background:Rectangle {color:Theme.surfaceRaised;radius:Theme.cornerRadius;border {width:Theme.borderWidth;color:Qt.alpha(Theme.primary,Theme.opacityBorder)}}
    palette.window:Theme.surfaceRaised
    palette.base:Theme.surface
    palette.text:Theme.text
    palette.windowText:Theme.text
    palette.button:Theme.surface
    palette.buttonText:Theme.primary
    palette.highlight:Theme.secondary
    palette.highlightedText:Theme.text
}
