pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: root
    property string error: ""
    readonly property var applications: DesktopEntries.applications.values.filter(entry=>!entry.noDisplay).slice().sort((a,b)=>a.name.localeCompare(b.name))
    function entry(ids: var, category: string): var {
        for(const id of ids) { const found=DesktopEntries.byId(id);if(found) return found; }
        return applications.find(app=>app.categories.includes(category)) || null;
    }
    function launch(app: var): bool {
        if(!app || !app.command.length) { error="Application is unavailable";return false; }
        // Quickshell execute ignores Terminal=true; wrap terminal apps explicitly.
        const command=app.runInTerminal ? ["foot","-e"].concat(app.command) : app.command;
        Quickshell.execDetached({command:command,workingDirectory:app.workingDirectory});error="";return true;
    }
    function openAi(): void { Quickshell.execDetached(["xdg-open","https://chatgpt.com"]); }
}
