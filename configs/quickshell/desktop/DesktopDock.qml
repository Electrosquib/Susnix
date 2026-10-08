pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../components"
import "../services"

// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: root
    anchors {bottom:true;left:true;right:true}
    implicitHeight:52
    exclusiveZone:52
    color:Theme.transparent
    WlrLayershell.namespace:"susnix-dock"
    WlrLayershell.layer:WlrLayer.Top
    readonly property var pins:[
        {name:"Applications",icon:"apps",category:"media",action:"apps"},
        {name:"Terminal",icon:"terminal",category:"dev",app:LauncherService.entry(["susnix-terminal","foot","kitty"],"TerminalEmulator")},
        {name:"Files",icon:"folder",category:"ai",action:"files"},
        {name:"Browser",icon:"browser",category:"browser",app:LauncherService.entry(["firefox","chromium"],"WebBrowser")},
        {name:"Editor",icon:"editor",category:"dev",app:LauncherService.entry(["code","codium","vim"],"TextEditor")},
        {name:"Music",icon:"audio",category:"media",app:LauncherService.entry(["spotify","org.gnome.Lollypop","vlc"],"AudioVideo")},
        {name:"Control center",icon:"controls",category:"system",action:"control"}]
    signal controlRequested()
    Rectangle {
        anchors.fill:parent
        gradient:Gradient {GradientStop {position:0;color:Qt.alpha(Theme.surfaceRaised,.87)} GradientStop {position:1;color:Qt.alpha(Theme.background,.97)}}
        Rectangle {anchors {left:parent.left;right:parent.right;top:parent.top} height:1;gradient:Gradient {orientation:Gradient.Horizontal;GradientStop {position:0;color:Theme.secondary} GradientStop {position:.5;color:Theme.primary} GradientStop {position:1;color:Qt.alpha(Theme.primary,.3)}}}
    }
    Text {
        visible:root.width>760
        anchors {left:parent.left;leftMargin:22;verticalCenter:parent.verticalCenter}
        text:"SUSNIX / "+ThemeManager.currentTheme.toUpperCase()
        color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:9;letterSpacing:1}
    }
    Row {
        anchors.centerIn:parent;spacing:8
        Repeater {
            model:root.pins
            delegate:AbstractButton {
                id:pin
                required property var modelData
                width:40;height:40
                enabled:!!modelData.action||!!modelData.app
                hoverEnabled:true
                opacity:enabled?1:Theme.opacityDisabled
                Accessible.name:modelData.name+(enabled?"":" (not installed)")
                onClicked: {
                    if(modelData.action==="apps")DesktopState.launcherOpen=!DesktopState.launcherOpen;
                    else if(modelData.action==="files")DesktopState.openFolder(DesktopState.home);
                    else if(modelData.action==="control")root.controlRequested();
                    else LauncherService.launch(modelData.app);
                }
                background:Rectangle {
                    radius:Theme.cornerRadius
                    gradient:Gradient {GradientStop {position:0;color:Qt.alpha(Theme.categoryColor(pin.modelData.category),pin.hovered?.32:.08)} GradientStop {position:1;color:Qt.alpha(Theme.surface,.4)}}
                    border {width:Theme.borderWidth;color:Qt.alpha(Theme.categoryColor(pin.modelData.category),pin.hovered?.8:.18)}
                    Rectangle {anchors {horizontalCenter:parent.horizontalCenter;bottom:parent.bottom;bottomMargin:2} width:pin.hovered?24:10;height:1;color:Qt.alpha(Theme.categoryColor(pin.modelData.category),pin.hovered?1:.4)}
                }
                contentItem:Item {
                    NeonFolder {visible:pin.modelData.icon==="folder";anchors.centerIn:parent;width:31;height:29;tint:Theme.categoryColor(pin.modelData.category)}
                    Icon {visible:pin.modelData.icon!=="folder";anchors.centerIn:parent;width:24;height:24;name:pin.modelData.icon;color:Theme.categoryColor(pin.modelData.category)}
                }
                ThemeToolTip {visible:pin.hovered;delay:400;text:pin.Accessible.name}
            }
        }
    }
    Text {
        visible:root.width>760
        anchors {right:parent.right;rightMargin:22;verticalCenter:parent.verticalCenter}
        text:"FOCUS · BUILD · CREATE";color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:9}
    }
}
