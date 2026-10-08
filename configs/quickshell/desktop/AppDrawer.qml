pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id:root
    visible:DesktopState.launcherOpen
    anchors.bottom:true
    exclusionMode:ExclusionMode.Ignore
    // Quickshell's margins value has incomplete cross-module lint metadata.
    // qmllint disable unqualified unresolved-type
    margins {bottom:60}
    // qmllint enable unqualified unresolved-type
    implicitWidth:Math.min(560,screen?screen.width-24:560)
    implicitHeight:Math.min(480,screen?screen.height-Theme.barHeight-90:480)
    color:Theme.transparent
    WlrLayershell.namespace:"susnix-applications"
    WlrLayershell.layer:WlrLayer.Overlay
    WlrLayershell.keyboardFocus:WlrKeyboardFocus.OnDemand
    readonly property var matches:LauncherService.applications.filter(app=>app.name.toLowerCase().includes(search.text.toLowerCase()))
    onVisibleChanged:if(visible) {search.text="";Qt.callLater(()=>search.forceActiveFocus());}
    Rectangle {
        anchors.fill:parent;radius:Theme.cornerRadius+2
        color:Qt.alpha(Theme.background,.97)
        border {width:Theme.borderWidth;color:Theme.primary}
        gradient:Gradient {GradientStop {position:0;color:Theme.surfaceRaised} GradientStop {position:1;color:Qt.alpha(Theme.background,.97)}}
    }
    Column {
        anchors {left:parent.left;right:parent.right;top:parent.top;margins:16}
        spacing:12
        Row {
            width:parent.width
            Text {width:parent.width-36;text:"APPLICATIONS // "+root.matches.length;color:Theme.primary;font {family:Theme.fontFamily;pixelSize:11;letterSpacing:1}}
            PanelButton {width:30;text:"×";onClicked:DesktopState.launcherOpen=false}
        }
        TextField {
            id:search;width:parent.width;height:34
            placeholderText:"Find an application…";color:Theme.text;placeholderTextColor:Theme.textMuted
            font {family:Theme.fontFamily;pixelSize:12}
            background:Rectangle {color:Theme.backgroundRaised;radius:Theme.cornerRadius;border {width:Theme.borderWidth;color:Qt.alpha(Theme.primary,.4)}}
            Keys.onEscapePressed:DesktopState.launcherOpen=false
            onAccepted:if(root.matches.length&&LauncherService.launch(root.matches[0]))DesktopState.launcherOpen=false
        }
    }
    GridView {
        id:grid
        anchors {left:parent.left;right:parent.right;top:parent.top;bottom:parent.bottom;leftMargin:12;rightMargin:12;topMargin:108;bottomMargin:14}
        clip:true;cellWidth:Math.floor(width/3);cellHeight:86
        model:root.matches
        ScrollBar.vertical:ScrollBar {}
        delegate:AbstractButton {
            id:appButton
            required property var modelData
            width:grid.cellWidth-6;height:80;hoverEnabled:true
            Accessible.name:modelData.name
            onClicked:if(LauncherService.launch(modelData))DesktopState.launcherOpen=false
            background:Rectangle {radius:Theme.cornerRadius;color:appButton.hovered?Qt.alpha(Theme.primary,Theme.opacityHover):Theme.transparent;border {width:Theme.borderWidth;color:appButton.hovered?Qt.alpha(Theme.primary,.6):Theme.transparent}}
            contentItem:Column {
                spacing:8
                Item {
                    anchors.horizontalCenter:parent.horizontalCenter;width:30;height:30
                    readonly property bool hasIcon:!!appButton.modelData.icon&&Quickshell.hasThemeIcon(appButton.modelData.icon)
                    Image {anchors.fill:parent;visible:parent.hasIcon;source:parent.hasIcon?Quickshell.iconPath(appButton.modelData.icon):"";sourceSize:Qt.size(60,60)}
                    Icon {anchors.fill:parent;visible:!parent.hasIcon;name:"apps";color:Theme.secondary}
                }
                Text {width:parent.width;text:appButton.modelData.name;color:Theme.text;elide:Text.ElideRight;horizontalAlignment:Text.AlignHCenter;font {family:Theme.fontFamily;pixelSize:10}}
            }
        }
    }
}
