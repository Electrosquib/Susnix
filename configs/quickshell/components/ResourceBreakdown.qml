pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../services"
Item {
    id: root
    required property string metric
    required property string label
    required property string value
    required property real utilization
    property real chargeProgress: 1
    property var segments: ResourceMonitor.segments(metric)
    implicitHeight:24
    Text { x:0;anchors.verticalCenter:parent.verticalCenter;text:root.label;color:Theme.text;font {family:Theme.fontFamily;pixelSize:10} }
    Rectangle {
        id: track
        x:55;y:(root.height-height)/2;width:Math.max(1,parent.width-139);height:14
        color:Theme.backgroundRaised;radius:2
        border {width:Theme.borderWidth;color:Qt.alpha(Theme.border,Theme.opacityBorder)}
        Item {
            x:1;y:1;width:(track.width-2)*root.chargeProgress*Math.max(0,Math.min(1,root.utilization/100));height:track.height-2
            Row {
                anchors.fill:parent
                Repeater {
                    model:root.segments.length ? root.segments : [{name:"Unattributed",category:"unattributed",fraction:1}]
                    delegate:Rectangle {
                        id:segment
                        required property var modelData
                        width:parent.width*modelData.fraction;height:parent.height
                        color:modelData.category==="unattributed" ? Qt.alpha(Theme.system,Theme.opacityInactive) : Theme.categoryColor(modelData.category)
                        HoverHandler { id:hover }
                        ThemeToolTip {visible:hover.hovered;text:segment.modelData.name+" • "+Math.round(segment.modelData.fraction*100)+"% of observed "+root.label}
                    }
                }
            }
        }
    }
    Text { anchors {right:parent.right;verticalCenter:parent.verticalCenter} text:root.value;color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:10} }
}
