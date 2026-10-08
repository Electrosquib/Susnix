pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell.Networking
import "../theme"
import "../services"

PanelCard {
    id: root
    readonly property string mode: DesktopService.details
    property var selected: null
    onModeChanged: { selected=null; password.clear(); }
    Connections {
        target:DesktopService.selectedNetwork
        function onConnectionFailed(reason: int): void {
            if (root.mode === "network" && [ConnectionFailReason.NoSecrets,ConnectionFailReason.WifiAuthTimeout].includes(reason)) {
                root.selected=DesktopService.selectedNetwork;
                password.forceActiveFocus();
            }
        }
    }
    Text { x:12; y:12; text:root.mode==="network"?"NETWORK":root.mode==="audio"?"AUDIO DEVICES":"BLUETOOTH"; color:Theme.primary; font {family:Theme.fontFamily;pixelSize:11;letterSpacing:1} }
    PanelButton { anchors.right:parent.right;anchors.rightMargin:10;y:6;text:"Back";onClicked:DesktopService.details="" }
    Text {
        x:12;y:42;width:parent.width-24;wrapMode:Text.Wrap
        text:root.mode==="network" ? DesktopService.wifi ? "Select a network. Saved connections reconnect without a password." : "No Wi-Fi adapter. "+DesktopService.connectedDevices.map(d=>d.name+": connected").join(" • ")
            :root.mode==="audio" ? "Choose your output and microphone." : DesktopService.adapter ? "Connect a paired device or open pairing for new devices." : "No Bluetooth adapter detected."
        color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:10}
    }
    Row {
        x:12;y:82;spacing:6
        PanelButton { visible:root.mode==="network";text:DesktopService.wifiEnabled?"Wi-Fi off":"Wi-Fi on";enabled:DesktopService.wifi!==null;onClicked:DesktopService.toggleWifi() }
        PanelButton { visible:root.mode==="bluetooth";text:DesktopService.bluetoothEnabled?"Turn off":"Turn on";enabled:DesktopService.adapter!==null;onClicked:DesktopService.toggleBluetooth() }
        PanelButton { visible:root.mode==="bluetooth";text:"Pair devices";enabled:DesktopService.adapter!==null;onClicked:DesktopService.connectBluetooth({paired:false}) }
        PanelButton { visible:root.mode==="audio";text:DesktopService.source && DesktopService.source.ready && DesktopService.source.audio.muted?"Unmute mic":"Mute mic";enabled:DesktopService.source!==null && DesktopService.source.ready;onClicked:DesktopService.source.audio.muted=!DesktopService.source.audio.muted }
    }
    ListView {
        id: list
        x:12;y:119;width:parent.width-24;height:Math.max(30,parent.height-y- (root.selected ? 140 : 64));clip:true;spacing:6
        model:root.mode==="network" ? DesktopService.networks : root.mode==="bluetooth" ? DesktopService.bluetoothDevices : DesktopService.outputs.concat(DesktopService.inputs)
        delegate:PanelButton {
            id: row
            required property var modelData
            width:list.width;height:40
            tint:root.mode==="network" ? modelData.connected?Theme.success:Theme.primary : root.mode==="bluetooth" ? modelData.connected?Theme.success:Theme.secondary : (modelData===DesktopService.sink || modelData===DesktopService.source)?Theme.success:Theme.media
            contentItem:Column {
                spacing:3
                Text {width:row.width-12;elide:Text.ElideRight;text:root.mode==="audio"?row.modelData.description || row.modelData.name:row.modelData.name;color:row.tint;font {family:Theme.fontFamily;pixelSize:10} }
                Text {
                    width:row.width-12;elide:Text.ElideRight
                    text:root.mode==="network" ? row.modelData.stateChanging?"Connecting…":row.modelData.connected?"Connected • click to disconnect":Math.round(row.modelData.signalStrength*100)+"% • "+(row.modelData.known?"Saved":WifiSecurityType.toString(row.modelData.security))
                        :root.mode==="bluetooth" ? row.modelData.connected?"Connected • click to disconnect":row.modelData.paired?"Paired • click to connect":"Click to pair"
                        : (row.modelData.isSink?"Output":"Microphone")+((row.modelData===DesktopService.sink || row.modelData===DesktopService.source)?" • selected":"")
                    color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:9}
                }
            }
            onClicked: {
                if(root.mode==="network") {
                    if(modelData.known || modelData.connected || [WifiSecurityType.Open,WifiSecurityType.Owe].includes(modelData.security)) DesktopService.connectNetwork(modelData,"");
                    else {root.selected=modelData; password.forceActiveFocus();}
                } else if(root.mode==="bluetooth") DesktopService.connectBluetooth(modelData);
                else if(modelData.isSink) DesktopService.setOutput(modelData); else DesktopService.setInput(modelData);
            }
        }
        Text { visible:list.count===0;anchors.centerIn:parent;text:root.mode==="audio"?"No audio devices":root.mode==="network"?"No networks found":"No devices found";color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:10} }
        ScrollBar.vertical:ScrollBar { policy:ScrollBar.AsNeeded }
    }
    Column {
        visible:root.selected!==null
        x:12;y:list.y+list.height+8;width:parent.width-24;spacing:6
        Text { width:parent.width;elide:Text.ElideRight;text:root.selected?root.selected.name:"";color:Theme.text;font {family:Theme.fontFamily;pixelSize:10} }
        TextField {
            id:password;width:parent.width;height:30;echoMode:TextInput.Password;placeholderText:"Wi-Fi password"
            color:Theme.text;placeholderTextColor:Theme.textMuted;selectionColor:Theme.primary;font {family:Theme.fontFamily;pixelSize:11}
            background:Rectangle {color:Theme.backgroundRaised;radius:Theme.cornerRadius;border {width:Theme.borderWidth;color:Theme.border} }
            onAccepted:if(connect.enabled) connect.clicked()
        }
        PanelButton { id:connect;text:"Connect";enabled:root.selected!==null && password.text.length>0;onClicked:{DesktopService.connectNetwork(root.selected,password.text);password.clear();root.selected=null;} }
    }
    Text {
        x:12;y:parent.height-52;width:parent.width-24;height:44;wrapMode:Text.Wrap
        text:DesktopService.error || DesktopService.notice
        color:DesktopService.error?Theme.danger:Theme.success;font {family:Theme.fontFamily;pixelSize:10}
    }
}
