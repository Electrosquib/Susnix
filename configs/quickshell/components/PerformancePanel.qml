pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../services"
PanelCard {
    id:root
    property bool fitMode:false
    property bool monitoring:true
    implicitHeight:content.height+24
    Column {
        id:content;objectName:"performanceContent";x:root.fitMode?8:12;y:root.fitMode?8:12;width:parent.width-2*x;spacing:root.fitMode?4:8
        Item {
            id: statsHeader
            width:parent.width;height:18
            Text {text:"SYSTEM PERFORMANCE";color:Theme.text;font {family:Theme.fontFamily;pixelSize:10;letterSpacing:.9;bold:true}}
            Text {anchors.right:parent.right;anchors.rightMargin:root.fitMode?85:0;text:ResourceMonitor.ready?"LIVE ●":"WAITING";color:ResourceMonitor.ready?Theme.success:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:9}}
            Row {
                visible:root.fitMode
                anchors.right:parent.right
                spacing:2
                Repeater {model:[1,10,60];delegate:PanelButton {required property int modelData;text:modelData+"m";tint:graph.minutes===modelData?Theme.primary:Theme.textMuted;implicitWidth:24;implicitHeight:16;onClicked:graph.minutes=modelData}}
            }
        }
        Row {
            id: metricLegend
            spacing:6
            Repeater {
                model:[{id:"cpu",name:"CPU",color:Theme.primary},{id:"gpu",name:"GPU",color:Theme.secondary},{id:"ram",name:"RAM",color:Theme.dev},{id:"disk",name:"Disk",color:Theme.media},{id:"network",name:"Net",color:Theme.ai}]
                delegate:PanelButton {
                    required property var modelData
                    required property int index
                    opacity: Math.max(0, Math.min(1, (root.initialization-.3-index*.04)/.2))
                    text:(graph.enabledMetrics.includes(modelData.id)?"● ":"○ ")+modelData.name
                    tint:modelData.color;implicitHeight:root.fitMode?18:22;implicitWidth:Math.max(32,contentItem.implicitWidth+8)
                    onClicked:graph.enabledMetrics=graph.enabledMetrics.includes(modelData.id)?graph.enabledMetrics.filter(key=>key!==modelData.id):graph.enabledMetrics.concat([modelData.id])
                    Accessible.name:"Toggle "+modelData.name+" graph"
                }
            }
        }
        Row {
            visible:!root.fitMode
            spacing:4
            Repeater {model:[1,10,60];delegate:PanelButton {required property int modelData;text:modelData+"m";tint:graph.minutes===modelData?Theme.primary:Theme.textMuted;implicitHeight:20;onClicked:graph.minutes=modelData}}
            Text {text:"  history since shell start";color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:8} anchors.verticalCenter:parent.verticalCenter}
        }
        ResourceGraph {active:root.monitoring;traceProgress: Math.max(0, Math.min(1, (root.initialization-.35)/.6)); id:graph;objectName:"performanceGraph";width:parent.width;height:root.fitMode?Math.max(20,Math.min(90,root.height-2*content.y-statsHeader.height-metricLegend.height-resourceRows.height-groupLegend.height-measurementNotes.height-5*content.spacing)):178}
        Column {
            id: resourceRows
            width:parent.width;spacing:root.fitMode?2:3
            ResourceBreakdown {width:parent.width;height:root.fitMode?18:24;chargeProgress: Math.max(0, Math.min(1, (root.initialization-0.4)/.35)); metric:"cpu";label:"CPU";value:ResourceMonitor.sample.cpu<0?"—":ResourceMonitor.sample.cpu.toFixed(0)+"%";utilization:ResourceMonitor.sample.cpu}
            ResourceBreakdown {width:parent.width;height:root.fitMode?18:24;chargeProgress: Math.max(0, Math.min(1, (root.initialization-0.44)/.35)); metric:"gpu";label:"GPU";value:SystemStats.gpuUsage<0?(SystemStats.gpuStatus==="virtual"?"VM / no data":"No data"):SystemStats.gpuUsage+"%";utilization:SystemStats.gpuUsage}
            ResourceBreakdown {width:parent.width;height:root.fitMode?18:24;chargeProgress: Math.max(0, Math.min(1, (root.initialization-0.48)/.35)); metric:"ram";label:"RAM";value:ResourceMonitor.bytes(ResourceMonitor.sample.memUsed);utilization:ResourceMonitor.sample.ram}
            ResourceBreakdown {width:parent.width;height:root.fitMode?18:24;chargeProgress: Math.max(0, Math.min(1, (root.initialization-0.52)/.35)); metric:"disk";label:"Disk";value:ResourceMonitor.bytes(ResourceMonitor.sample.diskRate)+"/s";utilization:ResourceMonitor.sample.disk}
            ResourceBreakdown {width:parent.width;height:root.fitMode?18:24;chargeProgress: Math.max(0, Math.min(1, (root.initialization-0.56)/.35)); metric:"network";label:"Network";value:ResourceMonitor.bytes(ResourceMonitor.sample.network)+"/s";utilization:ResourceMonitor.sample.network/graph.networkPeak*100}
        }
        Flow {
            id: groupLegend
            width:parent.width;spacing:6
            Repeater {
                model:ResourceMonitor.groups
                delegate:Text {required property var modelData;text:"● "+modelData.name;color:Theme.categoryColor(modelData.category);font {family:Theme.fontFamily;pixelSize:9}}
            }
            Text {text:"● Unattributed";color:Theme.system;font {family:Theme.fontFamily;pixelSize:9}}
        }
        Text {id:measurementNotes;width:parent.width;text:"Disk colors: I/O share\nNetwork: total only · GPU: provider-dependent";color:Theme.textMuted;wrapMode:Text.WordWrap;font {family:Theme.fontFamily;pixelSize:8}}
        Text {visible:ResourceMonitor.error.length>0;width:parent.width;text:ResourceMonitor.error;color:Theme.warning;wrapMode:Text.WordWrap;font {family:Theme.fontFamily;pixelSize:9}}
    }
}
