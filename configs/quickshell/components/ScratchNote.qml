import QtQuick
import QtQuick.Controls
import "../theme"
PanelCard {
    id: root
    property string note: ""
    implicitHeight: 86
    Text { x:12;y:root.height<50?3:10;text:"SCRATCH NOTE";color:Theme.primary;font {family:Theme.fontFamily;pixelSize:10;letterSpacing:1} }
    Text { anchors {right:parent.right;rightMargin:12;top:parent.top;topMargin:root.height<50?3:10} text:"SESSION";color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:9} }
    ScrollView {
        x:10;y:root.height<50?16:26;width:parent.width-20;height:Math.max(1,parent.height-y-6)
        TextArea {
            objectName:"controlScratchNote"
            text:root.note;onTextChanged:root.note=text
            placeholderText:"Type a note…";placeholderTextColor:Theme.textMuted
            color:Theme.text;selectionColor:Qt.alpha(Theme.primary,Theme.opacityBorder)
            wrapMode:TextEdit.Wrap;font {family:Theme.fontFamily;pixelSize:11}
            background:Rectangle {color:Theme.backgroundRaised;radius:Theme.cornerRadius}
            Accessible.name:"Session scratch note"
        }
    }
}
