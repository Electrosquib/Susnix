import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "theme"
import "services"

ShellRoot {
    // Initialize monitor tracking before the first shortcut press.
    readonly property var focusedMonitor: Hyprland.focusedMonitor
    readonly property bool resourceSamplingReady: ResourceMonitor.ready
    IpcHandler {
        target: "bar"
        function reload(): void { Quickshell.reload(false); }
        function theme(name: string): void { ThemeManager.select(name); }
        function currentTheme(): string { return ThemeManager.currentTheme; }
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

    Variants {
        id: bars
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
        }
    }
}
