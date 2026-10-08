pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../services"

PanelCard {
    id: root
    signal sessionRequested(string action)
    property bool compact:false
    implicitHeight:compact?140:176
    Text { visible:!root.compact;x:12; y:8; text:"DEVICE CONTROLS"; color:Theme.text; font { family:Theme.fontFamily;pixelSize:10;letterSpacing:1 } }
    component DeviceTile: Item {
        id: tile
        property string title: ""
        property string subtitle: ""
        property string icon: ""
        property bool powered: false
        property bool available: false
        signal openRequested()
        signal toggleRequested()
        PanelButton {
            anchors.fill: parent
            onClicked: tile.openRequested()
            Accessible.name: tile.title+" settings"
            contentItem: Item {
                Icon { x:8; y:12; width:18; height:18; name:tile.icon; color:tile.powered?Theme.primary:Theme.textMuted }
                Text { x:33; y:5; text:tile.title; color:Theme.text; font {family:Theme.fontFamily;pixelSize:10} }
                Text { x:33; y:21; width:parent.width-40; text:tile.subtitle; elide:Text.ElideRight; color:Theme.textMuted; font {family:Theme.fontFamily;pixelSize:8} }
            }
        }
        PanelButton { anchors.right:parent.right; anchors.rightMargin:5; y:3; width:28; height:18; text:tile.available?(tile.powered?"ON":"OFF"):"—"; enabled:tile.available; onClicked:tile.toggleRequested(); Accessible.name:"Toggle "+tile.title }
    }
    Row {
        x:10; y:root.compact?8:28; width:parent.width-20; spacing:6
        DeviceTile {
            width:(parent.width-parent.spacing)/2; height:root.compact?34:42
            title:DesktopService.wifi?"Wi-Fi":SystemStats.network==="Wired"?"Ethernet":"Network"; icon:DesktopService.wifi?"wifi":"network"; powered:DesktopService.wifi?DesktopService.wifiEnabled:SystemStats.network==="Wired"; available:DesktopService.wifi!==null
            subtitle:DesktopService.wifi ? DesktopService.wifiEnabled ? (DesktopService.networks.find(n=>n.connected)?.name || "Disconnected") : "Off" : SystemStats.network === "Wired" ? "Wired connection" : "No Wi-Fi adapter"
            onOpenRequested:DesktopService.details="network"
            onToggleRequested:DesktopService.toggleWifi()
        }
        DeviceTile {
            width:(parent.width-parent.spacing)/2; height:root.compact?34:42
            title:"Bluetooth"; icon:"bluetooth"; powered:DesktopService.bluetoothEnabled; available:DesktopService.adapter!==null
            subtitle:DesktopService.adapter ? DesktopService.bluetoothEnabled ? (DesktopService.bluetoothDevices.find(d=>d.connected)?.name || "Not connected") : "Off" : "No adapter"
            onOpenRequested:DesktopService.details="bluetooth"
            onToggleRequested:DesktopService.toggleBluetooth()
        }
    }
    PanelButton {
        x:10; y:root.compact?46:77; width:26; height:26; enabled:DesktopService.audioReady
        Accessible.name:DesktopService.muted?"Unmute audio":"Mute audio"
        contentItem:Icon {name:DesktopService.muted?"muted":"audio";color:Theme.media}
        onClicked:DesktopService.toggleMute()
    }
    ControlSlider {
        x:43; y:root.compact?45:76; width:parent.width-128; value:Math.max(0,DesktopService.volume); tint:Theme.media
        enabled:DesktopService.audioReady; Accessible.name:"Output volume"
        onMoved:DesktopService.setVolume(value)
    }
    Text { x:parent.width-82; y:root.compact?53:84; width:35; horizontalAlignment:Text.AlignRight; text:DesktopService.audioReady?Math.round(DesktopService.volume)+"%":"N/A"; color:Theme.text; font {family:Theme.fontFamily;pixelSize:9} }
    PanelButton { anchors.right:parent.right; anchors.rightMargin:10; y:root.compact?47:78; width:32; height:24; text:"…"; onClicked:DesktopService.details="audio"; Accessible.name:"Choose audio devices" }
    Icon { x:15; y:root.compact?82:112; name:"brightness"; color:Theme.warning }
    ControlSlider {
        id: brightness
        x:43; y:root.compact?76:106; width:parent.width-98; from:1; value:Math.max(1,DesktopService.brightness); tint:Theme.warning
        enabled:DesktopService.brightness>=0 && !DesktopService.busy; Accessible.name:"Screen brightness"
        onMoved:if(!pressed) DesktopService.run(["brightness",Math.round(value).toString()])
        onPressedChanged:if(!pressed && enabled) DesktopService.run(["brightness",Math.round(value).toString()])
    }
    Text { anchors.right:parent.right; anchors.rightMargin:12; y:root.compact?84:114; text:DesktopService.brightness>=0?Math.round(DesktopService.brightness)+"%":"N/A"; color:Theme.textMuted; font {family:Theme.fontFamily;pixelSize:9} }
    Row {
        x:10; y:root.compact?108:143; width:parent.width-20; spacing:5
        Repeater {
            model:[{id:"lock",name:"Lock"},{id:"logout",name:"Log out"},{id:"reboot",name:"Restart"},{id:"poweroff",name:"Power"}]
            delegate:PanelButton {
                required property var modelData
                width:(root.width-35)/4; height:25; text:modelData.name
                tint:modelData.id==="poweroff"?Theme.danger:Theme.primary
                enabled:!DesktopService.busy
                onClicked:root.sessionRequested(modelData.id)
            }
        }
    }
}
