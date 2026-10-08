pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import "theme"
import "services"
import "desktop"

ShellRoot {
    id:root
    // Initialize monitor tracking before the first shortcut press.
    readonly property var focusedMonitor: Hyprland.focusedMonitor
    readonly property bool resourceSamplingReady: ResourceMonitor.ready
    readonly property var desktopColors: DesktopAppearance.colors
    readonly property bool controlCenterOpen: bars.instances.some(panel => panel.controlOpen)
    readonly property bool barRevealed: bars.instances.some(panel => panel.controlsRevealed)
    Binding { target:DesktopService; property:"active"; value:root.controlCenterOpen }
    Binding { target:ResourceMonitor; property:"detailActive"; value:root.controlCenterOpen }
    Binding { target:SystemStats; property:"visualActive"; value:root.barRevealed }
    IpcHandler {
        target: "bar"
        function reload(): void { Quickshell.reload(false); }
        function theme(name: string): void { ThemeManager.select(name); }
        function currentTheme(): string { return ThemeManager.currentTheme; }
        function files(): void { DesktopState.openFolder(DesktopState.home); }
        function applications(): void { DesktopState.launcherOpen = !DesktopState.launcherOpen; }
        function isLauncherOpen(): string { return DesktopState.launcherOpen ? "true" : "false"; }
        function refreshAppearance(): void { DesktopAppearance.refresh(); }
        function toggleControl(): void {
            const focused = Hyprland.focusedMonitor;
            let panel = null;
            for (const instance of bars.instances) {
                if (!panel) panel = instance;
                if (focused && instance.screen.name === focused.name) { panel = instance; break; }
            }
            if (!panel) return;
            const open = !panel.controlOpen;
            for (const instance of bars.instances) instance.controlOpen = instance === panel && open;
        }
    }

    FilesWindow {}
    AppDrawer { screen: root.focusedMonitor ? Quickshell.screens.find(s => s.name === root.focusedMonitor.name) : Quickshell.screens[0] }
    Variants {
        model: Quickshell.screens
        DesktopBackground {
            required property var modelData; screen:modelData
            onControlRequested: {
                for(const panel of bars.instances)if(panel.screen.name===screen.name)panel.controlOpen=true;
            }
        }
    }
    Variants {
        model: Quickshell.screens
        DesktopDock {
            required property var modelData
            screen:modelData
            onControlRequested: {
                for (const panel of bars.instances) if (panel.screen.name === screen.name) panel.controlOpen = !panel.controlOpen;
            }
        }
    }

    Variants {
        id: bars
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
        }
    }
}
