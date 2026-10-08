import QtQuick
import QtQuick.Controls
import "../theme"
Dialog {
    palette.window:Theme.surfaceRaised
    palette.base:Theme.surface
    palette.text:Theme.text
    palette.windowText:Theme.text
    palette.button:Theme.surface
    palette.buttonText:Theme.primary
    palette.highlight:Theme.secondary
    palette.highlightedText:Theme.text
}
