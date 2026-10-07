import QtQuick
import QtQuick.Window

// Canvas uses physical pixels; callers draw logical coordinates with pixelRatio.
Canvas {
    readonly property real pixelRatio: Math.max(1, Window.window ? Window.window.devicePixelRatio : 1)
    canvasSize: Qt.size(Math.max(1, Math.ceil(width * pixelRatio)), Math.max(1, Math.ceil(height * pixelRatio)))
    canvasWindow: Qt.rect(0, 0, canvasSize.width, canvasSize.height)
    onPixelRatioChanged: requestPaint()
}
