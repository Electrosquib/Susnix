pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import "../theme"

Item {
    id:root
    readonly property var colors:ThemeManager.colors
    function refresh(): void { applyDelay.restart(); }
    onColorsChanged:applyDelay.restart()
    Component.onCompleted:applyDelay.restart()
    Timer {id:applyDelay;interval:120;onTriggered: {
        if(apply.running){restart();return;}
        apply.command=["bash",Qt.resolvedUrl("desktop-appearance.sh").toString().replace(/^file:\/\//,"")].concat(
            ["background","backgroundRaised","surface","surfaceRaised","primary","secondary","accent","text","textMuted","border","success","warning","danger","dev","browser","ai","media","system"].map(key=>root.colors[key]));
        apply.running=true;
    }}
    Process {
        id:apply
        stderr:StdioCollector {onStreamFinished:if(text.trim())console.warn("Susnix desktop appearance: "+text.trim())}
    }
}
