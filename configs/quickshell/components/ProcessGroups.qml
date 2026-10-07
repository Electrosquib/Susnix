pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../theme"
import "../services"
Item {
    id:root
    implicitHeight:232
    property bool choosing:false
    property var processRows:[]
    Component.onCompleted:processRows=ResourceMonitor.sample.processes
    onVisibleChanged:if(visible&&!choosing)processRows=ResourceMonitor.sample.processes
    Connections {
        target:ResourceMonitor
        function onSampleChanged():void {if(root.visible&&!root.choosing)root.processRows=ResourceMonitor.sample.processes;}
    }
    Text {text:"APP GROUP ASSIGNMENTS";color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:9;letterSpacing:.6}}
    Text {y:17;text:"Match by process name • overrides persist";color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:8}}
    ListView {
        x:0;y:36;width:parent.width;height:Math.max(1,parent.height-42);clip:true
        model:root.processRows
        delegate:Item {
            id:row
            required property var modelData
            width:ListView.view.width;height:36
            Text {x:0;y:3;width:parent.width-105;text:row.modelData.name+"  #"+row.modelData.pid;elide:Text.ElideRight;color:Theme.text;font {family:Theme.fontFamily;pixelSize:10}}
            Text {x:0;y:19;text:row.modelData.cpu.toFixed(1)+"% CPU  •  "+ResourceMonitor.bytes(row.modelData.ram)+" RSS";color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:8}}
            ComboBox {
                id:chooser
                objectName:"assignProcess"+row.modelData.pid
                anchors.right:parent.right;width:100;height:28
                enabled:!ResourceMonitor.saving
                model:ResourceMonitor.groups;textRole:"name";valueRole:"id"
                currentIndex:Math.max(0,ResourceMonitor.groups.findIndex(group=>group.id===ResourceMonitor.classify(row.modelData.name)))
                onActivated:ResourceMonitor.assign(row.modelData.name,currentValue)
                font {family:Theme.fontFamily;pixelSize:10}
                background:Rectangle {color:Theme.backgroundRaised;radius:Theme.cornerRadius;border {width:Theme.borderWidth;color:Qt.alpha(Theme.border,Theme.opacityBorder)}}
                contentItem:Text {leftPadding:8;rightPadding:18;text:chooser.displayText;color:Theme.text;verticalAlignment:Text.AlignVCenter;font:chooser.font;elide:Text.ElideRight}
                indicator:Icon {name:"chevron";width:10;height:10;x:parent.width-15;y:9;color:Theme.primary}
                popup:Popup {
                    onOpened:root.choosing=true
                    onClosed:{root.choosing=false;Qt.callLater(()=>root.processRows=ResourceMonitor.sample.processes);}
                    y:parent.height;width:parent.width;implicitHeight:Math.min(contentItem.implicitHeight,200);padding:2
                    background:PanelCard {}
                    contentItem:ListView {clip:true;implicitHeight:contentHeight;model:chooser.popup.visible?chooser.delegateModel:null;currentIndex:chooser.highlightedIndex}
                }
                delegate:ItemDelegate {
                    id:option
                    required property var modelData
                    width:100;height:28
                    contentItem:Text {text:option.modelData.name;color:Theme.text;font {family:Theme.fontFamily;pixelSize:10}}
                    background:Rectangle {color:option.hovered?Qt.alpha(Theme.primary,Theme.opacityHover):Theme.surface}
                }
            }
        }
    }
}
