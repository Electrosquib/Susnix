pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../theme"

// Six polygonal ring sectors. Paint only on input/theme changes, never at idle.
Popup {
    id: root
    parent: Overlay.overlay
    padding: 0
    width: Math.min(308, parent ? parent.width : 308)
    height: Math.min(308, parent ? parent.height : 308)
    modal: false
    dim: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    property var actions: []
    property var pages: []
    property string heading: "ACTIONS"
    property int activeIndex: -1
    readonly property real radius: Math.min(width, height) / 2 - 6
    readonly property real innerRadius: radius * .32
    signal triggered(string action)

    function showAt(origin: Item, px: real, py: real, entries: var, title: string): void {
        const point = origin.mapToItem(parent, px, py);
        actions = entries; pages = []; heading = title; activeIndex = -1;
        x = Math.max(0, Math.min(parent.width - width, point.x - width / 2));
        y = Math.max(0, Math.min(parent.height - height, point.y - height / 2));
        open();
    }
    function pointAt(angle: real, distance: real): var {
        return {x:width / 2 + Math.cos(angle) * distance, y:height / 2 + Math.sin(angle) * distance};
    }
    function polygon(index: int): var {
        const start = (index * 60 - 120) * Math.PI / 180;
        const end = start + Math.PI / 3;
        const outerA = pointAt(start, radius), outerB = pointAt(end, radius);
        const innerA = pointAt(start, innerRadius), innerB = pointAt(end, innerRadius);
        const trim = .025;
        return [
            {x:outerA.x+(outerB.x-outerA.x)*trim,y:outerA.y+(outerB.y-outerA.y)*trim},
            {x:outerB.x+(outerA.x-outerB.x)*trim,y:outerB.y+(outerA.y-outerB.y)*trim},
            {x:innerB.x+(innerA.x-innerB.x)*trim,y:innerB.y+(innerA.y-innerB.y)*trim},
            {x:innerA.x+(innerB.x-innerA.x)*trim,y:innerA.y+(innerB.y-innerA.y)*trim}
        ];
    }
    function containsPoint(points: var, px: real, py: real): bool {
        let inside = false;
        for (let i=0,j=points.length-1;i<points.length;j=i++) {
            const a=points[i], b=points[j];
            if ((a.y>py)!==(b.y>py) && px<(b.x-a.x)*(py-a.y)/(b.y-a.y)+a.x) inside=!inside;
        }
        return inside;
    }
    function hit(px: real, py: real): int {
        for(let i=0;i<actions.length;i++)if(containsPoint(polygon(i),px,py))return i;
        return -1;
    }
    function activate(index: int): void {
        const entry=actions[index];
        if(!entry || entry.enabled===false)return;
        if(entry.items) {
            pages=pages.concat([{actions:actions,heading:heading}]);
            actions=entry.items;heading=entry.label.toUpperCase();activeIndex=-1;
        } else {close();triggered(entry.action);}
    }
    function back(): void {
        if(!pages.length){close();return;}
        const page=pages[pages.length-1];
        pages=pages.slice(0,-1);actions=page.actions;heading=page.heading;activeIndex=-1;
    }
    onActionsChanged: frame.requestPaint()
    onActiveIndexChanged: frame.requestPaint()
    onOpened: contentItem.forceActiveFocus()
    background: Item {}
    enter: Transition { NumberAnimation {property:"opacity";from:0;to:1;duration:Theme.animationFast;easing.type:Easing.OutCubic} }
    exit: Transition { NumberAnimation {property:"opacity";from:1;to:0;duration:Theme.animationFast;easing.type:Easing.OutCubic} }
    contentItem: Item {
        id: surface
        focus: true
        Keys.onEscapePressed: root.close()
        Keys.onLeftPressed: root.activeIndex=(root.activeIndex+5)%root.actions.length
        Keys.onRightPressed: root.activeIndex=(root.activeIndex+1)%root.actions.length
        Keys.onReturnPressed: root.activate(root.activeIndex)
        Keys.onPressed: event=> {
            if(event.key>=Qt.Key_1 && event.key<=Qt.Key_6){root.activate(event.key-Qt.Key_1);event.accepted=true;}
            else if(event.key===Qt.Key_Backspace){root.back();event.accepted=true;}
        }
        Canvas {
            id: frame
            anchors.fill: parent
            readonly property color fillColor: Theme.surface
            readonly property color raisedColor: Theme.surfaceRaised
            readonly property color edgeColor: Theme.primary
            readonly property color idleColor: Theme.border
            onFillColorChanged: requestPaint()
            onRaisedColorChanged: requestPaint()
            onEdgeColorChanged: requestPaint()
            onIdleColorChanged: requestPaint()
            onPaint: {
                const ctx=getContext("2d");ctx.reset();ctx.clearRect(0,0,width,height);
                for(let i=0;i<root.actions.length;i++){
                    const entry=root.actions[i], points=root.polygon(i);
                    const active=i===root.activeIndex && entry.enabled!==false;
                    const tint=entry.danger?Theme.danger:Theme.primary;
                    ctx.beginPath();ctx.moveTo(points[0].x,points[0].y);
                    for(let j=1;j<points.length;j++)ctx.lineTo(points[j].x,points[j].y);
                    ctx.closePath();
                    const gradient=ctx.createLinearGradient(0,0,0,height);
                    gradient.addColorStop(0,Qt.alpha(Theme.surfaceRaised,.98));
                    gradient.addColorStop(1,Qt.alpha(Theme.background,.97));
                    ctx.fillStyle=gradient;ctx.fill();
                    if(active){ctx.fillStyle=Qt.alpha(tint,Theme.opacityHover);ctx.fill();}
                    ctx.lineWidth=Theme.borderWidth;
                    ctx.strokeStyle=Qt.alpha(active?tint:Theme.border,active?.95:.75);ctx.stroke();
                    // One bright outer edge, with no animated shadows.
                    ctx.beginPath();ctx.moveTo(points[0].x,points[0].y);ctx.lineTo(points[1].x,points[1].y);
                    ctx.strokeStyle=Qt.alpha(tint,active?.95:.38);ctx.stroke();
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: root.activeIndex>=0 && root.actions[root.activeIndex].enabled!==false ? Qt.PointingHandCursor : Qt.ArrowCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onPositionChanged: mouse=>root.activeIndex=root.hit(mouse.x,mouse.y)
            onExited: root.activeIndex=-1
            onClicked: mouse=> {
                if(mouse.button===Qt.RightButton){root.back();return;}
                const index=root.hit(mouse.x,mouse.y);
                if(index>=0)root.activate(index);
                else if(Math.hypot(mouse.x-width/2,mouse.y-height/2)<root.innerRadius)root.back();
                else root.close();
            }
        }
        Repeater {
            model: root.actions
            delegate: Item {
                id: label
                required property int index
                required property var modelData
                readonly property var position: root.pointAt((index*60-90)*Math.PI/180,root.radius*.66)
                x: position.x-width/2;y:position.y-height/2
                width: 76;height: 52
                opacity: modelData.enabled===false?Theme.opacityDisabled:1
                Accessible.role: Accessible.MenuItem
                Accessible.name: modelData.label
                Accessible.onPressAction: root.activate(label.index)
                Column {
                    anchors.centerIn:parent;spacing:5
                    Icon {anchors.horizontalCenter:parent.horizontalCenter;width:20;height:20;name:label.modelData.icon||"controls";effectsEnabled:false;color:label.modelData.danger?Theme.danger:root.activeIndex===label.index?Theme.primary:Theme.textMuted}
                    Text {anchors.horizontalCenter:parent.horizontalCenter;text:label.modelData.label;color:root.activeIndex===label.index?Theme.text:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:10}}
                }
            }
        }
        Column {
            anchors.centerIn:parent;spacing:4
            Text {anchors.horizontalCenter:parent.horizontalCenter;text:root.pages.length?"‹":"×";color:Theme.primary;font{family:Theme.fontFamily;pixelSize:20}}
            Text {anchors.horizontalCenter:parent.horizontalCenter;text:root.pages.length?"BACK":"CLOSE";color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:8;letterSpacing:1}}
        }
    }
}
