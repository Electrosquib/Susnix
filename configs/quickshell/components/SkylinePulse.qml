import QtQuick
import "../theme"

// Sparse, bounded light events; the skyline image itself never moves.
HiDpiCanvas {
    id: root
    property var windows: []
    property var litWindows: []
    property real phase: 1
    visible: flash.running && Theme.glowStrength > 0
    renderTarget: Canvas.Image
    onPhaseChanged: requestPaint()
    Timer {
        interval: 8000 + Math.floor(Math.random()*7000)
        running: root.parent.visible && root.parent.opacity > 0
        repeat: true
        onTriggered: {
            interval = 8000 + Math.floor(Math.random()*7000);
            if (Theme.glowStrength <= 0 || !root.windows.length) return;
            root.litWindows = [0,1,2].map(() => root.windows[Math.floor(Math.random()*root.windows.length)]);
            flash.restart();
        }
    }
    NumberAnimation { id: flash; target: root; property: "phase"; from: 0; to: 1; duration: Theme.animationNormal; easing.type: Easing.OutCubic }
    onPaint: {
        const ctx = getContext("2d");
        ctx.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
        ctx.clearRect(0,0,width,height);
        const alpha = Theme.opacityGlow * Theme.glowStrength * (1-phase);
        ctx.fillStyle = Qt.alpha(Theme.primary,alpha);
        for (const point of litWindows) ctx.fillRect(point[0],point[1],2,1);
        if (litWindows.length) {
            ctx.fillStyle = Qt.alpha(Theme.secondary,alpha);
            ctx.fillRect(litWindows[0][0],height*(1-phase),1,height*0.2);
        }
        ctx.fillStyle = Qt.alpha(Theme.primary,alpha);
        ctx.fillRect(width*phase,0,1,height);
    }
}
