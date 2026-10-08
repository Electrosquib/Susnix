pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id:root
    visible:DesktopState.launcherOpen&&LauncherModel.backdropReady||hideDelay.running
    anchors {top:true;bottom:true;left:true;right:true}
    exclusionMode:ExclusionMode.Ignore
    color:Theme.transparent
    WlrLayershell.namespace:"susnix-applications"
    WlrLayershell.layer:WlrLayer.Overlay
    WlrLayershell.keyboardFocus:DesktopState.launcherOpen?WlrKeyboardFocus.Exclusive:WlrKeyboardFocus.None
    property string group:"All"
    property string expandedFolder:""
    property var contextItem:null
    property var selectedApp:null
    readonly property bool searchMode:search.text.trim().length>0
    readonly property bool narrow:width<800
    readonly property var matches:LauncherModel.results(group,search.text)
    readonly property var browseItems:LauncherModel.browse(group)
    function close(): void {DesktopState.launcherOpen=false;}
    function activate(item: var): void {if(item.kind==="folder")expandedFolder=expandedFolder===item.id?"":item.id;else LauncherModel.open(item);}
    function context(item: var,position: var): void {contextItem=item;actions.popup(position||Qt.point(panel.x+panel.width/2,panel.y+130));}
    function appInfo(item: var): void {selectedApp=item;LauncherModel.info(item);}
    Connections {target:DesktopState;function onLauncherOpenChanged(): void {if(DesktopState.launcherOpen){root.group="All";root.expandedFolder="";root.selectedApp=null;search.text="";LauncherModel.prepare(root.screen?root.screen.name:"");}else {actions.close();hideDelay.restart();}}}
    Connections {target:LauncherModel;function onSettingsChanged(): void {if(root.expandedFolder&&!LauncherModel.settings.folders.some(f=>f.id===root.expandedFolder))root.expandedFolder="";}function onBackdropReadyChanged(): void {if(LauncherModel.backdropReady&&DesktopState.launcherOpen)Qt.callLater(()=>search.forceActiveFocus());}}
    Timer {id:hideDelay;interval:Theme.animationFast}
    Shortcut {sequence:"Escape";enabled:root.visible&&!renameFolder.opened;onActivated:if(actions.opened)actions.close();else if(search.text)search.clear();else root.close()}
    Item {
        id:veil;anchors.fill:parent
        opacity:DesktopState.launcherOpen&&LauncherModel.backdropReady?1:0
        Behavior on opacity {NumberAnimation{duration:Theme.animationFast;easing.type:Easing.OutCubic}}
        Image {anchors.fill:parent;source:LauncherModel.backdrop;fillMode:Image.Stretch;asynchronous:true;cache:false}
        Rectangle {anchors.fill:parent;color:Qt.alpha(Theme.background,LauncherModel.backdrop?.55:.92)}
        MouseArea {anchors.fill:parent;onClicked:root.close()}
        Rectangle {
            id:panel;anchors.centerIn:parent
            width:Math.min(1180,root.width-32);height:Math.min(860,root.height-Theme.barHeight-56)
            radius:Theme.cornerRadius+8;color:Qt.alpha(Theme.surface,Theme.opacityGlass)
            border{width:Theme.borderWidth;color:Qt.alpha(Theme.primary,.55)}
            MouseArea {anchors.fill:parent;onPressed:event=>event.accepted=true}
            ColumnLayout {
                anchors.fill:parent;anchors.margins:root.narrow?14:24;spacing:14
                RowLayout {
                    Layout.fillWidth:true
                    Text {text:"SUSNIX // LAUNCH";color:Theme.primary;font{family:Theme.fontFamily;pixelSize:11;letterSpacing:2}}
                    Item {Layout.fillWidth:true}
                    Text {text:"BROWSE · FIND · ACT";visible:!root.narrow;color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:10;letterSpacing:1}}
                    PanelButton {text:"×";Accessible.name:"Close launcher";onClicked:root.close()}
                }
                TextField {
                    id:search;Layout.fillWidth:true;Layout.preferredHeight:46
                    placeholderText:"Search apps, files, commands…";color:Theme.text;placeholderTextColor:Theme.textMuted;selectByMouse:true
                    font{family:Theme.fontFamily;pixelSize:15}
                    background:Rectangle{radius:Theme.cornerRadius+4;color:Qt.alpha(Theme.backgroundRaised,.8);border{width:Theme.borderWidth;color:search.activeFocus?Qt.alpha(Theme.primary,.65):Theme.border}}
                    onTextChanged:{if(text.trim()||root.group==="Files")LauncherModel.search(text);else LauncherModel.cancelSearch();results.currentIndex=0;root.selectedApp=null;}
                    onAccepted:{if(root.searchMode&&root.matches.length)LauncherModel.open(root.matches[Math.max(0,results.currentIndex)]);else if(LauncherModel.favorites.length)LauncherModel.open(LauncherModel.favorites[0]);}
                    Keys.onDownPressed:{if(root.matches.length)results.currentIndex=Math.min(root.matches.length-1,results.currentIndex+1);}
                    Keys.onUpPressed:{if(root.matches.length)results.currentIndex=Math.max(0,results.currentIndex-1);}
                    Keys.onMenuPressed:if(root.matches.length)root.context(root.matches[Math.max(0,results.currentIndex)])
                }
                RowLayout {
                    Layout.fillWidth:true;Layout.fillHeight:true;spacing:root.narrow?12:22
                    ScrollView {
                        Layout.preferredWidth:root.narrow?94:130;Layout.fillHeight:true;clip:true
                        Column {width:root.narrow?94:130;spacing:5
                            Repeater {model:["All","Favorites","Recent","Development","Internet","Media","System","Games","Files","Installed Apps"];delegate:PanelButton{
                                required property string modelData
                                width:parent.width;height:34;text:modelData==="Development"?"Dev":modelData==="Installed Apps"?"App info":modelData
                                tint:root.group===modelData?Theme.primary:Theme.textMuted
                                onClicked:{LauncherModel.notice="";root.group=modelData;root.expandedFolder="";root.selectedApp=null;if(modelData==="Files"||root.searchMode)LauncherModel.search(search.text);else LauncherModel.cancelSearch();results.currentIndex=0;}
                            }}
                            Rectangle {width:parent.width;height:1;color:Qt.alpha(Theme.border,.5)}
                            Text {width:parent.width;text:"Drag apps together\nto create a folder.\n\nDrag favorites\nto reorder.";color:Theme.textMuted;wrapMode:Text.Wrap;font{family:Theme.fontFamily;pixelSize:9}lineHeight:1.4}
                        }
                    }
                    Item {
                        visible:!root.narrow||!root.selectedApp
                        Layout.fillWidth:true;Layout.fillHeight:true
                        ScrollView {
                            id:browse;anchors.fill:parent;visible:!root.searchMode;clip:true
                            Column {
                                width:browse.availableWidth;spacing:16
                                Text {visible:root.group==="All";text:"FAVORITES";color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:10;letterSpacing:2}}
                                Flow {
                                    visible:root.group==="All";width:parent.width;spacing:5
                                    Repeater {model:LauncherModel.favorites;delegate:LauncherTile{required property var modelData;required property int index;item:modelData;width:Math.min(116,(browse.availableWidth-10)/3);onActivated:item=>root.activate(item);onContextRequested:(item,position)=>root.context(item,position);onAppDropped:(sourceId,target)=>LauncherModel.pin(sourceId,index)}}
                                    DropArea {width:80;height:102;keys:["susnix-app"];onDropped:event=>{const source=event.source as LauncherTile;if(source){LauncherModel.pin(source.item.id,LauncherModel.favorites.length);event.acceptProposedAction();}}Rectangle{anchors.fill:parent;anchors.margins:4;radius:Theme.cornerRadius;color:Theme.transparent;border{width:1;color:parent.containsDrag?Theme.primary:Qt.alpha(Theme.border,.3)}Text{anchors.centerIn:parent;text:"+ PIN";color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:9}}}}
                                }
                                Row {width:parent.width;spacing:8
                                    Text {text:root.group==="All"?"APPS":root.group.toUpperCase();color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:10;letterSpacing:2}}
                                    Text {text:root.browseItems.length;color:Theme.system;font{family:Theme.fontFamily;pixelSize:10}}
                                }
                                Flow {
                                    width:parent.width;spacing:5
                                    Repeater {model:root.browseItems;delegate:LauncherTile{
                                        required property var modelData;required property int index;item:modelData;width:Math.min(124,(browse.availableWidth-10)/3)
                                        onActivated:item=>{if(root.group==="Installed Apps")root.appInfo(item);else root.activate(item);}
                                        onContextRequested:(item,position)=>root.context(item,position)
                                        onAppDropped:(sourceId,target)=>{if(root.group==="Favorites")LauncherModel.pin(sourceId,index);else LauncherModel.groupApp(sourceId,target);}
                                    }}
                                }
                                Text {visible:!root.browseItems.length;text:root.group==="Files"&&LauncherModel.searching?"Indexing personal folders…":"Nothing here yet";color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:11}}
                                Rectangle {
                                    visible:!!root.expandedFolder; width:parent.width;height:folderContent.implicitHeight+24
                                    color:Qt.alpha(Theme.backgroundRaised,.7);radius:Theme.cornerRadius;border{width:1;color:Qt.alpha(Theme.secondary,.4)}
                                    Column {id:folderContent;anchors{left:parent.left;right:parent.right;top:parent.top;margins:12}spacing:12
                                        RowLayout {width:parent.width
                                            Text {text:(LauncherModel.settings.folders.find(f=>f.id===root.expandedFolder)||{}).name||"";color:Theme.secondary;font{family:Theme.fontFamily;pixelSize:12}Layout.fillWidth:true}
                                            PanelButton {text:"×";onClicked:root.expandedFolder=""}
                                        }
                                        Flow {width:parent.width;spacing:5
                                            Repeater {model:LauncherModel.folderItems(LauncherModel.settings.folders.find(f=>f.id===root.expandedFolder)||{apps:[]});delegate:LauncherTile{required property var modelData;item:modelData;onActivated:item=>root.activate(item);onContextRequested:(item,position)=>root.context(item,position)}}
                                        }
                                    }
                                }
                                Text {visible:root.group==="All";text:"RECENT";color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:10;letterSpacing:2}}
                                Flow {visible:root.group==="All";width:parent.width;spacing:5;Repeater{model:LauncherModel.recents.slice(0,6);delegate:LauncherTile{required property var modelData;item:modelData;draggable:false;onActivated:item=>root.activate(item);onContextRequested:(item,position)=>root.context(item,position)}}}
                                Text {visible:root.group==="All"&&!LauncherModel.recents.length;text:"Apps and files you open will appear here.";color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:11}}
                                Text {visible:root.group==="All";text:"QUICK ACTIONS";color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:10;letterSpacing:2}}
                                Flow {visible:root.group==="All";width:parent.width;spacing:6;Repeater{model:LauncherModel.commands.slice(0,6);delegate:PanelButton{required property var modelData;text:modelData.name;height:30;onClicked:LauncherModel.command(modelData.id)}}}
                            }
                        }
                        ListView {
                            id:results;anchors.fill:parent;visible:root.searchMode;clip:true;model:root.matches;currentIndex:0;spacing:4
                            highlightMoveDuration:Theme.animationFast
                            ScrollBar.vertical:ScrollBar{}
                            onCurrentIndexChanged:positionViewAtIndex(currentIndex,ListView.Contain)
                            delegate:Item {
                                id:row;required property var modelData;required property int index
                                readonly property bool heading:index===0||root.matches[index-1].section!==modelData.section
                                width:results.width;height:heading?88:62
                                Text {visible:row.heading;text:row.modelData.section;color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:9;letterSpacing:2}y:5}
                                Rectangle {
                                    y:row.heading?25:0;width:parent.width;height:58;radius:Theme.cornerRadius
                                    color:results.currentIndex===row.index?Qt.alpha(Theme.primary,.1):resultMouse.containsMouse?Qt.alpha(Theme.surfaceRaised,.7):Theme.transparent
                                    border{width:1;color:results.currentIndex===row.index?Qt.alpha(Theme.primary,.35):Theme.transparent}
                                    RowLayout {anchors.fill:parent;anchors.margins:10;spacing:12
                                        LauncherIcon {item:row.modelData;Layout.preferredWidth:24;Layout.preferredHeight:24}
                                        ColumnLayout {Layout.fillWidth:true;spacing:4
                                            Text {text:row.modelData.name;color:Theme.text;Layout.fillWidth:true;elide:Text.ElideRight;font{family:Theme.fontFamily;pixelSize:12}}
                                            Text {text:row.modelData.path||row.modelData.description||row.modelData.category||"";color:Theme.textMuted;Layout.fillWidth:true;elide:Text.ElideMiddle;font{family:Theme.fontFamily;pixelSize:10}}
                                        }
                                        PanelButton {text:"•••";onClicked:root.context(row.modelData)}
                                    }
                                    MouseArea {id:resultMouse;anchors{left:parent.left;right:parent.right;top:parent.top;bottom:parent.bottom;rightMargin:48}hoverEnabled:true;acceptedButtons:Qt.LeftButton|Qt.RightButton;onClicked:event=>{results.currentIndex=row.index;if(event.button===Qt.RightButton)root.context(row.modelData);else LauncherModel.open(row.modelData);}}
                                }
                            }
                        }
                    }
                    Rectangle {
                        visible:!!root.selectedApp;Layout.fillWidth:root.narrow;Layout.preferredWidth:root.narrow?170:230;Layout.fillHeight:true;radius:Theme.cornerRadius;color:Qt.alpha(Theme.backgroundRaised,.8);border{width:1;color:Qt.alpha(Theme.border,.5)}
                        ScrollView {id:infoScroll;anchors.fill:parent;anchors.margins:12;clip:true
                            Column {width:infoScroll.availableWidth;spacing:14
                                Text {width:parent.width;text:root.selectedApp?root.selectedApp.name:"";color:Theme.primary;wrapMode:Text.Wrap;font{family:Theme.fontFamily;pixelSize:14}}
                                Text {width:parent.width;text:root.selectedApp?[root.selectedApp.category,"Version",LauncherModel.appInfo.version||"Reading…","Executable",LauncherModel.appInfo.executable||"Internal shell view","Package",LauncherModel.appInfo.package||"User application","Desktop entry",LauncherModel.appInfo.desktop||root.selectedApp.id].join("\n"):"";color:Theme.textMuted;wrapMode:Text.WrapAnywhere;lineHeight:1.5;font{family:Theme.fontFamily;pixelSize:10}}
                                PanelButton {text:"OPEN";onClicked:if(root.selectedApp)LauncherModel.open(root.selectedApp)}
                                PanelButton {text:root.selectedApp&&LauncherModel.settings.favorites.includes(root.selectedApp.id)?"UNPIN":"PIN";onClicked:if(root.selectedApp)LauncherModel.togglePin(root.selectedApp.id)}
                                PanelButton {text:"CLOSE INFO";onClicked:root.selectedApp=null}
                            }
                        }
                    }
                }
                RowLayout {Layout.fillWidth:true
                    Text {Layout.fillWidth:true;text:LauncherModel.notice||(LauncherModel.searching&&root.searchMode?"Searching personal folders…":LauncherModel.indexLimited?"File index: first 50,000 entries / 2 seconds. Search roots are documented.":root.searchMode?root.matches.length+" RESULTS":"Right-click an app or file for actions");color:Theme.textMuted;elide:Text.ElideRight;font{family:Theme.fontFamily;pixelSize:9}}
                    Text {text:"ESC CLOSE  ·  ↵ OPEN";visible:!root.narrow;color:Theme.textMuted;font{family:Theme.fontFamily;pixelSize:9}}
                }
            }
        }
    }
    ThemeMenu {
        id:actions; width:240; font.family:Theme.fontFamily; font.pixelSize:11
        MenuItem {text:"Open";onTriggered:if(root.contextItem)root.activate(root.contextItem)}
        MenuItem {text:root.contextItem&&LauncherModel.settings.favorites.includes(root.contextItem.id)?"Unpin":"Pin";visible:!!root.contextItem&&root.contextItem.kind==="app";height:visible?implicitHeight:0;onTriggered:LauncherModel.togglePin(root.contextItem.id)}
        MenuItem {text:"Open as root…";visible:!!root.contextItem&&root.contextItem.kind==="app"&&!!root.contextItem.entry;height:visible?implicitHeight:0;onTriggered:LauncherModel.appAction(root.contextItem,"root")}
        MenuItem {text:"Open in workspace 2";visible:!!root.contextItem&&root.contextItem.kind==="app"&&!!root.contextItem.entry;height:visible?implicitHeight:0;onTriggered:LauncherModel.appAction(root.contextItem,"workspace")}
        MenuItem {text:"App info";visible:!!root.contextItem&&root.contextItem.kind==="app";height:visible?implicitHeight:0;onTriggered:root.appInfo(root.contextItem)}
        MenuItem {text:"Open in Code / editor";visible:!!root.contextItem&&root.contextItem.kind==="file";height:visible?implicitHeight:0;onTriggered:LauncherModel.fileAction(root.contextItem,"code")}
        MenuItem {text:"Open folder";visible:!!root.contextItem&&root.contextItem.kind==="file";height:visible?implicitHeight:0;onTriggered:LauncherModel.fileAction(root.contextItem,"folder")}
        MenuItem {text:"Copy path";visible:!!root.contextItem&&root.contextItem.kind==="file";height:visible?implicitHeight:0;onTriggered:LauncherModel.fileAction(root.contextItem,"copy-path")}
        MenuItem {text:"Run in Terminal…";visible:!!root.contextItem&&root.contextItem.kind==="file"&&!root.contextItem.isDir;height:visible?implicitHeight:0;onTriggered:LauncherModel.fileAction(root.contextItem,"run-file")}
        MenuItem {text:"Ask AI about file";visible:!!root.contextItem&&root.contextItem.kind==="file";height:visible?implicitHeight:0;onTriggered:LauncherModel.fileAction(root.contextItem,"ai")}
        MenuItem {text:"Rename app folder";visible:!!root.contextItem&&root.contextItem.kind==="folder";height:visible?implicitHeight:0;onTriggered:{folderName.text=root.contextItem.name;renameFolder.open();}}
        MenuItem {text:"Ungroup apps";visible:!!root.contextItem&&root.contextItem.kind==="folder";height:visible?implicitHeight:0;onTriggered:{LauncherModel.ungroup(root.contextItem.id);root.expandedFolder="";}}
    }
    ThemeDialog {id:renameFolder;width:Math.min(360,root.width-32);anchors.centerIn:parent;title:"App folder name";standardButtons:Dialog.Ok|Dialog.Cancel;modal:true;onOpened:{folderName.forceActiveFocus();folderName.selectAll();}contentItem:TextField{id:folderName;color:Theme.text;selectByMouse:true;onAccepted:renameFolder.accept()}onAccepted:LauncherModel.renameFolder(root.contextItem.id,folderName.text)}
}
