pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"

Item {
    id:root
    required property var item
    property bool draggable:true
    signal activated(var item)
    signal contextRequested(var item,var position)
    signal appDropped(string sourceId,var target)
    width:116;height:102
    activeFocusOnTab:true
    Accessible.name:item.name
    Accessible.role:Accessible.Button
    Keys.onReturnPressed:activated(item)
    Keys.onSpacePressed:activated(item)
    Keys.onMenuPressed:contextRequested(item,root.mapToItem(null,0,height))
    Rectangle {
        anchors.fill:parent;anchors.margins:3;radius:Theme.cornerRadius+4
        color:drop.containsDrag?Qt.alpha(Theme.primary,.13):mouse.containsMouse||root.activeFocus?Qt.alpha(Theme.surfaceRaised,.75):Theme.transparent
        border{width:Theme.borderWidth;color:drop.containsDrag?Theme.primary:mouse.containsMouse||root.activeFocus?Qt.alpha(Theme.primary,.4):Theme.transparent}
    }
    Item {
        id:glyph;anchors.horizontalCenter:parent.horizontalCenter;y:12;width:42;height:42
        LauncherIcon {anchors.fill:parent;item:root.item}
        Rectangle {visible:root.item.kind==="folder";anchors{right:parent.right;bottom:parent.bottom}width:20;height:16;radius:3;color:Theme.surfaceRaised;Text{anchors.centerIn:parent;text:root.item.folder?root.item.folder.apps.length:"";color:Theme.primary;font{family:Theme.fontFamily;pixelSize:9}}}
    }
    Text {x:5;y:64;width:parent.width-10;text:root.item.name;color:Theme.text;font{family:Theme.fontFamily;pixelSize:11}horizontalAlignment:Text.AlignHCenter;elide:Text.ElideRight}
    Text {x:5;y:82;width:parent.width-10;text:root.item.kind==="file"?(root.item.isDir?"Folder":"File"):root.item.kind==="folder"?"App folder":root.item.category;color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:9}horizontalAlignment:Text.AlignHCenter;elide:Text.ElideRight}
    Item {
        id:dragGhost;width:root.width;height:root.height;z:20;visible:mouse.drag.active
        Drag.active:mouse.drag.active
        Drag.source:root
        Drag.keys:["susnix-app"]
        Drag.hotSpot.x:width/2;Drag.hotSpot.y:height/2
        Rectangle {anchors.fill:parent;radius:Theme.cornerRadius;color:Qt.alpha(Theme.surfaceRaised,.9);border{width:1;color:Theme.primary}}
        LauncherIcon {anchors.centerIn:parent;width:36;height:36;item:root.item}
    }
    MouseArea {
        id:mouse;anchors.fill:parent;hoverEnabled:true;acceptedButtons:Qt.LeftButton|Qt.RightButton
        drag.target:root.draggable&&root.item.kind==="app"&&pressedButtons===Qt.LeftButton?dragGhost:null
        onClicked:event=>{root.forceActiveFocus();if(event.button===Qt.RightButton)root.contextRequested(root.item,mouse.mapToItem(null,event.x,event.y));else root.activated(root.item);}
        onReleased:{if(drag.active)dragGhost.Drag.drop();dragGhost.x=0;dragGhost.y=0;}
        onCanceled:{dragGhost.Drag.cancel();dragGhost.x=0;dragGhost.y=0;}
    }
    ThemeToolTip {visible:mouse.containsMouse&&!mouse.drag.active;text:root.item.path||root.item.name;delay:600}
    DropArea {
        id:drop;anchors.fill:parent;keys:["susnix-app"]
        onDropped:event=>{const source=event.source as LauncherTile;if(source&&source.item.kind==="app"){root.appDropped(source.item.id,root.item);event.acceptProposedAction();}}
    }
}
