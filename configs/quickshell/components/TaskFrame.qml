import QtQuick
import "../theme"

// Borderless gradient glass inside the bar's single outer outline.
HiDpiCanvas {
    id: root
    property color categoryColor: Theme.dev
    property bool hovered: false
    readonly property var style: [categoryColor, hovered, Theme.secondary, Theme.text,
        Theme.surface, Theme.surfaceRaised, Theme.opacityGlass, Theme.opacityHover,
        Theme.opacityBorder, Theme.opacityGlow, Theme.glowStrength, Theme.borderWidth]
    onStyleChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onAvailableChanged: if (available) requestPaint()
    renderTarget: Canvas.Image
    onPaint: {
        if (width < 1 || height < 1) return;
        const ctx = getContext("2d");
        ctx.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
        ctx.clearRect(0, 0, width, height);
        const inset = Math.max(0.5, Theme.borderWidth / 2);
        const right = width - inset, bottom = height - inset;
        const cut = Math.min(7, height / 3);
        ctx.beginPath();
        ctx.moveTo(cut, inset); ctx.lineTo(right, inset);
        ctx.lineTo(right, bottom - cut); ctx.lineTo(right - cut, bottom);
        ctx.lineTo(inset, bottom); ctx.lineTo(inset, cut); ctx.closePath();
        const glass = ctx.createLinearGradient(0, 0, 0, height);
        glass.addColorStop(0, Qt.alpha(Theme.surfaceRaised, Theme.opacityGlass));
        glass.addColorStop(0.48, Qt.alpha(Theme.surface, Theme.opacityGlass));
        glass.addColorStop(1, Qt.alpha(categoryColor, hovered ? Theme.opacityHover * 2 : Theme.opacityHover));
        ctx.fillStyle = glass; ctx.fill();
        // A fine reflection and segmented terminals give the glass an etched finish.
        const reflection = ctx.createLinearGradient(0, 0, width, 0);
        reflection.addColorStop(0, Qt.alpha(categoryColor, Theme.opacityGlow));
        reflection.addColorStop(0.35, Qt.alpha(Theme.text, Theme.opacityGlow * Theme.glowStrength * 2));
        reflection.addColorStop(1, Theme.transparent);
        ctx.fillStyle = reflection; ctx.fillRect(cut + 3, inset + 1, width - cut - 7, 1);
        ctx.fillStyle = Qt.alpha(categoryColor, Theme.opacityBorder);
        ctx.fillRect(2, height / 2 - 2, 1, 4);
        ctx.fillStyle = Qt.alpha(Theme.secondary, Theme.opacityBorder);
        ctx.fillRect(width - 3, height / 2 - 2, 1, 4);
    }
}
