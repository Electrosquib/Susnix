import QtQuick
import "../theme"

HiDpiCanvas {
    id: root
    property color tint: Theme.primary
    property real phase: 1
    visible: sweep.running && Theme.glowStrength > 0
    renderTarget: Canvas.Image
    onPhaseChanged: requestPaint()
    function trigger(): void { if (Theme.glowStrength > 0 && Theme.animationFast > 0) sweep.restart(); }
    NumberAnimation {
        id: sweep
        target: root; property: "phase"; from: 0; to: 1
        duration: Theme.animationFast
        easing.type: Easing.OutCubic
    }
    onPaint: {
        const ctx = getContext("2d");
        ctx.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
        ctx.clearRect(0,0,width,height);
        const x = Math.max(0, width * phase);
        ctx.strokeStyle = Qt.alpha(tint, (1 - phase) * Theme.glowStrength);
        ctx.lineWidth = Theme.borderWidth;
        ctx.beginPath(); ctx.moveTo(Math.max(0,x-width*0.35),height-1); ctx.lineTo(x,height-1); ctx.stroke();
    }
}
