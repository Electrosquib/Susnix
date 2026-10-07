import QtQuick
import QtQuick.Controls
import "../theme"
AbstractButton {
    id:root
    property color tint:Theme.primary
    implicitWidth:Math.max(34,label.implicitWidth+16)
    implicitHeight:26
    hoverEnabled:true
    focusPolicy:Qt.NoFocus
    opacity:enabled?1:Theme.opacityDisabled
    background:Rectangle {
        radius:Theme.cornerRadius
        color:Qt.alpha(root.tint,root.hovered||root.down?Theme.opacityHover:Theme.opacityGlow)
        border {width:Theme.borderWidth;color:Qt.alpha(root.tint,root.hovered?Theme.opacityBorder:Theme.opacityGlow)}
    }
    contentItem:Text {id:label;text:root.text;color:root.tint;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;font {family:Theme.fontFamily;pixelSize:10}}
}
