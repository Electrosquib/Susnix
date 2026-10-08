pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../theme"
Item {
    id:root
    implicitWidth:90;implicitHeight:26
    signal closeRequested()
    signal minimizeRequested()
    signal maximizeRequested()
    HiDpiCanvas {
        id:frame;anchors.fill:parent
        onPaint:{
            const ctx=getContext("2d");ctx.reset();ctx.scale(pixelRatio,pixelRatio);
            ctx.beginPath();ctx.moveTo(9,1);ctx.lineTo(width-16,1);ctx.lineTo(width-1,height-1);ctx.lineTo(1,height-1);ctx.lineTo(1,9);ctx.closePath();
            ctx.fillStyle=Qt.alpha(Theme.surfaceRaised,.4);ctx.fill();
            const edge=ctx.createLinearGradient(0,0,width,0);edge.addColorStop(0,Qt.alpha(Theme.primary,.8));edge.addColorStop(1,Qt.alpha(Theme.secondary,.5));ctx.strokeStyle=edge;ctx.lineWidth=1;ctx.stroke();
        }
        Connections {target:Theme;function onPrimaryChanged(): void {frame.requestPaint();}function onSecondaryChanged(): void {frame.requestPaint();}function onSurfaceRaisedChanged(): void {frame.requestPaint();}}
    }
    Row {
        anchors {left:parent.left;leftMargin:5;verticalCenter:parent.verticalCenter}spacing:2
        Repeater {
            model:[{glyph:"×",name:"Close",action:"close"},{glyph:"−",name:"Minimize",action:"minimize"},{glyph:"□",name:"Maximize / restore",action:"maximize"}]
            delegate:AbstractButton {
                id:control
                required property var modelData
                width:23;height:22;hoverEnabled:true
                Accessible.name:modelData.name
                onClicked:{if(modelData.action==="close")root.closeRequested();else if(modelData.action==="minimize")root.minimizeRequested();else root.maximizeRequested();}
                background:Rectangle {color:control.hovered?Qt.alpha(Theme.primary,.1):Theme.transparent;radius:2}
                contentItem:Text {text:control.modelData.glyph;color:control.modelData.action==="close"?Theme.accent:Theme.primary;font {family:Theme.fontFamily;pixelSize:17}horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter}
                ThemeToolTip {visible:control.hovered;delay:400;text:control.Accessible.name}
            }
        }
    }
}
