pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"
import "../services"
import "../components"

// qmllint disable uncreatable-type
FloatingWindow {
// qmllint enable uncreatable-type
    id:root
    title:"Susnix Files"
    visible:DesktopState.filesOpen
    readonly property var availableScreen:screen||Quickshell.screens[0]
    readonly property bool compact:width<720||height<440
    implicitWidth:Math.min(1000,availableScreen?availableScreen.width-48:1000)
    implicitHeight:Math.min(640,availableScreen?availableScreen.height-Theme.barHeight-100:640)
    minimumSize:Qt.size(410,300)
    maximumSize:Qt.size(Math.max(410,availableScreen?availableScreen.width-32:1000),Math.max(300,availableScreen?availableScreen.height-Theme.barHeight-84:640))
    color:Theme.background
    onClosed:DesktopState.filesOpen=false
    onVisibleChanged:if(visible){DesktopState.recenterFiles();ExplorerService.watch();}else contextMenu.close()
    property string viewMode:"Details"
    property string sortBy:"Name"
    property bool descending:false
    property bool showHidden:false
    property bool detailsOpen:false
    property string typeFilter:"All"
    property string selectedPath:""
    property bool editingPath:false
    readonly property bool popupOpen:contextMenu.opened||actionDialog.opened||networkDialog.opened||viewMenu.opened||sortMenu.opened||filterMenu.opened||moreMenu.opened
    property string dialogAction:""
    property var pending:({})
    readonly property var selected:entries.find(file=>file.path===selectedPath)||null
    readonly property var breadcrumbs:{
        const parts=DesktopState.folderPath.split("/").filter(Boolean);
        const result=[{name:"/",path:"/"}];let full="";
        for(const part of parts){full+="/"+part;result.push({name:full===DesktopState.home?"Home":part,path:full});}
        return result;
    }
    readonly property var entries:(ExplorerService.snapshot.entries||[]).filter(file=>
        (showHidden||!file.name.startsWith("."))&&(!search.text||file.name.toLowerCase().includes(search.text.toLowerCase()))&&
        (typeFilter==="All"||(typeFilter==="Folders"&&file.isDir)||(typeFilter==="Files"&&!file.isDir)||(typeFilter==="Images"&&/\.(png|jpe?g|svg|webp|gif)$/i.test(file.name))))
        .sort((a,b)=>{if(a.isDir!==b.isDir)return a.isDir?-1:1;const order=sortBy==="Size"?a.size-b.size:sortBy==="Modified"?a.modified-b.modified:sortBy==="Type"?a.type.localeCompare(b.type):a.name.localeCompare(b.name,undefined,{numeric:true});return descending?-order:order;})
    component SidebarEntry: PanelButton {
        id: sidebarButton
        property var entry: ({})
        width:root.compact?88:122;height:root.compact?23:29
        tint:DesktopState.folderPath===entry.path?Theme.primary:Theme.textMuted
        contentItem:RowLayout {
            spacing:6
            Icon {name:sidebarButton.entry.icon||"folder";effectsEnabled:false;color:sidebarButton.tint;Layout.preferredWidth:14;Layout.preferredHeight:14}
            Text {text:sidebarButton.entry.name||"";color:sidebarButton.tint;Layout.fillWidth:true;elide:Text.ElideRight;font{family:Theme.fontFamily;pixelSize:10}}
        }
    }
    function folderEmblem(path: string): string {
        const location=DesktopState.locations.find(entry=>entry.path===path);
        if(location&&location.icon!=="folder")return location.icon;
        if(path===DesktopState.home+"/Projects"||path===DesktopState.home+"/susnix"||path===DesktopState.home+"/Radar")return "terminal";
        return "";
    }
    function editPath(): void {pathInput.text=DesktopState.folderPath;root.editingPath=true;pathInput.forceActiveFocus();pathInput.selectAll();}
    function bytes(n: real): string {if(n<1024)return n+" B";if(n<1048576)return (n/1024).toFixed(1)+" KB";if(n<1073741824)return (n/1048576).toFixed(1)+" MB";return (n/1073741824).toFixed(1)+" GB";}
    function modified(n: real): string {return Qt.formatDateTime(new Date(n*1000),"MMM d, HH:mm");}
    function open(file: var): void {if(!file)return;if(file.isDir)DesktopState.openFolder(file.path);else DesktopState.openFile(file.url);}
    function select(file: var): void {selectedPath=file.path;ExplorerService.inspect(file.path);}
    function contextActions(): var {
        const ready=!ExplorerService.busy, picked=!!selected&&ready;
        const extra=[
            {label:"Terminal",icon:"terminal",action:"terminal"},
            {label:"Code",icon:"editor",action:"code",enabled:picked},
            {label:"Details",icon:"document",action:"details",enabled:picked},
            {label:"New folder",icon:"folder",action:"mkdir",enabled:ready},
            {label:"Refresh",icon:"controls",action:"refresh"},
            {label:"Hidden files",icon:"settings",action:"hidden"}
        ];
        if(!selected)return [extra[3],extra[0],extra[4],extra[5],{label:"Home",icon:"folder",action:"home"},{label:"Up",icon:"folder",action:"up",enabled:DesktopState.folderPath!=="/"}];
        return [
            {label:"Open",icon:selected.isDir?"folder":"document",action:"open",enabled:picked},
            {label:"Copy",icon:"copy",action:"copy",enabled:picked},
            {label:"Move",icon:"move",action:"move",enabled:picked},
            {label:"Rename",icon:"editor",action:"rename",enabled:picked},
            {label:"Trash",icon:"trash",action:"trash",enabled:picked,danger:true},
            {label:"More",icon:"settings",items:extra}
        ];
    }
    function ask(action: string): void {
        if(action!=="mkdir"&&!selected)return;
        dialogAction=action;pending=selected||{}
        actionInput.text=action==="rename"?selected.name:action==="copy"||action==="move"?DesktopState.home:"";
        actionDialog.open();actionInput.forceActiveFocus();actionInput.selectAll();
    }
    function windowAction(action: string): void {
        if(windowProcess.running)return;
        const selector="title:^Susnix Files$";
        windowProcess.command=["hyprctl","eval",action==="maximize"?"hl.dispatch(hl.dsp.window.fullscreen({window=\""+selector+"\",mode=\"maximized\"}))":"hl.dispatch(hl.dsp.window.move({window=\""+selector+"\",workspace=\"special:susnix-minimized\",follow=false}))"];
        windowProcess.running=true;
    }
    function escapeHtml(value: string): string {return value.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");}
    Connections {target:root.availableScreen;function onWidthChanged(): void {if(root.visible)DesktopState.recenterFiles();}function onHeightChanged(): void {if(root.visible)DesktopState.recenterFiles();}}
    Connections {
        target:DesktopState
        function onFolderPathChanged(): void {search.text="";root.selectedPath="";root.editingPath=false;contextMenu.close();}
        function onNewFolderRequested(): void {root.ask("mkdir");}
    }
    Connections {target:ExplorerService;function onOperationFinished(ok: bool): void {if(ok){ExplorerService.watch();if(root.selected)ExplorerService.inspect(root.selected.path);}}}
    Process {id:windowProcess;stdout:StdioCollector{}stderr:StdioCollector{}}
    Shortcut {sequence:"Escape";enabled:root.visible&&!root.popupOpen;onActivated:if(root.editingPath)root.editingPath=false;else DesktopState.filesOpen=false}
    Shortcut {sequence:"Ctrl+L";enabled:root.visible;onActivated:{root.editPath();}}
    Shortcut {sequence:"Alt+Left";enabled:root.visible;onActivated:DesktopState.back()}
    Shortcut {sequence:"Alt+Right";enabled:root.visible;onActivated:DesktopState.forward()}
    Shortcut {sequence:"Alt+Up";enabled:root.visible;onActivated:DesktopState.up()}
    Shortcut {sequence:"Ctrl+H";enabled:root.visible;onActivated:root.showHidden=!root.showHidden}
    Shortcut {sequence:"F2";enabled:root.visible&&!!root.selected;onActivated:root.ask("rename")}
    Rectangle {anchors.fill:parent;gradient:Gradient{GradientStop{position:0;color:Theme.surfaceRaised}GradientStop{position:.18;color:Theme.backgroundRaised}GradientStop{position:1;color:Theme.background}}border{width:Theme.borderWidth;color:Qt.alpha(Theme.primary,.55)}}
    ColumnLayout {
        anchors.fill:parent;anchors.margins:root.compact?8:12;spacing:root.compact?5:8
        RowLayout {
            Layout.fillWidth:true;spacing:6
            WindowControls {onCloseRequested:DesktopState.filesOpen=false;onMinimizeRequested:root.windowAction("minimize");onMaximizeRequested:root.windowAction("maximize")}
            Item {
                Layout.fillWidth:true;Layout.preferredHeight:26
                Text {anchors.fill:parent;visible:!root.compact;text:"FILES // EXPLORER";color:Theme.primary;verticalAlignment:Text.AlignVCenter;font{family:Theme.fontFamily;pixelSize:10;letterSpacing:1}elide:Text.ElideRight}
                MouseArea {
                    anchors.fill:parent;cursorShape:Qt.OpenHandCursor
                    onPressed:if(Window.window)Window.window.startSystemMove()
                    onDoubleClicked:root.windowAction("maximize")
                }
            }
            PanelButton {text:"‹";enabled:DesktopState.history.length>0;Accessible.name:"Back";onClicked:DesktopState.back()}
            PanelButton {text:"›";enabled:DesktopState.forwardHistory.length>0;Accessible.name:"Forward";onClicked:DesktopState.forward()}
            PanelButton {text:"↑";enabled:DesktopState.folderPath!=="/";Accessible.name:"Parent folder";onClicked:DesktopState.up()}
        }
        RowLayout {
            Layout.fillWidth:true;spacing:6
            Rectangle {
                Layout.fillWidth:true;Layout.preferredHeight:30;color:Theme.surface;border{width:1;color:Qt.alpha(Theme.border,.6)}radius:Theme.cornerRadius;clip:true
                MouseArea {anchors.fill:parent;onClicked:{root.editPath();}}
                Flickable {
                    anchors.fill:parent;anchors.margins:3;visible:!root.editingPath;contentWidth:crumbs.width;contentHeight:height;clip:true
                    Row {id:crumbs;height:parent.height;spacing:1
                        Repeater {model:root.breadcrumbs;delegate:PanelButton {required property var modelData;text:modelData.name+" ›";height:24;tint:DesktopState.folderPath===modelData.path?Theme.primary:Theme.textMuted;onClicked:DesktopState.openFolder(modelData.path)}}
                    }
                }
                MouseArea {visible:!root.editingPath;x:Math.min(crumbs.width+6,parent.width);width:Math.max(0,parent.width-x);height:parent.height;onClicked:{root.editPath();}}
                TextField {id:pathInput;anchors.fill:parent;visible:root.editingPath;text:DesktopState.folderPath;color:Theme.text;selectByMouse:true;font{family:Theme.fontFamily;pixelSize:11}background:Item{}onAccepted:{let next=text.replace(/^~/,DesktopState.home);if(next.startsWith("/")){DesktopState.openFolder(next);root.editingPath=false;}}}
            }
            TextField {id:search;Layout.preferredWidth:root.compact?110:180;Layout.preferredHeight:30;placeholderText:"Search folder";color:Theme.text;placeholderTextColor:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:10}background:Rectangle{color:Theme.surface;border{width:1;color:Qt.alpha(Theme.border,.5)}}}
        }
        RowLayout {
            Layout.fillWidth:true;spacing:5
            PanelButton {text:root.viewMode+" ▾";onClicked:viewMenu.open();ThemeMenu{id:viewMenu;MenuItem{text:"Details";onTriggered:root.viewMode=text}MenuItem{text:"Grid";onTriggered:root.viewMode=text}MenuItem{text:"Compact grid";onTriggered:root.viewMode=text}}}
            PanelButton {text:"Sort ▾";onClicked:sortMenu.open();ThemeMenu{id:sortMenu;Repeater{model:["Name","Type","Size","Modified"];MenuItem{required property string modelData;text:modelData;onTriggered:root.sortBy=text}}MenuSeparator{}MenuItem{text:"Descending";checkable:true;checked:root.descending;onTriggered:root.descending=checked}}}
            PanelButton {text:"Filter ▾";onClicked:filterMenu.open();ThemeMenu{id:filterMenu;Repeater{model:["All","Folders","Files","Images"];MenuItem{required property string modelData;text:modelData;onTriggered:root.typeFilter=text}}MenuSeparator{}MenuItem{text:"Hidden files";checkable:true;checked:root.showHidden;onTriggered:root.showHidden=checked}}}
            Item {Layout.fillWidth:true}
            PanelButton {text:root.detailsOpen?"Details ▸":"Details ◂";checkable:true;checked:root.detailsOpen;onClicked:root.detailsOpen=!root.detailsOpen}
            PanelButton {text:"•••";onClicked:moreMenu.open();ThemeMenu{id:moreMenu;MenuItem{text:"New folder";onTriggered:root.ask("mkdir")}MenuItem{text:"Refresh";onTriggered:ExplorerService.watch()}MenuItem{text:"Move selected to Trash";enabled:!!root.selected;onTriggered:root.ask("trash")}}}
        }
        RowLayout {
            Layout.fillWidth:true;Layout.fillHeight:true;spacing:8
            ScrollView {
                Layout.preferredWidth:root.compact?90:125;Layout.fillHeight:true;clip:true
                Column {
                    width:parent.width;spacing:3
                    Repeater {model:DesktopState.locations;delegate:SidebarEntry {required property var modelData;entry:modelData;onClicked:DesktopState.openFolder(modelData.path)}}
                    Rectangle {width:parent.width;height:1;color:Qt.alpha(Theme.border,.4)}
                    Repeater {model:[{name:"Projects",path:DesktopState.home+"/Projects"},{name:"Radar",path:DesktopState.home+"/Radar"},{name:"Susnix",path:DesktopState.home+"/susnix"},{name:"Drives",path:"/run/media/"+(Quickshell.env("USER")||"")},{name:"Network",path:"/"},{name:"Trash",path:(Quickshell.env("XDG_DATA_HOME")||DesktopState.home+"/.local/share")+"/Trash/files"}];delegate:SidebarEntry{required property var modelData;entry:modelData;onClicked:if(modelData.name==="Network")networkDialog.open();else DesktopState.openFolder(modelData.path)}}
                }
            }
            ColumnLayout {
                Layout.fillWidth:true;Layout.fillHeight:true;spacing:2
                Row {
                    visible:root.viewMode==="Details";Layout.fillWidth:true;Layout.preferredHeight:22
                    Text {width:files.width*(root.compact?.65:.45);text:"NAME";color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:9}}
                    Text {visible:!root.compact;width:files.width*.18;text:"TYPE";color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:9}}
                    Text {width:files.width*(root.compact?.35:.14);text:"SIZE";color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:9}}
                    Text {visible:!root.compact;text:"MODIFIED";color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:9}}
                }
                GridView {
                    id:files;Layout.fillWidth:true;Layout.fillHeight:true;clip:true;model:root.entries
                    cellWidth:root.viewMode==="Details"?width:Math.max(96,Math.floor(width/Math.max(1,Math.floor(width/(root.viewMode==="Grid"?136:104)))))
                    cellHeight:root.viewMode==="Details"?30:root.viewMode==="Grid"?115:82
                    ScrollBar.vertical:ScrollBar{}
                    MouseArea {
                        parent:files;anchors.fill:parent;z:2;acceptedButtons:Qt.RightButton
                        onClicked: mouse=> {
                            const index=files.indexAt(mouse.x+files.contentX,mouse.y+files.contentY);
                            if(index>=0)root.select(root.entries[index]);else root.selectedPath="";
                            contextMenu.showAt(this,mouse.x,mouse.y,root.contextActions(),root.selected?root.selected.name:"FOLDER");
                        }
                    }
                    delegate:AbstractButton {
                        id:fileButton;required property var modelData
                        width:files.cellWidth-2;height:files.cellHeight-2;hoverEnabled:true
                        Accessible.name:modelData.name
                        onClicked:root.select(modelData)
                        onDoubleClicked:root.open(modelData)
                        Keys.onReturnPressed:root.open(modelData)
                        background:Rectangle{color:root.selectedPath===fileButton.modelData.path?Qt.alpha(Theme.primary,.1):fileButton.hovered?Qt.alpha(Theme.surfaceRaised,.65):Theme.transparent;radius:Theme.cornerRadius;border{width:1;color:root.selectedPath===fileButton.modelData.path?Qt.alpha(Theme.primary,.4):fileButton.hovered?Qt.alpha(Theme.border,.5):Theme.transparent}}
                        contentItem:Item {
                            Row {
                                visible:root.viewMode==="Details";anchors.fill:parent
                                Row {width:files.width*(root.compact?.65:.45);height:parent.height;spacing:6
                                    NeonFolder {visible:fileButton.modelData.isDir;effectsEnabled:false;tint:Theme.primary;emblem:root.folderEmblem(fileButton.modelData.path);width:22;height:20;anchors.verticalCenter:parent.verticalCenter}
                                    Icon {visible:!fileButton.modelData.isDir;effectsEnabled:false;name:"document";color:fileButton.modelData.isDir?Qt.alpha(Theme.primary,.75):Theme.textMuted;width:18;height:18;anchors.verticalCenter:parent.verticalCenter}
                                    Text {width:parent.width-28;text:fileButton.modelData.name;color:fileButton.hovered?Theme.text:Qt.alpha(Theme.text,.9);font{family:Theme.fontFamily;pixelSize:10}elide:Text.ElideMiddle;anchors.verticalCenter:parent.verticalCenter}
                                }
                                Text {visible:!root.compact;width:files.width*.18;text:fileButton.modelData.type;color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:10}elide:Text.ElideRight;anchors.verticalCenter:parent.verticalCenter}
                                Text {width:files.width*(root.compact?.35:.14);text:fileButton.modelData.isDir?"—":root.bytes(fileButton.modelData.size);color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:10}anchors.verticalCenter:parent.verticalCenter}
                                Text {visible:!root.compact;width:files.width*.23;text:root.modified(fileButton.modelData.modified);color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:10}elide:Text.ElideRight;anchors.verticalCenter:parent.verticalCenter}
                            }
                            Column {
                                visible:root.viewMode!=="Details";anchors.fill:parent;spacing:5
                                Item {width:parent.width;height:root.viewMode==="Grid"?68:40;y:fileButton.hovered?-1:0
                                    NeonFolder {visible:fileButton.modelData.isDir;effectsEnabled:false;anchors.centerIn:parent;width:root.viewMode==="Grid"?48:34;height:width*.9;tint:Theme.primary;emblem:root.folderEmblem(fileButton.modelData.path)}
                                    Icon {visible:!fileButton.modelData.isDir;effectsEnabled:false;anchors.centerIn:parent;width:root.viewMode==="Grid"?40:28;height:width;name:fileButton.modelData.isDir?"folder":/\.(png|jpg|svg|webp)$/i.test(fileButton.modelData.name)?"picture":"document";color:fileButton.modelData.isDir?Qt.alpha(Theme.primary,.75):Qt.alpha(Theme.secondary,.8)}
                                }
                                Text {width:parent.width;text:fileButton.modelData.name;color:Theme.text;font{family:Theme.fontFamily;pixelSize:10}horizontalAlignment:Text.AlignHCenter;elide:Text.ElideMiddle}
                                Text {visible:root.viewMode==="Grid";width:parent.width;text:fileButton.modelData.isDir?"Folder":root.bytes(fileButton.modelData.size);color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:9}horizontalAlignment:Text.AlignHCenter}
                            }
                        }
                    }
                    Text {anchors.centerIn:parent;visible:root.entries.length===0;text:ExplorerService.snapshot.error||"No matching files";width:parent.width-20;wrapMode:Text.Wrap;color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:11}}
                }
            }
            ScrollView {
                visible:root.detailsOpen&&!root.compact;Layout.preferredWidth:210;Layout.fillHeight:true;clip:true
                Column {width:200;spacing:10
                    Text {width:parent.width;text:root.selected?root.selected.name:"Select a file";color:Theme.primary;font{family:Theme.fontFamily;pixelSize:12}wrapMode:Text.Wrap}
                    Image {visible:!!ExplorerService.details.image;source:ExplorerService.details.image||"";width:200;height:visible?140:0;fillMode:Image.PreserveAspectFit;asynchronous:true;sourceSize:Qt.size(400,280)}
                    Text {width:200;text:root.selected?[root.selected.type,root.selected.isDir?(ExplorerService.details.items===undefined?"":ExplorerService.details.items+" immediate items"):root.bytes(root.selected.size),"Modified",root.modified(root.selected.modified),"Path",root.selected.path,"Permissions",root.selected.permissions,"Git",ExplorerService.details.git||"—"].join("\n"):"";color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:10}wrapMode:Text.Wrap;lineHeight:1.35}
                    Text {width:200;text:(ExplorerService.details.folders||[]).join("\n");color:Theme.primary;font{family:Theme.fontFamily;pixelSize:10}wrapMode:Text.Wrap}
                    Text {width:200;text:(ExplorerService.details.tokens||[]).map(token=>"<span style='color:"+ThemeManager.colors[token.role]+"'>"+root.escapeHtml(token.text)+"</span>").join("").replace(/\n/g,"<br>");textFormat:Text.RichText;color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:9}wrapMode:Text.WrapAnywhere}
                    Row {spacing:6;PanelButton{text:"Open";enabled:!!root.selected;onClicked:root.open(root.selected)}PanelButton{text:"Rename";enabled:!!root.selected;onClicked:root.ask("rename")}}
                }
            }
        }
        Flickable {
            visible:!!root.selected;Layout.fillWidth:true;Layout.preferredHeight:27;clip:true;contentWidth:actions.width;contentHeight:height
            Row {id:actions;spacing:4
                Repeater {model:["OPEN","COPY","MOVE","RENAME","TERMINAL","CODE","MORE"];delegate:PanelButton{required property string modelData;text:modelData;enabled:!ExplorerService.busy;onClicked:{if(modelData==="OPEN")root.open(root.selected);else if(modelData==="TERMINAL")DesktopState.terminalHere(root.selected.isDir?root.selected.path:DesktopState.folderPath);else if(modelData==="CODE"){if(!LauncherService.editFile(root.selected.path))ExplorerService.message="No editor installed.";}else if(modelData==="MORE")moreMenu.open();else root.ask(modelData.toLowerCase());}}}
            }
        }
        RowLayout {
            Layout.fillWidth:true
            Text {text:ExplorerService.busy?"WORKING…":ExplorerService.message||root.entries.length+" ITEMS  ·  "+root.bytes(root.entries.reduce((sum,file)=>sum+file.size,0))+(root.selected?"  ·  1 SELECTED":"");color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:9}Layout.fillWidth:true;elide:Text.ElideRight}
            Text {visible:!root.compact;text:(ExplorerService.snapshot.branch?ExplorerService.snapshot.branch+"  ·  ":"")+(ExplorerService.snapshot.free===undefined?"":root.bytes(ExplorerService.snapshot.free)+" FREE");color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:9}}
        }
    }
    HexContextMenu {
        id:contextMenu
        onTriggered: action=> {
            if(action==="open")root.open(root.selected);
            else if(action==="terminal")DesktopState.terminalHere(root.selected&&root.selected.isDir?root.selected.path:DesktopState.folderPath);
            else if(action==="code"){if(root.selected&&!LauncherService.editFile(root.selected.path))ExplorerService.message="No editor installed.";}
            else if(action==="details")root.detailsOpen=true;
            else if(action==="refresh")ExplorerService.watch();
            else if(action==="hidden")root.showHidden=!root.showHidden;
            else if(action==="home")DesktopState.openFolder(DesktopState.home);
            else if(action==="up")DesktopState.up();
            else root.ask(action);
        }
    }
    ThemeDialog {
        id:actionDialog;anchors.centerIn:parent;width:Math.min(400,root.width-32);modal:true
        title:root.dialogAction==="trash"?"Move to Trash?":root.dialogAction==="mkdir"?"New folder":root.dialogAction==="rename"?"Rename":root.dialogAction==="copy"?"Copy to folder":"Move to folder"
        standardButtons:Dialog.Ok|Dialog.Cancel
        background:Rectangle{color:Theme.surfaceRaised;border{width:1;color:Theme.border}radius:Theme.cornerRadius}
        contentItem:Column {spacing:10
            Text {width:parent.width;text:root.dialogAction==="trash"?"Move "+(root.pending.name||"")+" to Trash?":root.dialogAction==="copy"||root.dialogAction==="move"?"Destination directory (existing files are never overwritten)":"Name";color:Theme.textMuted;wrapMode:Text.Wrap;font{family:Theme.fontFamily;pixelSize:11}}
            TextField {id:actionInput;width:parent.width;visible:root.dialogAction!=="trash";color:Theme.text;selectByMouse:true;background:Rectangle{color:Theme.background;border{width:1;color:Theme.border}}Keys.onReturnPressed:actionDialog.accept()}
        }
        onAccepted:ExplorerService.request(root.dialogAction,root.dialogAction==="mkdir"?DesktopState.folderPath:root.pending.path,{name:actionInput.text,target:actionInput.text.replace(/^~/,DesktopState.home)})
    }
    ThemeDialog {id:networkDialog;anchors.centerIn:parent;width:Math.min(380,root.width-32);title:"Network locations";modal:true;standardButtons:Dialog.Ok;background:Rectangle{color:Theme.surfaceRaised;border{width:1;color:Theme.border}}contentItem:Text{text:"Mounted network shares appear under Drives. Automatic SMB discovery is not installed.";color:Theme.textMuted;wrapMode:Text.Wrap;width:340}}
}
