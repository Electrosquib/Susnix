pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    readonly property string home: Quickshell.env("HOME")
    property bool launcherOpen: false
    property bool filesOpen: false
    property string folderPath: home
    property var history: []
    property var forwardHistory: []
    property int focusAttempts:0
    property var locations: [
        {name:"Home",path:home,icon:"folder",category:"dev"},
        {name:"Desktop",path:home,icon:"folder",category:"dev"},
        {name:"Downloads",path:home,icon:"download",category:"ai"},
        {name:"Documents",path:home,icon:"document",category:"dev"},
        {name:"Pictures",path:home,icon:"picture",category:"browser"},
        {name:"Music",path:home,icon:"audio",category:"media"},
        {name:"Videos",path:home,icon:"play",category:"media"}
    ]
    function openFolder(path: string): void {
        if (folderPath !== path) { history = history.concat([folderPath]); forwardHistory=[];folderPath = path; }
        filesOpen = true;
        launcherOpen = false;
        focusAttempts = 10;
        focusDelay.restart();
    }
    function back(): void {
        if (!history.length) return;
        forwardHistory=forwardHistory.concat([folderPath]);folderPath = history[history.length - 1]; history = history.slice(0, -1);
    }
    function forward(): void {
        if(!forwardHistory.length)return;
        history=history.concat([folderPath]);folderPath=forwardHistory[forwardHistory.length-1];forwardHistory=forwardHistory.slice(0,-1);
    }
    function up(): void {
        if (folderPath === "/") return;
        openFolder(folderPath.slice(0, folderPath.lastIndexOf("/")) || "/");
    }
    function openFile(url: string): void {
        // Source/text files remain usable even in the minimal VM before browser
        // and media applications are installed. Core already provides Vim.
        if (/\.(txt|md|json|qml|lua|sh|py|ini|conf|html|css|js|ts|rs|c|h|xml|log|yaml|yml)$/i.test(url)) {
            const path=decodeURIComponent(url.replace(/^file:\/\//,""));
            if(LauncherService.editFile(path))return;
        }
        Quickshell.execDetached(["xdg-open", url]);
    }
    function terminalHere(directory: string): void { Quickshell.execDetached({command:["bash",Qt.resolvedUrl("open-terminal.sh").toString().replace(/^file:\/\//,"")],workingDirectory:directory||folderPath}); }
    function recenterFiles(): void {centerDelay.restart();}
    Timer {id:centerDelay;interval:200;onTriggered:if(root.filesOpen){if(centerFiles.running)restart();else centerFiles.running=true;}}
    Process {
        id:centerFiles
        command:["hyprctl","eval","hl.dispatch(hl.dsp.window.center({window=\"title:^Susnix Files$\"}))"]
        stdout:StdioCollector {}
        stderr:StdioCollector {}
    }
    // Existing windows need explicit activation; showing them again may otherwise
    // leave Files behind the current application or on another workspace.
    Timer {
        id:focusDelay;interval:50
        onTriggered: {
            if(!root.filesOpen||root.focusAttempts===0)return;
            if(focusFiles.running){restart();return;}
            root.focusAttempts--;focusFiles.running=true;
        }
    }
    Process {
        id:focusFiles
        command:["hyprctl","eval","hl.dispatch(hl.dsp.window.move({window=\"title:^Susnix Files$\",workspace=hl.get_active_workspace(),follow=false})); hl.dispatch(hl.dsp.focus({window=\"title:^Susnix Files$\"}))"]
        stdout:StdioCollector {id:focusReply}
        stderr:StdioCollector {}
        // QProcess::ExitStatus has no QML enum metadata in Quickshell 0.3.1.
        // qmllint disable signal-handler-parameters
        onExited:exitCode=>{if((exitCode!==0||focusReply.text.includes("window not found"))&&root.focusAttempts>0)focusDelay.restart();}
        // qmllint enable signal-handler-parameters
    }
    Process {
        running: true
        command: ["bash", Qt.resolvedUrl("desktop-paths.sh").toString().replace(/^file:\/\//, "")]
        stdout: StdioCollector {
            onStreamFinished: {
                const paths = {};
                for (const line of text.trim().split("\n")) {
                    const separator = line.indexOf("\t");
                    if (separator > 0) paths[line.slice(0, separator)] = line.slice(separator + 1);
                }
                root.locations = root.locations.map(place => Object.assign({}, place, {path:paths[place.name] || root.home}));
            }
        }
    }
}
