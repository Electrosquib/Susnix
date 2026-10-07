import QtQuick
import "../theme"
import "../services"
Item {
    id: root
    property real traceProgress: 1
    onTraceProgressChanged: plot.requestPaint()
    property int minutes: 10
    readonly property bool compact:height<110
    property var enabledMetrics: ["cpu","gpu","ram","disk","network"]
    readonly property var points: ResourceMonitor.history.filter(point=>point.time>=Date.now()-minutes*60000)
    property var previousPoints: []
    property var nextPoints: []
    property real refreshProgress: 1
    readonly property var renderedPoints: nextPoints.map((point, index) => {
        const old = previousPoints[index] || point;
        const result = {time: old.time+(point.time-old.time)*refreshProgress};
        for (const metric of metrics) {
            result[metric] = old[metric] < 0 || point[metric] < 0 ? point[metric] : old[metric]+(point[metric]-old[metric])*refreshProgress;
        }
        return result;
    })
    readonly property real networkPeak: Math.max(1024,...renderedPoints.map(point=>point.network))
    function refreshGraph(): void {
        const current = renderedPoints;
        const byTime = new Map(current.map(point=>[point.time, point]));
        const last = current.length ? current[current.length-1] : null;
        previousPoints = points.map(point=>byTime.get(point.time) || (last && point.time>last.time ? last : point));
        nextPoints = points;
        if (current.length) refresh.restart(); else refreshProgress=1;
    }
    NumberAnimation { id: refresh; target: root; property: "refreshProgress"; from: 0; to: 1; duration: Theme.animationNormal; easing.type: Easing.OutCubic }
    onRefreshProgressChanged: plot.requestPaint()
    onRenderedPointsChanged: plot.requestPaint()
    readonly property var styles: [Theme.primary,Theme.secondary,Theme.dev,Theme.media,Theme.ai,Theme.border,Theme.textMuted]
    readonly property var metrics: ["cpu","gpu","ram","disk","network"]
    property int hoverIndex:-1
    implicitHeight:178
    onPointsChanged: { if (hoverIndex >= points.length) hoverIndex = -1; Qt.callLater(refreshGraph); }
    onEnabledMetricsChanged: plot.requestPaint()
    onStylesChanged: plot.requestPaint()
    Column {
        x:0;y:6;height:136;spacing:Math.max(1,(plot.height-24)/2)
        Repeater {model:["100%","50%","0%"];delegate:Text {required property string modelData;text:modelData;color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:8}}}
    }
    HiDpiCanvas {
        id:plot;x:33;y:8;width:Math.max(1,parent.width-38);height:Math.max(20,root.height-(root.compact?34:46))
        onWidthChanged:requestPaint()
        onHeightChanged:requestPaint()
        onPaint: {
            const ctx=getContext("2d");ctx.setTransform(pixelRatio,0,0,pixelRatio,0,0);ctx.clearRect(0,0,width,height);
            ctx.strokeStyle=Qt.alpha(Theme.border,Theme.opacityBorder);ctx.lineWidth=1;
            for(let i=0;i<=4;i++){ctx.beginPath();ctx.moveTo(0,i*height/4);ctx.lineTo(width,i*height/4);ctx.stroke();ctx.beginPath();ctx.moveTo(i*width/4,0);ctx.lineTo(i*width/4,height);ctx.stroke();}
            if(root.renderedPoints.length<2)return;
            ctx.save();ctx.beginPath();ctx.rect(0,0,width*root.traceProgress,height);ctx.clip();
            const last=root.renderedPoints[root.renderedPoints.length-1].time,first=last-root.minutes*60000;
            for(let line=0;line<root.metrics.length;line++) {
                const key=root.metrics[line];if(!root.enabledMetrics.includes(key))continue;
                ctx.strokeStyle=root.styles[line];ctx.lineWidth=1.3;ctx.beginPath();let started=false;
                for(const point of root.renderedPoints) {
                    const value=key==="network" ? point.network/root.networkPeak*100 : point[key];
                    if(value<0){started=false;continue;}
                    const x=(point.time-first)/(last-first)*width,y=height*(1-Math.max(0,Math.min(100,value))/100);
                    if(started)ctx.lineTo(x,y);else ctx.moveTo(x,y);started=true;
                }
                ctx.stroke();
            }
            ctx.restore();
        }
        HoverHandler {
            id: hover
            onPointChanged: {
                if(root.points.length<1)return;
                const last=root.points[root.points.length-1].time,target=last-root.minutes*60000*(1-point.position.x/plot.width);
                root.hoverIndex=root.points.reduce((best,p,i)=>Math.abs(p.time-target)<Math.abs(root.points[best].time-target)?i:best,0);
            }
            onHoveredChanged:if(!hovered)root.hoverIndex=-1
        }
        Rectangle {
            visible:root.hoverIndex>=0
            width:1;height:parent.height;color:Qt.alpha(Theme.text,Theme.opacityBorder)
            x:root.hoverIndex>=0 ? Math.max(0,Math.min(parent.width, (root.points[root.hoverIndex].time-root.points[root.points.length-1].time+root.minutes*60000)/(root.minutes*60000)*parent.width)) : 0
        }
        ThemeToolTip {
        visible:hover.hovered && root.hoverIndex>=0
        text: {
            if(root.hoverIndex<0 || !root.points[root.hoverIndex])return "";
            const p=root.points[root.hoverIndex];return Qt.formatDateTime(new Date(p.time),"HH:mm:ss")+"\nCPU "+(p.cpu<0?"—":p.cpu.toFixed(0)+"%")+" • GPU "+(p.gpu<0?"—":p.gpu.toFixed(0)+"%")+"\nRAM "+p.ram.toFixed(0)+"% • Disk "+(p.disk<0?"—":p.disk.toFixed(0)+"%")+"\nNetwork "+ResourceMonitor.bytes(p.network)+"/s";
        }
        }
    }
    Text {x:33;y:root.height-(root.compact?25:33);text:root.minutes+"m ago";color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:8}}
    Text {anchors.right:parent.right;y:root.height-(root.compact?25:33);text:"Now";color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:8}}
    Text {x:33;y:root.height-12;text:root.points.length<2?"Collecting live samples…":"Network scale: "+ResourceMonitor.bytes(root.networkPeak)+"/s";color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:8}}
}
