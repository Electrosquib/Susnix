import QtQuick
import QtQuick.Controls
import "../theme"
Menu {
    palette.window:Theme.surfaceRaised
    palette.base:Theme.surface
    palette.text:Theme.text
    palette.windowText:Theme.text
    palette.buttonText:Theme.text
    palette.highlight:Qt.alpha(Theme.primary,.18)
    palette.highlightedText:Theme.primary
    background:Rectangle {color:Theme.surfaceRaised;border{width:Theme.borderWidth;color:Qt.alpha(Theme.primary,.4)}radius:Theme.cornerRadius}
}
