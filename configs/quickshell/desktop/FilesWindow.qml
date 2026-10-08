pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
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
    readonly property bool compact:height<430
    implicitWidth:Math.min(780,availableScreen?availableScreen.width-48:780)
    implicitHeight:Math.min(530,availableScreen?availableScreen.height-Theme.barHeight-100:530)
    minimumSize:Qt.size(410,300)
    maximumSize:Qt.size(Math.max(410,availableScreen?availableScreen.width-32:780),Math.max(300,availableScreen?availableScreen.height-Theme.barHeight-84:530))
    color:Theme.background
    onClosed:DesktopState.filesOpen=false
    onVisibleChanged:if(visible)DesktopState.recenterFiles()
    Connections {
        target:root.availableScreen
        function onWidthChanged(): void {if(root.visible)DesktopState.recenterFiles();}
        function onHeightChanged(): void {if(root.visible)DesktopState.recenterFiles();}
    }
    Connections {
        target:DesktopState
        function onFolderPathChanged(): void {filter.text="";files.currentIndex=-1;}
    }
    FolderListModel {
        id:folder
        folder:"file://"+DesktopState.folderPath.split("/").map(part=>encodeURIComponent(part)).join("/")
        showDotAndDotDot:false
        showHidden:hiddenButton.checked
        showDirsFirst:true
        caseSensitive:false
        sortField:FolderListModel.Name
        nameFilters:filter.text.length?["*"+filter.text+"*"]:[]
    }
    Rectangle {
        anchors.fill:parent
        gradient:Gradient {GradientStop {position:0;color:Theme.surfaceRaised} GradientStop {position:.2;color:Theme.backgroundRaised} GradientStop {position:1;color:Theme.background}}
        border {width:Theme.borderWidth;color:Qt.alpha(Theme.primary,.65)}
    }
    ColumnLayout {
        anchors.fill:parent;anchors.margins:14;spacing:root.compact?8:12
        Shortcut {sequence:"Escape";enabled:root.visible;onActivated:DesktopState.filesOpen=false}
        Shortcut {sequence:"Ctrl+L";enabled:root.visible;onActivated:{path.forceActiveFocus();path.selectAll();}}
        Shortcut {sequence:"Alt+Left";enabled:root.visible;onActivated:DesktopState.back()}
        Shortcut {sequence:"Alt+Up";enabled:root.visible;onActivated:DesktopState.up()}
        Shortcut {sequence:"Ctrl+H";enabled:root.visible;onActivated:hiddenButton.checked=!hiddenButton.checked}
        RowLayout {
            Layout.fillWidth:true;spacing:10
            Icon {name:"folder";color:Theme.primary;implicitWidth:18;implicitHeight:18}
            Text {text:"FILES // "+(DesktopState.folderPath===DesktopState.home?"HOME":DesktopState.folderPath.split("/").pop()||"ROOT");color:Theme.primary;font {family:Theme.fontFamily;pixelSize:11;letterSpacing:1} Layout.fillWidth:true;elide:Text.ElideRight}
            PanelButton {text:"Terminal";onClicked:DesktopState.terminalHere()}
            PanelButton {text:"×";tint:Theme.secondary;Accessible.name:"Close Files";onClicked:DesktopState.filesOpen=false}
        }
        RowLayout {
            Layout.fillWidth:true;spacing:6
            PanelButton {text:"‹";enabled:DesktopState.history.length>0;onClicked:DesktopState.back()}
            PanelButton {text:"↑";enabled:DesktopState.folderPath!=="/";onClicked:DesktopState.up()}
            TextField {
                id:path;Layout.fillWidth:true;Layout.preferredHeight:32
                text:DesktopState.folderPath;color:Theme.text;selectByMouse:true
                font {family:Theme.fontFamily;pixelSize:11}
                background:Rectangle {radius:Theme.cornerRadius;color:Theme.surface;border {width:Theme.borderWidth;color:Qt.alpha(Theme.border,.7)}}
                onAccepted:if(text.startsWith("/"))DesktopState.openFolder(text)
                Keys.onEscapePressed:root.visible=false
            }
        }
        RowLayout {
            Layout.fillWidth:true;Layout.fillHeight:true;spacing:12
    ColumnLayout {
                Layout.preferredWidth:root.width<560?94:132
                Layout.minimumWidth:root.width<560?94:132
                Layout.maximumWidth:root.width<560?94:132
                Layout.fillHeight:true;spacing:root.compact?2:4
                Text {visible:!root.compact;text:"QUICK ACCESS";color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:9;letterSpacing:.6} Layout.bottomMargin:8}
                Repeater {
                    model:DesktopState.locations
                    delegate:AbstractButton {
                        id:place
                        required property var modelData
                        Layout.fillWidth:true;implicitHeight:root.compact?22:34;hoverEnabled:true
                        Accessible.name:modelData.name
                        onClicked:{filter.text="";DesktopState.openFolder(modelData.path);}
                        background:Rectangle {radius:Theme.cornerRadius;color:place.hovered||DesktopState.folderPath===place.modelData.path?Qt.alpha(Theme.categoryColor(place.modelData.category),.17):Theme.transparent}
                        contentItem:Row {
                            spacing:8
                            NeonFolder {width:23;height:22;tint:Theme.categoryColor(place.modelData.category)}
                            Text {text:place.modelData.name;color:Theme.text;font {family:Theme.fontFamily;pixelSize:10} anchors.verticalCenter:parent.verticalCenter}
                        }
                    }
                }
                Item {Layout.fillHeight:true}
                PanelButton {id:hiddenButton;text:"Hidden files";checkable:true;Layout.fillWidth:true}
            }
            ColumnLayout {
                Layout.fillWidth:true;Layout.fillHeight:true;spacing:8
                TextField {
                    id:filter;Layout.fillWidth:true;Layout.preferredHeight:30;placeholderText:"Filter files…"
                    color:Theme.text;placeholderTextColor:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:11}
                    background:Rectangle {color:Theme.surface;radius:Theme.cornerRadius;border {width:Theme.borderWidth;color:Qt.alpha(Theme.border,.5)}}
                }
                GridView {
                    id:files
                    Layout.fillWidth:true;Layout.fillHeight:true
                    cellWidth:Math.max(98,Math.floor(width/Math.max(1,Math.floor(width/116))));cellHeight:root.compact?88:108
                    clip:true;model:folder
                    ScrollBar.vertical:ScrollBar {}
                    delegate:AbstractButton {
                        id:fileButton
                        required property int index
                        required property string fileName
                        required property string filePath
                        required property url fileUrl
                        required property bool fileIsDir
                        width:files.cellWidth-6;height:files.cellHeight-6;hoverEnabled:true
                        Accessible.name:fileName
                        onClicked:files.currentIndex=index
                        onDoubleClicked:{const target=filePath;const directory=fileIsDir;const url=fileUrl.toString();if(directory)DesktopState.openFolder(target);else DesktopState.openFile(url);}
                        Keys.onReturnPressed:if(fileIsDir)DesktopState.openFolder(filePath);else DesktopState.openFile(fileUrl.toString())
                        background:Rectangle {radius:Theme.cornerRadius;color:fileButton.hovered||files.currentIndex===fileButton.index?Qt.alpha(Theme.primary,.1):Theme.transparent;border {width:Theme.borderWidth;color:files.currentIndex===fileButton.index?Qt.alpha(Theme.primary,.6):Theme.transparent}}
                        contentItem:Column {
                            spacing:6
                            Item {
                                width:parent.width;height:root.compact?44:55
                                NeonFolder {visible:fileButton.fileIsDir;anchors.centerIn:parent;tint:fileButton.fileName.match(/Music|Videos/i)?Theme.media:fileButton.fileName.match(/Pictures/i)?Theme.browser:Theme.primary}
                                Icon {visible:!fileButton.fileIsDir;anchors.centerIn:parent;width:32;height:32;name:fileButton.fileName.match(/\.(png|jpg|jpeg|svg|webp)$/i)?"picture":"document";color:Theme.secondary}
                            }
                            Text {width:parent.width;text:fileButton.fileName;color:Theme.text;font {family:Theme.fontFamily;pixelSize:10} horizontalAlignment:Text.AlignHCenter;wrapMode:Text.Wrap;maximumLineCount:2;elide:Text.ElideRight}
                        }
                    }
                    Text {anchors.centerIn:parent;visible:folder.count===0&&folder.status===FolderListModel.Ready;text:filter.text?"No matching files":"This folder is empty";color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:11}}
                }
            }
        }
        RowLayout {
            Layout.fillWidth:true
            Text {text:folder.count+" items";color:Theme.textMuted;font {family:Theme.fontFamily;pixelSize:10} Layout.fillWidth:true}
            Text {text:"DOUBLE CLICK TO OPEN";color:Qt.alpha(Theme.primary,.7);font {family:Theme.fontFamily;pixelSize:9;letterSpacing:.6}}
        }
    }
}
