pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: root
    anchors { top:true; bottom:true; left:true; right:true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "susnix-desktop"
    color: Theme.background
    Image {
        anchors.fill:parent
        source:Qt.resolvedUrl("../assets/desktop/nyx-city.png")
        fillMode:Image.PreserveAspectCrop
        asynchronous:true
        // Decode once per monitor size; no decorative timers or animated rain.
        sourceSize.width:Math.ceil(root.width*(root.screen?root.screen.devicePixelRatio:1))
        sourceSize.height:Math.ceil(root.height*(root.screen?root.screen.devicePixelRatio:1))
    }
    Rectangle {anchors.fill:parent;color:Qt.alpha(Theme.background,.12)}
    Rectangle {
        width:Math.min(parent.width*.5,560);height:parent.height
        gradient:Gradient {orientation:Gradient.Horizontal;GradientStop {position:0;color:Qt.alpha(Theme.background,.48)} GradientStop {position:1;color:Theme.transparent}}
    }
    Column {
        x:Math.max(22,root.width*.04);y:Theme.barHeight+28;spacing:7
        Text {text:"SUSNIX // PERSONAL SYSTEM";color:Theme.primary;font {family:Theme.fontFamily;pixelSize:9;letterSpacing:1.5}}
        Text {text:(Quickshell.env("USER")||"user")+"  /  ARCH · HYPRLAND";color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:9;letterSpacing:.7}}
    }
    Column {
        x:Math.max(22,root.width*.065);y:Math.max(104,root.height*.19);spacing:5
        SusnixWordmark {width:Math.min(300,root.width*.32);height:width*44/282}
        Text {text:"B U I L D   D I F F E R E N T";color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:9}}
        Rectangle {width:100;height:1;color:Qt.alpha(Theme.primary,.6)}
    }
    Grid {
        x:Math.max(22,root.width*.045)
        y:root.height<600?Math.max(186,root.height*.43):Math.max(250,root.height*.37)
        columns:Math.min(root.height<600?6:3,Math.max(2,Math.floor((root.width-44)/96)))
        rowSpacing:12;columnSpacing:8
        Repeater {
            model:DesktopState.locations.filter(place=>place.name!=="Desktop")
            delegate:AbstractButton {
                id:shortcut
                required property var modelData
                width:88;height:88;hoverEnabled:true
                Accessible.name:"Open "+modelData.name
                onClicked:DesktopState.openFolder(modelData.path)
                background:Rectangle {
                    radius:Theme.cornerRadius
                    color:shortcut.hovered?Qt.alpha(Theme.surfaceRaised,.85):Theme.transparent
                    border {width:Theme.borderWidth;color:shortcut.hovered?Qt.alpha(Theme.categoryColor(shortcut.modelData.category),.7):Theme.transparent}
                }
                contentItem:Item {
                    NeonFolder {anchors {top:parent.top;topMargin:8;horizontalCenter:parent.horizontalCenter} tint:Theme.categoryColor(shortcut.modelData.category);emblem:shortcut.modelData.icon==="folder"?"":shortcut.modelData.icon}
                    Text {anchors {bottom:parent.bottom;bottomMargin:10;horizontalCenter:parent.horizontalCenter} text:shortcut.modelData.name;color:Theme.text;font {family:Theme.fontFamily;pixelSize:10} style:Text.Outline;styleColor:Theme.background}
                }
            }
        }
    }
    Text {
        anchors {left:parent.left;leftMargin:28;bottom:parent.bottom;bottomMargin:70}
        text:"FOCUS  ›  BUILD  ›  CREATE  ›  REPEAT";color:Qt.alpha(Theme.primary,.65)
        font {family:Theme.fontFamily;pixelSize:8;letterSpacing:1}
    }
}
