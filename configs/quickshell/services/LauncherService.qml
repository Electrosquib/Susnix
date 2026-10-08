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
    function commandFor(app: var): var {
        // Quickshell execute ignores Terminal=true; wrap terminal apps explicitly.
        const terminal=["bash",Qt.resolvedUrl("open-terminal.sh").toString().replace(/^file:\/\//,"")];
        if(app.runInTerminal)return terminal.concat(["-e"],app.command);
        const program=app.command[0].split("/").pop();
        return app.command.length===1&&["foot","susnix-terminal"].includes(program)?terminal:app.command;
    }
    function launch(app: var): bool {
        if(!app || !app.command.length) { error="Application is unavailable";return false; }
        Quickshell.execDetached({command:commandFor(app),workingDirectory:app.workingDirectory});error="";return true;
    }
    function editFile(path: string): bool {
        const app=entry(["code","codium","org.kde.kate","vim"],"TextEditor");
        if(!app || !app.command.length)return false;
        Quickshell.execDetached({command:commandFor(app).concat(["--",path]),workingDirectory:app.workingDirectory});return true;
    }
    function openAi(): void { Quickshell.execDetached(["xdg-open","https://chatgpt.com"]); }
}
