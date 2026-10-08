pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
Item {
    id:root
    readonly property string helper:Qt.resolvedUrl("explorer-backend.py").toString().replace(/^file:\/\//,"")
    property var snapshot:({entries:[],error:""})
    property var details:({})
    property string message:""
    property bool busy:operation.running
    property string detailsPath:""
    signal operationFinished(bool ok)
    function watch(): void {watcher.running=false;Qt.callLater(()=>{if(DesktopState.filesOpen)watcher.running=true;});}
    function request(action: string, source: string, extra: var): void {
        if(operation.running)return;
        message="";
        operation.command=["python",helper,JSON.stringify(Object.assign({action:action,source:source},extra||{}))];operation.running=true;
    }
    function inspect(path: string): void {detailsPath=path;details={};detailDelay.restart();}
    Timer {id:detailDelay;interval:80;onTriggered: {
        if(detailProcess.running){restart();return;}
        detailProcess.command=["python",root.helper,JSON.stringify({action:"details",source:root.detailsPath})];detailProcess.running=true;
    }}
    Connections {target:DesktopState;function onFilesOpenChanged(): void {if(DesktopState.filesOpen)root.watch();else watcher.running=false;} function onFolderPathChanged(): void {root.snapshot={entries:[],error:""};root.details={};root.watch();}}
    Process {
        id:watcher
        command:["python",root.helper,"watch",DesktopState.folderPath]
        stdout:SplitParser {onRead:data=>{try{root.snapshot=JSON.parse(data);}catch(e){root.message="Could not read folder.";}}}
        stderr:StdioCollector {}
    }
    Process {
        id:detailProcess
        stdout:StdioCollector {onStreamFinished:{try{const data=JSON.parse(text);if(data.details&&data.details.path===root.detailsPath)root.details=data.details;}catch(e){root.details={};}}}
        stderr:StdioCollector {}
    }
    Process {
        id:operation
        stdout:StdioCollector {onStreamFinished:{try{const result=JSON.parse(text);root.message=result.error||"Done";root.operationFinished(!result.error);}catch(e){root.message="Operation failed.";root.operationFinished(false);}}}
        stderr:StdioCollector {}
    }
}
