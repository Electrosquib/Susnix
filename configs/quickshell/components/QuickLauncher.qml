pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../theme"
import "../services"
PanelCard {
    id:root
    property bool compact:false
    signal launched()
    signal settingsRequested()
    implicitHeight:62
    readonly property var pins:[
        {name:"Terminal",icon:"terminal",entry:LauncherService.entry(["foot","kitty","Alacritty"],"TerminalEmulator"),category:"dev"},
        {name:"Files",icon:"folder",category:"system",action:"files"},
        {name:"Browser",icon:"browser",entry:LauncherService.entry(["firefox","chromium","brave-browser"],"WebBrowser"),category:"browser"},
        {name:"ChatGPT",icon:"ai",entry:LauncherService.entry([],"WebBrowser"),category:"ai",action:"ai"},
        {name:"Editor",icon:"editor",entry:LauncherService.entry(["code","codium","org.kde.kate","nvim"],"TextEditor"),category:"dev"},
        {name:"Settings",icon:"settings",category:"system",action:"settings"}]
    Text {x:12;y:10;text:"QUICK TASKS";color:Theme.primary;font {family:Theme.fontFamily;pixelSize:10;letterSpacing:1}}
    Row {
        x:10;y:root.compact?22:33;spacing:2
        Repeater {
            model:root.pins
            delegate:AbstractButton {
                id:pin
                required property var modelData
                objectName:"launch"+modelData.name
                width:(root.width-30)/6;height:root.compact?32:43
                enabled:modelData.action==="settings" || modelData.action==="files" || !!modelData.entry
                opacity:enabled?1:Theme.opacityDisabled
                hoverEnabled:true
                Accessible.name:modelData.name+(enabled?"":" (not installed)")
                onClicked: {
                    if(modelData.action==="settings")root.settingsRequested();
                    else if(modelData.action==="files"){DesktopState.openFolder(DesktopState.home);root.launched();}
                    else if(modelData.action==="ai"){LauncherService.openAi();root.launched();}
                    else if(LauncherService.launch(modelData.entry))root.launched();
                }
                background:Rectangle {radius:Theme.cornerRadius;color:pin.hovered?Qt.alpha(Theme.categoryColor(pin.modelData.category),Theme.opacityHover):Theme.transparent}
                contentItem:Item {
                    Icon {name:pin.modelData.icon;color:Theme.categoryColor(pin.modelData.category);width:root.compact?18:22;height:root.compact?18:22;anchors {top:parent.top;horizontalCenter:parent.horizontalCenter}}
                    Text {text:pin.modelData.name;color:Theme.textMuted;anchors {bottom:parent.bottom;horizontalCenter:parent.horizontalCenter} font {family:Theme.fontFamily;pixelSize:8}}
                }
            }
        }
    }
}
