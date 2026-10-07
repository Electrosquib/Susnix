import QtQuick
import "../theme"
PanelCard {
    id:root
    property bool compact: false
    implicitHeight: 140
    Text { x:12;y:10;text:"SUSNIX AI";color:Theme.accent;font {family:Theme.fontFamily;pixelSize:13;bold:true;letterSpacing:1} }
    Text { anchors {right:parent.right;rightMargin:12;top:parent.top;topMargin:12} text:"PLACEHOLDER";color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:9} }
    Image {
        fillMode:Image.PreserveAspectFit
        visible:root.height>=64
        x:44;y:root.compact?28:36;width:root.compact?70:100;height:Math.max(20,parent.height-(root.compact?44:62));sourceSize:Qt.size(224,208)
        source:"data:image/svg+xml,"+encodeURIComponent("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 112 104' fill='none' stroke='"+Theme.secondary+"'><path d='M56 5L84 19L94 45L86 76L56 97L26 76L18 45L28 19Z M28 19L56 35L84 19M18 45L56 35L94 45M26 76L56 63L86 76M56 35V63M56 63V97' stroke-opacity='"+Theme.opacityBorder+"'/><path d='M31 48L46 52M66 52L81 48M46 78H66' stroke='"+Theme.primary+"' stroke-width='2'/><circle cx='18' cy='45' r='4' stroke='"+Theme.accent+"'/><circle cx='94' cy='45' r='4' stroke='"+Theme.accent+"'/></svg>")
    }
    Column {
        visible:root.height>=64
        anchors {right:parent.right;rightMargin:18;top:parent.top;topMargin:32} spacing:root.compact?3:8
        Repeater { model:root.compact?["ANALYZE","CREATE"]:["ANALYZE","PLAN","CREATE","EXECUTE"];delegate:Text { required property string modelData;text:modelData;color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:10;letterSpacing:1} } }
    }
    Text { x:12;y:parent.height-17;width:parent.width-24;text:"Assistant module • not connected";color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:10} }
}
