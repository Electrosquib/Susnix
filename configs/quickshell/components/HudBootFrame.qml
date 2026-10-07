pragma ComponentBehavior: Bound
import QtQuick
import "../theme"

// Static glass is cached; native edges and a cached shard animate without Canvas repainting.
Item {
    id: root
    property real progress: 1
    property bool poweredRail: false
    readonly property var accents: [Theme.primary, Theme.secondary, Theme.borderWidth,
        Theme.glowStrength, Theme.opacityBorder, Theme.opacityGlow, Theme.text]
    HiDpiCanvas {
        id: glass
        anchors.fill: parent
        opacity: Math.min(1, root.progress*4)
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onAvailableChanged: if (available) requestPaint()
        Connections { target: root; function onAccentsChanged(): void { glass.requestPaint(); } }
        onPaint: {
            const ctx = getContext("2d");
            ctx.setTransform(pixelRatio, 0, 0, pixelRatio, 0, 0);
            ctx.clearRect(0, 0, width, height);
        const inset = Math.max(.5, Theme.borderWidth/2);
        const settled = 1;
        const reflection = ctx.createLinearGradient(0, 0, width, Math.min(height, 42));
        reflection.addColorStop(0, Qt.alpha(Theme.primary, Theme.opacityGlow*Theme.glowStrength*settled));
        reflection.addColorStop(.35, Qt.alpha(Theme.text, Theme.opacityGlow*.4*Theme.glowStrength*settled));
        reflection.addColorStop(.65, Theme.transparent);
        reflection.addColorStop(1, Qt.alpha(Theme.secondary, Theme.opacityGlow*.35*Theme.glowStrength*settled));
        ctx.fillStyle = reflection; ctx.fillRect(inset, inset, width-2*inset, Math.min(20, height-2*inset));
        // Static polished edge: restrained reflection, bright corners, no idle loop.
        const shine = ctx.createLinearGradient(0, 0, width, height);
        shine.addColorStop(0, Qt.alpha(Theme.primary, Theme.opacityBorder*settled));
        shine.addColorStop(.32, Qt.alpha(Theme.border, Theme.opacityBorder*settled));
        shine.addColorStop(.68, Qt.alpha(Theme.secondary, Theme.opacityBorder*settled));
        shine.addColorStop(1, Qt.alpha(Theme.primary, Theme.opacityBorder*settled));
        for (let stroke=3;stroke>=1;stroke--) {
            ctx.lineWidth = Theme.borderWidth+(stroke-1)*2;
            ctx.strokeStyle = stroke===1 ? shine : Qt.alpha(Theme.primary, Theme.opacityGlow*Theme.glowStrength*settled/stroke);
            ctx.strokeRect(inset, inset, width-2*inset, height-2*inset);
        }
        ctx.lineWidth = Math.max(1, Theme.borderWidth);
        ctx.strokeStyle = Qt.alpha(Theme.text, Theme.opacityGlow*3*Theme.glowStrength*settled);
        ctx.beginPath();ctx.moveTo(inset, 12);ctx.lineTo(inset, inset);ctx.lineTo(18, inset);
        ctx.moveTo(width-18, height-inset);ctx.lineTo(width-inset, height-inset);ctx.lineTo(width-inset, height-12);ctx.stroke();
        }
    }
    Item {
        id: construction
        anchors.fill: parent
        visible: root.progress > 0 && root.progress < 1
        readonly property real fade: Math.min(1,(1-root.progress)*5)*Theme.glowStrength
        readonly property real edge: Math.max(1,Theme.borderWidth)
        readonly property real span: Math.min(1,root.progress*3)*width/2
        readonly property real depth: Math.max(0,Math.min(1,(root.progress-.12)*2))*height
        readonly property real lower: Math.max(0,Math.min(1,(root.progress-.5)*3))*width/2
        // Native scene items animate their geometry; cached glass never repaints.
        Rectangle { width:construction.span;height:construction.edge;color:Theme.primary;opacity:construction.fade*Theme.opacityBorder }
        Rectangle { anchors.right:parent.right;width:construction.span;height:construction.edge;color:Theme.secondary;opacity:construction.fade*Theme.opacityBorder }
        Rectangle { width:construction.edge;height:construction.depth;color:Theme.primary;opacity:construction.fade*Theme.opacityBorder }
        Rectangle { anchors.right:parent.right;width:construction.edge;height:construction.depth;color:Theme.secondary;opacity:construction.fade*Theme.opacityBorder }
        Rectangle { anchors.bottom:parent.bottom;width:construction.lower;height:construction.edge;color:Theme.secondary;opacity:construction.fade*Theme.opacityBorder }
        Rectangle { anchors {right:parent.right;bottom:parent.bottom} width:construction.lower;height:construction.edge;color:Theme.primary;opacity:construction.fade*Theme.opacityBorder }
        Rectangle {
            width:parent.width;height:6
            y:Math.min(1,root.progress*1.4)*parent.height-height
            opacity:construction.fade
            gradient:Gradient {
                GradientStop {position:0;color:Theme.transparent}
                GradientStop {position:1;color:Qt.alpha(Theme.primary,Theme.opacityHover)}
            }
        }
        Rectangle {
            visible:root.progress<.72;width:parent.width;height:1
            y:Math.min(1,root.progress*1.4)*parent.height
            color:Theme.primary;opacity:construction.fade*Theme.opacityBorder
        }
        Rectangle {
            visible:root.poweredRail;anchors.right:parent.right
            width:2;height:8;y:Math.min(parent.height-height,root.progress*parent.height)
            color:Theme.text;opacity:construction.fade
        }
        Repeater {
            model:4
            Rectangle {
                required property int index
                x:8+index*8;y:construction.height-3;width:4;height:1
                color:index%2?Theme.secondary:Theme.primary
                opacity:Math.max(0,1-Math.abs(root.progress-(.25+index*.12))*8)*construction.fade
            }
        }
        Rectangle {
            visible:root.progress>.7;anchors.fill:parent;color:Theme.transparent
            border {width:Theme.borderWidth;color:Theme.secondary}
            opacity:construction.fade*.45
        }
    }
    Image {
        // A cached, faceted glass splinter: pointed ends and diagonal fracture lines.
        visible: !root.poweredRail && root.progress > .2 && root.progress < .9
        width: 18; height: Math.min(180, root.height*.8)
        y: (root.height-height)/2
        x: (root.progress-.2)/.7*(root.width+width)-width
        opacity: Math.min(1,(root.progress-.2)*12,(.9-root.progress)*12)*Theme.glowStrength
        sourceSize: Qt.size(36,360)
        source: "data:image/svg+xml,"+encodeURIComponent(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 18 180' fill='none'>"+
            "<path d='M13 1L17 63L8 180L1 102Z' fill='"+Theme.primary+"' fill-opacity='"+Theme.opacityGlow+"'/>"+
            "<path d='M13 1L10 76L1 102M10 76L8 180M10 76L17 63' stroke='"+Theme.secondary+"' stroke-opacity='"+Theme.opacityBorder+"' stroke-width='.7'/>"+
            "<path d='M13 1L17 63L8 180M1 102L5 90M12 128L10 135' stroke='"+Theme.primary+"' stroke-opacity='"+Theme.opacityBorder+"' stroke-width='.8'/>"+
            "<path d='M17 63L10 76L13 101Z' fill='"+Theme.text+"' fill-opacity='"+Theme.opacityGlow+"'/></svg>")
    }
}
