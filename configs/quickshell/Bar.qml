import QtQuick
import Quickshell
import Quickshell.Wayland
import "components"
import "theme"

// Quickshell registers the creatable PanelWindow backend at runtime.
// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: panel
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    color: Theme.transparent
    WlrLayershell.namespace: "susnix-bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    property bool controlOpen: false
    // Stay visible at login until the first hover; subsequent exits use normal autohide.
    property bool startupRevealed: true
    property bool pointerRevealed: false
    function toggleThemes(): void {
        const open = !logo.expanded;
        collapseDelay.stop();
        pointerRevealed = true;
        currentTask.historyOpen = false;
        // Finish the click and dismiss the previous focus grab before opening.
        Qt.callLater(() => {
            logo.expanded = open;
            if (!open && !panelHover.hovered) collapseDelay.restart();
        });
    }
    onControlOpenChanged: if (controlOpen) { logo.expanded = false; currentTask.historyOpen = false; }
    readonly property bool controlsRevealed: startupRevealed || pointerRevealed || controlOpen || logo.expanded || currentTask.historyOpen || currentTask.editing
    property real taskReveal: controlsRevealed || currentTask.pinned ? 1 : 0
    Behavior on taskReveal { NumberAnimation { duration: Theme.animationReveal; easing.type: Theme.revealEasing } }
    property real reveal: controlsRevealed ? 1 : 0
    Behavior on reveal { NumberAnimation { duration: Theme.animationReveal; easing.type: Theme.revealEasing } }
    // Only the top edge accepts input when all controls are collapsed.
    mask: Region {
        Region { x: 0; y: 0; width: panel.width; height: panel.controlsRevealed ? Theme.barSideHeight : 3 }
        Region { x: Math.floor(currentTask.x - 18); y: 0; width: Math.ceil(currentTask.width + 36); height: panel.controlsRevealed || currentTask.pinned ? Theme.barHeight : 0 }
    }
    HoverHandler {
        id: panelHover
        parent: panel.contentItem
        onHoveredChanged: {
            if (hovered) { collapseDelay.stop(); panel.pointerRevealed = true; panel.startupRevealed = false; }
            else collapseDelay.restart();
        }
    }

    Timer {
        id: collapseDelay
        interval: 350
        onTriggered: if (!panelHover.hovered) panel.pointerRevealed = false
    }

    // qmllint disable uncreatable-type
    PanelWindow {
    // qmllint enable uncreatable-type
        id:controlPopup
        screen: panel.screen
        anchors { top: true; bottom: true; right: true }
        // Quickshell's margins value has incomplete cross-module lint metadata.
        // qmllint disable unqualified unresolved-type
        margins { top: Theme.barSideHeight - Theme.borderWidth }
        // qmllint enable unqualified unresolved-type
        implicitWidth: Math.min(340, Math.max(1, panel.width*.45))
        // Ignore reserved zones; the explicit top margin already accounts for the bar.
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "susnix-control-center"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        color: Theme.transparent
        visible: panel.controlOpen || controlCenter.openProgress > 0
        contentItem.clip: true
        ControlCenter {
            id:controlCenter
            anchors.fill:parent
            opened:panel.controlOpen
            // Share the exact task bevel, in sidebar-local coordinates.
            topJoinOffset: currentTask.x + currentTask.width - (panel.width-controlPopup.width)
            onCloseRequested:panel.controlOpen=false
            onSettingsRequested:panel.toggleThemes()
        }
    }

    // Expand beneath the top-left color button without squeezing the bar.
    // qmllint disable uncreatable-type
    PopupWindow {
    // qmllint enable uncreatable-type
        id: themePopup
        anchor.window: panel
        anchor.rect.x: logo.x
        anchor.rect.y: Theme.barSideHeight
        implicitWidth: Math.min(306, panel.width - 2 * Theme.padding)
        implicitHeight: 48
        color: Theme.transparent
        // Interactive popups need Qt.Popup, rather than the default tooltip role.
        grabFocus: true
        visible: logo.expanded
        onVisibleChanged: {
            if (!visible && logo.expanded) logo.expanded = false;
            if (visible) Qt.callLater(themeContent.unfoldNow);
        }
        ThemeStrip {
            id: themeContent
            anchors.fill: parent
            onGlitchRequested: outline.triggerGlitch()
            property real openProgress: 0
            function unfoldNow(): void { openProgress = 0; themeUnfold.restart(); }
            opacity: openProgress
            transform: Translate { y: -4 * (1 - themeContent.openProgress) }
            NumberAnimation { id: themeUnfold; target: themeContent; property: "openProgress"; from: 0; to: 1; duration: Theme.animationReveal; easing.type: Theme.revealEasing }
        }
    }

    // qmllint disable uncreatable-type
    PopupWindow {
    // qmllint enable uncreatable-type
        id: historyPopup
        anchor.window: panel
        anchor.rect.x: Math.max(Theme.padding, Math.min(panel.width - width - Theme.padding, currentTask.x))
        anchor.rect.y: Theme.barHeight
        implicitWidth: Math.min(360, panel.width - 2 * Theme.padding)
        implicitHeight: Math.min(history.implicitHeight, Math.max(48, panel.screen ? panel.screen.height - Theme.barHeight - Theme.padding : history.implicitHeight))
        color: Theme.transparent
        grabFocus: true
        visible: currentTask.historyOpen
        onVisibleChanged: {
            if (!visible && currentTask.historyOpen) currentTask.historyOpen = false;
            if (visible) Qt.callLater(history.unfoldNow);
        }
        TaskHistory {
            id: history
            anchors.fill: parent
            onGlitchRequested: outline.triggerGlitch()
            property real openProgress: 0
            function unfoldNow(): void { openProgress = 0; unfold.restart(); }
            opacity: openProgress
            transform: Translate { y: -4 * (1 - history.openProgress) }
            NumberAnimation { id: unfold; target: history; property: "openProgress"; from: 0; to: 1; duration: Theme.animationReveal; easing.type: Theme.revealEasing }
        }
    }

    Item {
        anchors.fill: parent
        PanelDetails {
            id: outline
            anchors.fill: parent
            reveal: panel.reveal
            opacity: Math.max(panel.reveal, panel.taskReveal)
            transform: Translate { y: -Theme.barHeight * (1 - panel.taskReveal) }
            taskLeft: currentTask.x
            taskWidth: currentTask.width
            taskOpen: currentTask.historyOpen
        }
        BarBackground {
            opacity: panel.reveal * Theme.opacityBackdrop * (0.5 + 0.5 * Theme.glowStrength)
            x: Theme.borderWidth; y: Theme.borderWidth - Theme.barSideHeight * (1 - panel.reveal)
            width: parent.width - 2 * Theme.borderWidth
            height: Theme.barSideHeight - 2 * Theme.borderWidth
        }
        Item {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: Theme.barSideHeight
            opacity: panel.reveal
            enabled: panel.controlsRevealed
            transform: Translate { y: -Theme.barSideHeight * (1 - panel.reveal) }
            SusnixLogo {
                id: logo
                onToggleRequested: panel.toggleThemes()
                onGlitchRequested: outline.powerOn()
                anchors { left: parent.left; leftMargin: Theme.padding; verticalCenter: parent.verticalCenter }
            }
            PanelButton {
                objectName:"controlCenterButton"
                anchors {left:logo.right;leftMargin:6;verticalCenter:parent.verticalCenter}
                width:24;height:24
                Accessible.name:"Toggle control center"
                onClicked:panel.controlOpen=!panel.controlOpen
                contentItem:Item {Icon {name:"controls";anchors.centerIn:parent;color:Theme.primary}}
            }
            StatusArea {
                id: status
                anchors { right: parent.right; rightMargin: Theme.padding; verticalCenter: parent.verticalCenter }
                compact: panel.width < 1100
                maximumWidth: Math.max(0, (panel.width - Math.min(360, panel.width * 0.30)) / 2 - Theme.padding - 12)
            }
        }
        CurrentTask {
            id: currentTask
            onHistoryOpenChanged: if (historyOpen) logo.expanded = false;
            onGlitchRequested: if (historyOpen) outline.powerOn(); else outline.triggerGlitch()
            opacity: panel.taskReveal
            enabled: panel.controlsRevealed || currentTask.pinned
            visible: panel.taskReveal > 0
            transform: Translate { y: -Theme.barHeight * (1 - panel.taskReveal) }
            // Symmetric free space keeps the task on the monitor's true center.
            anchors.centerIn: parent
            anchors.alignWhenCentered: false
            property real focusExpansion: editing || historyOpen ? 6 : 0
            Behavior on focusExpansion { NumberAnimation { duration: Theme.animationReveal; easing.type: Theme.revealEasing } }
            width: Math.min(360, panel.width * 0.30) + focusExpansion
        }
    }
}
