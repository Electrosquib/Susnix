import QtQuick
import "../theme"

// Static glass reflections and circuit traces, without continuously animated effects.
HiDpiCanvas {
    id: root
    property var settledAccents: []
    property var previousAccents: []
    property real themePhase: 1
    onThemePhaseChanged: requestPaint()
    Component.onCompleted: settledAccents = [Theme.primary, Theme.secondary]
    function updateAccents(): void {
        const colors = [Theme.primary, Theme.secondary];
        if (settledAccents.length && colors.some((color, i) => color.toString() !== settledAccents[i].toString())) {
            previousAccents = settledAccents;
            colorWave.restart();
        }
        settledAccents = colors;
    }
    NumberAnimation { id: colorWave; target: root; property: "themePhase"; from: 0; to: 1; duration: Theme.animationNormal; easing.type: Easing.OutCubic }
    property real bootPhase: 1
    readonly property bool bootActive: ignition.running
    onBootPhaseChanged: requestPaint()
    function powerOn(): void { ignition.restart(); }
    NumberAnimation { id: ignition; target: root; property: "bootPhase"; from: 0; to: 1; duration: Theme.animationDropdown; easing.type: Easing.Linear }
    property real glitchPhase: 1
    readonly property bool glitchActive: glitchBurst.running
    onGlitchPhaseChanged: requestPaint()
    function triggerGlitch(): void {
        if (Theme.glowStrength <= 0 || Theme.animationFast <= 0) return;
        glitchBurst.restart();
    }
    NumberAnimation {
        id: glitchBurst
        target: root; property: "glitchPhase"
        from: 0; to: 1; duration: Theme.animationFast
        easing.type: Easing.OutCubic
    }
    property real reveal: 1
    onRevealChanged: requestPaint()
    property real taskLeft: 0
    property real taskWidth: 0
    property bool taskOpen: false
    onTaskOpenChanged: requestPaint()
    readonly property var style: [Theme.primary, Theme.secondary, Theme.accent, Theme.text,
        Theme.opacityGlow, Theme.opacityBorder, Theme.glowStrength, Theme.borderWidth,
        Theme.background, Theme.opacityPanel, Theme.barSideHeight]
    onStyleChanged: { requestPaint(); Qt.callLater(updateAccents); }
    onTaskLeftChanged: requestPaint()
    onTaskWidthChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onAvailableChanged: if (available) requestPaint()
    renderTarget: Canvas.Image
    onPaint: {
        const ctx = getContext("2d");
        ctx.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
        ctx.clearRect(0, 0, width, height);
        const inset = Math.max(0.5, Theme.borderWidth / 2);
        const sideBottom = Math.max(inset, Theme.barSideHeight * reveal - inset);
        const outerLeft = (taskLeft - 18) * (1 - reveal) + inset * reveal;
        const outerRight = (taskLeft + taskWidth + 18) * (1 - reveal) + (width - inset) * reveal;
        const taskBottom = height - inset;
        // One continuous silhouette: thin sides and the original taller task section.
        ctx.beginPath();
        ctx.moveTo(outerLeft, inset);
        ctx.lineTo(outerRight, inset);
        ctx.lineTo(outerRight, sideBottom);
        ctx.lineTo(taskLeft + taskWidth + 18, sideBottom);
        ctx.lineTo(taskLeft + taskWidth + 3, taskBottom);
        ctx.lineTo(taskLeft - 3, taskBottom);
        ctx.lineTo(taskLeft - 18, sideBottom);
        ctx.lineTo(outerLeft, sideBottom);
        ctx.closePath();
        ctx.fillStyle = Theme.glass;
        ctx.fill();
        const shine = ctx.createLinearGradient(0, 0, 0, height);
        shine.addColorStop(0, Qt.alpha(Theme.secondary, Theme.opacityGlow * Theme.glowStrength * 2));
        shine.addColorStop(0.35, Qt.alpha(Theme.text, Theme.opacityGlow * Theme.glowStrength));
        shine.addColorStop(0.5, Theme.transparent);
        shine.addColorStop(1, Qt.alpha(Theme.primary, Theme.opacityGlow * Theme.glowStrength));
        ctx.fillStyle = shine;
        ctx.fill();
        const edge = ctx.createLinearGradient(0, 0, width, 0);
        const stops = [0, 0.25, 0.5, 1];
        if (colorWave.running) stops.push(Math.max(0.001,themePhase-0.005),Math.min(0.999,themePhase+0.005));
        stops.sort((a,b) => a-b);
        for (const position of stops) {
            const role = position >= 0.4 && position <= 0.6 || position === 0 ? 1 : 0;
            const old = colorWave.running && previousAccents.length && position > themePhase;
            const tint = old ? previousAccents[role] : settledAccents[role] || Theme.primary;
            edge.addColorStop(position, Qt.alpha(tint, Theme.opacityBorder * (old ? Theme.opacityInactive : 1)));
        }
        ctx.strokeStyle = edge;
        ctx.lineWidth = Theme.borderWidth;
        ctx.stroke();

        if (bootActive) {
            const p = bootPhase, fade = Math.min(1, (1-p)*4)*Theme.glowStrength;
            const reach = Math.min(1, p*2)*width/2;
            const light = ctx.createLinearGradient(width/2-reach, 0, width/2+reach, 0);
            light.addColorStop(0, Qt.alpha(Theme.primary, fade));
            light.addColorStop(.5, Qt.alpha(Theme.secondary, fade*.7));
            light.addColorStop(1, Qt.alpha(Theme.primary, fade));
            ctx.strokeStyle = light; ctx.lineWidth = Math.max(1, Theme.borderWidth);
            ctx.beginPath(); ctx.moveTo(width/2-reach, inset); ctx.lineTo(width/2+reach, inset); ctx.stroke();
            // Directional traces and sequential junctions, contained within the silhouette.
            for (let side=-1;side<=1;side+=2) {
                for (let i=0;i<3;i++) {
                    const start = width/2 + side*(taskWidth/2+35+i*30);
                    const lit = Math.max(0, 1-Math.abs(p-(.25+i*.13))*5)*fade*reveal;
                    ctx.strokeStyle = Qt.alpha(i%2 ? Theme.secondary : Theme.primary, lit);
                    ctx.beginPath(); ctx.moveTo(start, sideBottom-2); ctx.lineTo(start+side*8, sideBottom-8);
                    ctx.lineTo(start+side*(8+22*Math.min(1,p*2)), sideBottom-8); ctx.stroke();
                    ctx.fillStyle = Qt.alpha(Theme.primary, lit); ctx.fillRect(start, sideBottom-3, 2, 2);
                }
            }
        }

        if (glitchActive) {
            const points = [[outerLeft,inset], [outerRight,inset], [outerRight,sideBottom],
                [taskLeft+taskWidth+18,sideBottom], [taskLeft+taskWidth+3,taskBottom],
                [taskLeft-3,taskBottom], [taskLeft-18,sideBottom], [outerLeft,sideBottom], [outerLeft,inset]];
            const lengths = points.slice(1).map((point, i) => Math.hypot(point[0]-points[i][0], point[1]-points[i][1]));
            const perimeter = lengths.reduce((sum, length) => sum + length, 0);
            const frame = Math.floor(glitchPhase * 9);
            const strength = (1 - glitchPhase * 0.8) * Theme.glowStrength;
            // Fragments follow the same perimeter, including the task's bevels.
            for (let fragment = 0; fragment < 7; ++fragment) {
                let offset = (glitchPhase * perimeter + fragment * perimeter / 7 + frame * 11) % perimeter;
                let span = 12 + (fragment % 3) * 10;
                ctx.beginPath();
                for (let i = 0; i < lengths.length && span > 0; ++i) {
                    const length = lengths[i];
                    if (length <= 0 || offset >= length) { offset -= length; continue; }
                    const segment = Math.min(span, length - offset);
                    const a = points[i], b = points[i+1];
                    ctx.moveTo(a[0] + (b[0]-a[0])*offset/length, a[1] + (b[1]-a[1])*offset/length);
                    ctx.lineTo(a[0] + (b[0]-a[0])*(offset+segment)/length, a[1] + (b[1]-a[1])*(offset+segment)/length);
                    span -= segment; offset = 0;
                }
                const tint = fragment % 3 === 0 ? Theme.accent : fragment % 3 === 1 ? Theme.primary : Theme.text;
                ctx.strokeStyle = Qt.alpha(tint, strength);
                ctx.lineWidth = Math.max(1, Theme.borderWidth);
                ctx.stroke();
            }
        }

        if (taskOpen) ctx.clearRect(taskLeft + taskWidth / 2 - 4, height - Math.max(1,Theme.borderWidth), 8, Math.max(1,Theme.borderWidth));

        // Sparse etched traces sit under the city, away from status text.
        ctx.strokeStyle = Qt.alpha(Theme.primary, Theme.opacityGlow * Theme.glowStrength * reveal);
        for (let i = 0; reveal > 0 && i < 3; ++i) {
            const start = 145 + i * 24;
            if (start + 36 > taskLeft - 24) break;
            ctx.beginPath();
            ctx.moveTo(start, Theme.barSideHeight - 2);
            ctx.lineTo(start, Theme.barSideHeight - 7 - i * 4);
            ctx.lineTo(start + 12, Theme.barSideHeight - 19 - i * 4);
            ctx.lineTo(start + 36, Theme.barSideHeight - 19 - i * 4);
            ctx.stroke();
            ctx.fillStyle = Qt.alpha(Theme.primary, Theme.opacityBorder * reveal);
            ctx.fillRect(start + 35, Theme.barSideHeight - 20 - i * 4, 2, 2);
        }
    }
}
