import QtQuick
import "../theme"

// Paint only on load, resize or palette changes; no GPU effects or polling.
HiDpiCanvas {
    id: root
    readonly property url artwork: Qt.resolvedUrl("../theme/assets/cityscape.png")
    readonly property var tintColors: [Theme.primary, Theme.secondary, Theme.accent, Theme.text]
    opacity: Theme.opacityBackdrop * (0.5 + 0.5 * Theme.glowStrength)
    renderTarget: Canvas.Image
    renderStrategy: Canvas.Immediate
    Component.onCompleted: loadImage(artwork)
    onImageLoaded: requestPaint()
    onAvailableChanged: if (available) requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onTintColorsChanged: requestPaint()

    SkylinePulse { id: cityLights; width: parent.width * 0.24; height: parent.height }

    onPaint: {
        if (!isImageLoaded(artwork) || width < 1 || height < 1) return;
        const ctx = getContext("2d");
        ctx.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
        ctx.clearRect(0, 0, width, height);
        const left = 0;
        const cityWidth = Math.max(1, Math.round(width * 0.24 * pixelRatio));
        const cityHeight = Math.max(1, Math.round(height * pixelRatio));
        // Read the asset directly: Canvas draw commands are deferred until paint ends.
        const source = ctx.createImageData(artwork.toString());
        // Start inside the first tower so the screen edge is a straight crop.
        const sourceLeft = Math.floor(source.width * 0.16);
        const sourceWidth = source.width - sourceLeft;
        const original = source.data;
        const image = ctx.createImageData(cityWidth, cityHeight);
        const pixels = image.data;
        const windows = [];
        const primary = tintColors[0], secondary = tintColors[1];
        const accent = tintColors[2], neutral = tintColors[3];
        // Crop empty margins and map the original lighting into the active palette.
        for (let y = 0; y < cityHeight; ++y) {
            const sy = Math.min(source.height - 1, Math.floor(104 + (y + 0.5) * 482 / cityHeight));
            for (let x = 0; x < cityWidth; ++x) {
                const sx = Math.min(source.width - 1, sourceLeft + Math.floor((x + 0.5) * sourceWidth / cityWidth));
                const src = (sy * source.width + sx) * 4;
                const dst = (y * cityWidth + x) * 4;
                const red = original[src], green = original[src + 1], blue = original[src + 2];
                const cyan = Math.max(0, green - red);
                const magenta = Math.max(0, red - green);
                const violet = Math.max(0, blue - Math.max(red, green));
                const total = cyan + magenta + violet;
                const brightness = Math.max(red, green, blue);
                pixels[dst] = Math.round(brightness * (total ? (cyan * primary.r + violet * secondary.r + magenta * accent.r) / total : neutral.r));
                pixels[dst + 1] = Math.round(brightness * (total ? (cyan * primary.g + violet * secondary.g + magenta * accent.g) / total : neutral.g));
                pixels[dst + 2] = Math.round(brightness * (total ? (cyan * primary.b + violet * secondary.b + magenta * accent.b) / total : neutral.b));
                pixels[dst + 3] = original[src + 3];
                if (brightness > 140 && original[src+3] > 160 && y > cityHeight*0.3 && x % 6 === 0 && y % 3 === 0) windows.push([x / pixelRatio,y / pixelRatio]);
            }
        }
        cityLights.windows = windows;
        ctx.putImageData(image, left, 0, 0, 0, cityWidth, cityHeight);
    }
}
