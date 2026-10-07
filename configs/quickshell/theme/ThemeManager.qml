pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    readonly property var availableThemes: ["Nyx", "Aurora", "Void", "Sakura", "Terminal", "Ember"]
    readonly property string configPath: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/susnix/colors.json"
    property var settings: ({theme: "Nyx", colors: {}, effects: {}})
    property var pendingSettings: null
    property bool saving: false
    property var previews: ({})
    property var activePalette: defaults
    readonly property string currentTheme: settings.theme
    readonly property var defaults: JSON.parse(nyx.text())
    readonly property var colors: Object.assign({}, defaults.colors, activePalette.colors, settings.colors)
    readonly property var effects: Object.assign({}, defaults.effects, activePalette.effects || {}, settings.effects)

    // Preview tiles read the same palette files as the active desktop.
    Repeater {
        model: root.availableThemes
        delegate: Item {
            id: preview
            required property string modelData
            FileView {
                path: Qt.resolvedUrl("themes/" + preview.modelData + ".json")
                watchChanges: true
                onFileChanged: reload()
                onLoaded: {
                    try {
                        const data = JSON.parse(text());
                        if (!root.validate(data)) throw new Error("invalid palette");
                        const updated = Object.assign({}, root.previews);
                        updated[preview.modelData] = Object.assign({}, root.defaults.colors, data.colors);
                        root.previews = updated;
                    } catch (error) { console.warn("Susnix theme preview: " + error); }
                }
            }
        }
    }

    function validate(data: var): bool {
        if (!data || typeof data !== "object" || Array.isArray(data)) return false;
        if (data.colors !== undefined) {
            if (!data.colors || typeof data.colors !== "object" || Array.isArray(data.colors)) return false;
            for (const key of Object.keys(data.colors)) {
                if (!Object.keys(defaults.colors).includes(key) || typeof data.colors[key] !== "string" || !/^#[0-9a-fA-F]{6}$/.test(data.colors[key])) return false;
            }
        }
        if (data.effects !== undefined) {
            if (!data.effects || typeof data.effects !== "object" || Array.isArray(data.effects)) return false;
            for (const key of Object.keys(data.effects)) {
                const value = data.effects[key];
                if (!Object.keys(defaults.effects).includes(key) || typeof value !== "number" || !Number.isFinite(value) || value < 0) return false;
                if (key.startsWith("opacity") || key === "glowStrength") {
                    if (value > 1) return false;
                } else if (!Number.isInteger(value) || value > 1000) return false;
            }
        }
        return true;
    }

    function readConfig(text: string): void {
        if (saving) return;
        try {
            const data = JSON.parse(text);
            if (!validate(data) || !availableThemes.includes(data.theme)) throw new Error("invalid theme, color, or effect");
            settings = data;
        } catch (error) {
            console.warn("Susnix colors.json: keeping last valid theme: " + error);
        }
    }

    function select(name: string): void {
        const match = availableThemes.find(theme => theme.toLowerCase() === name.toLowerCase());
        if (!match) { console.warn("Susnix: unknown theme " + name); return; }
        if (saving) return;
        if (currentTheme === match && !Object.keys(settings.colors || {}).length) return;
        // A palette switch clears color overrides; shared effect overrides persist.
        pendingSettings = Object.assign({}, settings, {theme: match, colors: {}});
        saving = true;
        config.setText(JSON.stringify(pendingSettings, null, 4) + "\n");
    }

    FileView {
        id: nyx
        path: Qt.resolvedUrl("themes/Nyx.json")
        blockLoading: true
    }
    FileView {
        path: Qt.resolvedUrl("themes/" + root.currentTheme + ".json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (!root.validate(data)) throw new Error("invalid palette");
                root.activePalette = data;
            } catch (error) { console.warn("Susnix palette: keeping last valid colors: " + error); }
        }
    }
    FileView {
        id: config
        path: root.configPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.readConfig(text())
        onSaved: {
            root.saving = false;
            root.settings = root.pendingSettings;
            root.pendingSettings = null;
            reload();
        }
        onSaveFailed: {
            root.saving = false;
            root.pendingSettings = null;
            console.warn("Susnix: cannot save " + root.configPath);
        }
    }
    Process {
        command: ["bash", Qt.resolvedUrl("../services/collect.sh").toString().replace(/^file:\/\//, ""), "init-theme", Qt.resolvedUrl("colors.json").toString().replace(/^file:\/\//, "")]
        running: true
        onRunningChanged: if (!running) config.reload()
        stderr: StdioCollector { onStreamFinished: if (text.trim()) console.warn("Susnix theme initialization: " + text.trim()) }
    }
}
