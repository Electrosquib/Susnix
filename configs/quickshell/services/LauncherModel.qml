pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

Item {
    id:root
    readonly property string helper:Qt.resolvedUrl("launcher-backend.py").toString().replace(/^file:\/\//,"")
    property var settings:({initialized:false,favorites:[],folders:[],recent:[]})
    property bool loaded:false
    property string query:""
    property var files:[]
    property bool indexLimited:false
    property string notice:""
    property var appInfo:({})
    property string infoId:""
    property bool backdropReady:false
    property string backdrop:""
    property string monitor:""
    readonly property bool searching:searcher.running||searchDelay.running
    readonly property var apps:[{kind:"app",id:"susnix:files",name:"Files",icon:"system-file-manager",fallback:"folder",category:"System",entry:null}].concat(LauncherService.applications.map(app=>({kind:"app",id:app.id,name:app.name,icon:app.icon,fallback:fallback(app),category:category(app.categories),entry:app})))
    readonly property var favorites:settings.favorites.map(id=>find(id)).filter(Boolean)
    readonly property var recents:settings.recent.map(item=>item.kind==="app"?find(item.id):item).filter(Boolean)
    readonly property var commands:[
        {id:"terminal",name:"Open terminal here",description:DesktopState.folderPath,icon:"terminal",category:"Development"},
        {id:"radar-code",name:"Open radar project in Code",description:Quickshell.env("HOME")+"/Radar",icon:"editor",category:"Development"},
        {id:"radar-workspace",name:"Open radar workspace",description:"Terminal on workspace 2",icon:"folder",category:"Development"},
        {id:"bluetooth-off",name:"Bluetooth off",description:"Turn off the Bluetooth adapter",icon:"bluetooth",category:"System"},
        {id:"restart-audio",name:"Restart audio",description:"Restart PipeWire and WirePlumber",icon:"audio",category:"System"},
        {id:"update",name:"Update Susnix",description:"Review Arch package updates in Terminal",icon:"download",category:"System"},
        {id:"theme:Nyx",name:"Dark theme · Nyx",description:"Cyan / violet / magenta",icon:"controls",category:"System"}
    ].concat(ThemeManager.availableThemes.filter(t=>t!=="Nyx").map(t=>({id:"theme:"+t,name:"Theme · "+t,description:"Change the global desktop palette",icon:"controls",category:"System"})))
    function fallback(app: var): string {
        const name=app.name.toLowerCase();
        if(/term|foot|kitty/.test(name))return "terminal";
        if(/code|vim|editor/.test(name))return "editor";
        if(/firefox|chrome|browser/.test(name))return "browser";
        if(/ssh|vnc|network/.test(name))return "network";
        if(/htop|monitor/.test(name))return "cpu";
        return "apps";
    }
    function category(categories: var): string {
        if(categories.includes("Development")||categories.includes("TextEditor")||categories.includes("TerminalEmulator"))return "Development";
        if(categories.includes("Network")||categories.includes("WebBrowser"))return "Internet";
        if(categories.includes("AudioVideo")||categories.includes("Audio")||categories.includes("Video")||categories.includes("Graphics"))return "Media";
        if(categories.includes("Game"))return "Games";
        return "System";
    }
    function tint(group: string): color {return group==="AI"?Theme.ai:group==="Development"?Theme.dev:group==="Internet"?Theme.browser:group==="Media"?Theme.media:group==="Games"?Theme.secondary:Theme.system;}
    function find(id: string): var {return apps.find(a=>a.id===id)||null;}
    function folderItems(folder: var): var {return folder.apps.map(id=>find(id)).filter(Boolean);}
    function browse(group: string): var {
        if(group==="Favorites")return favorites;
        if(group==="Recent")return recents;
        if(group==="Files")return files;
        const assigned=[];for(const folder of settings.folders)for(const id of folder.apps)assigned.push(id);
        const folders=settings.folders.map(f=>({kind:"folder",id:f.id,name:f.name,icon:"folder",category:"System",folder:f}));
        if(group==="All")return folders.concat(apps.filter(a=>!assigned.includes(a.id)));
        if(group==="Installed Apps")return apps;
        return apps.filter(a=>a.category===group);
    }
    function score(item: var, term: string): int {
        const name=item.name.toLowerCase();const extra=item.entry?(item.entry.genericName+" "+item.entry.comment+" "+item.entry.keywords.join(" ")):item.description||"";
        if(name===term)return 100;if(name.startsWith(term))return 80;if(name.includes(term))return 60;
        if(extra.toLowerCase().includes(term))return 40;
        let at=0;for(const c of name)if(c===term[at])at++;return at===term.length?20:0;
    }
    function results(group: string, term: string): var {
        term=term.trim().toLowerCase();if(!term)return [];
        const applications=apps.filter(a=>score(a,term)>0).sort((a,b)=>score(b,term)-score(a,term));
        let items=[];
        if(group!=="Files")items=items.concat(applications.filter(a=>["All","Favorites","Recent","Installed Apps"].includes(group)?(group!=="Favorites"||settings.favorites.includes(a.id))&&(group!=="Recent"||settings.recent.some(r=>r.kind==="app"&&r.id===a.id)):a.category===group).map(a=>Object.assign({},a,{section:"APPS"})));
        if(group==="Recent")items=items.concat(recents.filter(f=>f.kind==="file"&&(f.name.toLowerCase().includes(term)||f.path.toLowerCase().includes(term))).map(f=>Object.assign({},f,{section:"FILES"})));
        else if(["All","Files"].includes(group))items=items.concat(files.map(f=>Object.assign({},f,{section:"FILES"})));
        if(group==="All"||group==="System")items=items.concat(commands.filter(c=>score(c,term)>=40).map(c=>Object.assign({},c,{kind:"command",section:"COMMANDS"})));
        if(group==="All")items=items.concat([{kind:"web",id:"web",name:"Search the web for “"+query+"”",icon:"browser",category:"Internet",section:"WEB / AI"},{kind:"ai",id:"ai",name:"Ask Susnix AI about “"+query+"”",icon:"ai",category:"AI",section:"WEB / AI"}]);
        return items;
    }
    function changed(): void {saveDelay.restart();}
    function pin(id: string, at: int): void {
        const list=settings.favorites.filter(x=>x!==id);list.splice(Math.max(0,Math.min(at,list.length)),0,id);
        settings=Object.assign({},settings,{favorites:list});changed();
    }
    function togglePin(id: string): void {
        if(settings.favorites.includes(id)){settings=Object.assign({},settings,{favorites:settings.favorites.filter(x=>x!==id)});changed();}
        else pin(id,settings.favorites.length);
    }
    function groupApp(source: string,target: var): void {
        if(source===target.id||!find(source)||target.kind==="file")return;
        let folders=settings.folders.map(f=>Object.assign({},f,{apps:f.apps.filter(id=>id!==source)}));
        if(target.kind==="folder")folders=folders.map(f=>f.id===target.id?Object.assign({},f,{apps:f.apps.concat([source])}):f);
        else if(find(target.id)) {
            folders=folders.map(f=>Object.assign({},f,{apps:f.apps.filter(id=>id!==target.id)}));
            folders.push({id:"folder:"+Date.now(),name:find(source).category===target.category?target.category:"Apps",apps:[target.id,source]});
        }
        settings=Object.assign({},settings,{folders:folders.filter(f=>f.apps.length)});changed();
    }
    function renameFolder(id: string,name: string): void {if(!name.trim())return;settings=Object.assign({},settings,{folders:settings.folders.map(f=>f.id===id?Object.assign({},f,{name:name.trim().slice(0,80)}):f)});changed();}
    function ungroup(id: string): void {settings=Object.assign({},settings,{folders:settings.folders.filter(f=>f.id!==id)});changed();}
    function remember(item: var): void {
        if(!loaded||!item)return;
        const recent=settings.recent.filter(x=>x.id!==item.id);recent.unshift({kind:item.kind,id:item.id,name:item.name,path:item.path||"",isDir:!!item.isDir,time:Date.now()});
        settings=Object.assign({},settings,{recent:recent.slice(0,32)});changed();
    }
    function rememberFile(path: string,isDir: bool): void {remember({kind:"file",id:path,path:path,name:path.split("/").pop()||"/",isDir:isDir});}
    function prepare(output: string): void {
        monitor=output;query="";files=[];notice="";backdropReady=false;backdrop="";
        capture.running=false;Qt.callLater(()=>capture.running=true);captureTimeout.restart();DesktopService.refresh();
    }
    function cancelSearch(): void {query="";files=[];notice="";indexLimited=false;searchDelay.stop();searcher.running=false;}
    function search(term: string): void {query=term.trim();notice="";files=[];searcher.running=false;searchDelay.restart();}
    function info(item: var): void {
        infoId=item.id;appInfo={};metadata.running=false;
        metadata.command=["python",helper,JSON.stringify({action:"info",id:item.id,command:item.entry?item.entry.command:[]})];Qt.callLater(()=>metadata.running=true);
    }
    function run(data: var): bool {if(action.running){notice="An action is already running.";return false;}notice="";action.command=["python",helper,JSON.stringify(data)];action.running=true;return true;}
    function open(item: var): void {
        if(item.kind==="app"){
            if(item.id==="susnix:files"){remember(item);DesktopState.openFolder(DesktopState.home);}
            else if(!LauncherService.launch(item.entry)){notice=LauncherService.error;return;}
        }else if(item.kind==="file"){
            if(item.isDir)DesktopState.openFolder(item.path);else DesktopState.openFile("file://"+item.path.split("/").map(encodeURIComponent).join("/"));
        }else if(item.kind==="command"){command(item.id);return;}
        else if(item.kind==="web"){if(!webAvailable())return;Quickshell.execDetached(["xdg-open","https://www.google.com/search?q="+encodeURIComponent(query)]);}
        else if(item.kind==="ai"){askAi(query);return;}
        DesktopState.launcherOpen=false;
    }
    function webAvailable(): bool {
        if(LauncherService.applications.some(a=>a.categories.includes("WebBrowser")))return true;
        notice="Install a browser (the desktop package set includes Firefox) to open web and AI results.";return false;
    }
    function askAi(prompt: string): void {
        if(!webAvailable())return;
        // The existing assistant is a placeholder; carry the request to the web AI.
        if(!run({action:"copy-path",path:prompt}))return;Quickshell.execDetached(["xdg-open","https://chatgpt.com/?q="+encodeURIComponent(prompt)]);DesktopState.launcherOpen=false;
    }
    function appAction(item: var,mode: string): void {
        if(mode==="pin"){togglePin(item.id);return;}
        if(mode==="info"){info(item);return;}
        if(!item.entry)return;
        const args=mode==="root"?(item.entry.categories.includes("TerminalEmulator")?["bash","-l"]:item.entry.command):LauncherService.commandFor(item.entry);
        if(!run({action:mode,command:args,workspace:2}))return;remember(item);DesktopState.launcherOpen=false;
    }
    function fileAction(item: var,mode: string): void {
        if(mode==="copy-path"){run({action:mode,path:item.path});return;}
        if(mode==="code"){if(!LauncherService.editFile(item.path)){notice="No editor installed.";return;}remember(item);}
        else if(mode==="folder"){DesktopState.openFolder(item.isDir?item.path:item.path.slice(0,item.path.lastIndexOf("/"))||"/");}
        else if(mode==="run-file"){if(!run({action:mode,path:item.path}))return;}
        else if(mode==="ai"){if(!webAvailable())return;aiContext.command=["python",helper,JSON.stringify({action:"ai-context",path:item.path})];aiContext.running=true;return;}
        DesktopState.launcherOpen=false;
    }
    function command(id: string): void {
        if(id.startsWith("theme:")){ThemeManager.select(id.slice(6));notice="Theme applied";return;}
        if(id==="terminal")DesktopState.terminalHere(DesktopState.folderPath);
        else if(id==="radar-code"){if(!LauncherService.editFile(Quickshell.env("HOME")+"/Radar")){notice="No editor installed.";return;}}
        else if(id==="radar-workspace"){if(!run({action:"workspace",workspace:2,command:[Quickshell.env("HOME")+"/.local/bin/susnix-terminal","--working-directory",Quickshell.env("HOME")+"/Radar"]}))return;}
        else if(id==="bluetooth-off"){if(DesktopService.adapter)DesktopService.adapter.enabled=false;else {notice="No Bluetooth adapter available.";return;}}
        else if(!run({action:id}))return;
        DesktopState.launcherOpen=false;
    }
    Connections {target:DesktopState;function onLauncherOpenChanged(): void {if(!DesktopState.launcherOpen){searchDelay.stop();searcher.running=false;captureTimeout.stop();}}}
    Process {
        id:loadState;running:true;command:["python",root.helper,'{"action":"load"}']
        stdout:StdioCollector {onStreamFinished:{try{const data=JSON.parse(text);if(data.error)throw new Error(data.error);root.settings=data.state;root.loaded=true;root.initialize();}catch(e){root.notice="Cannot read launcher settings: "+e;}}}
    }
    function initialize(): void {
        if(!loaded||settings.initialized||apps.length<2)return;
        const ids=[];
        for(const choices of [["code","codium","vim"],["susnix-terminal","foot","kitty"],["firefox","org.mozilla.firefox","chromium"]]){
            let chosen=null;for(const id of choices){chosen=find(id);if(chosen)break;}if(chosen)ids.push(chosen.id);
        }
        ids.push("susnix:files");settings=Object.assign({},settings,{initialized:true,favorites:ids});changed();
    }
    onAppsChanged:initialize()
    Timer {id:saveDelay;interval:100;onTriggered:if(saveState.running)restart();else {saveState.command=["python",root.helper,JSON.stringify({action:"save",state:root.settings})];saveState.running=true;}}
    Process {id:saveState;stdout:StdioCollector{onStreamFinished:{try{const data=JSON.parse(text);if(data.error)root.notice=data.error;}catch(e){root.notice="Cannot save launcher settings.";}}}}
    Timer {id:searchDelay;interval:120;onTriggered:{searcher.command=["python",root.helper,JSON.stringify({action:"search",query:root.query.trim().slice(0,160)})];searcher.running=true;}}
    Process {id:searcher;stdout:StdioCollector{onStreamFinished:{try{const data=JSON.parse(text);if(data.error){root.notice=data.error;return;}if(data.query!==root.query.trim().slice(0,160))return;root.files=data.files||[];root.indexLimited=!!data.limited;if(data.error)root.notice=data.error;}catch(e){}}}}
    Process {id:metadata;stdout:StdioCollector{onStreamFinished:{try{const data=JSON.parse(text);if(data.id===root.infoId)root.appInfo=data;else if(data.error){root.appInfo={version:"Unavailable"};root.notice=data.error;}}catch(e){if(text.trim()){root.appInfo={version:"Unavailable"};root.notice="Cannot read app information.";}}}}}
    Timer {id:captureTimeout;interval:250;onTriggered:root.backdropReady=true}
    Process {id:capture;command:["python",root.helper,JSON.stringify({action:"backdrop",monitor:root.monitor})];stdout:StdioCollector{onStreamFinished:{if(!text.trim()||!DesktopState.launcherOpen)return;try{const data=JSON.parse(text);root.backdrop=data.image||"";}catch(e){}root.backdropReady=true;captureTimeout.stop();}}}
    Process {id:aiContext;stdout:StdioCollector{onStreamFinished:{try{const data=JSON.parse(text);if(data.error)root.notice=data.error;else root.askAi(data.prompt);}catch(e){root.notice="Cannot prepare the AI context.";}}}}
    Process {id:action;stdout:StdioCollector{onStreamFinished:{try{const data=JSON.parse(text);if(data.error){if(!DesktopState.launcherOpen)DesktopState.launcherOpen=true;root.notice=data.error;}else root.notice="Applied";}catch(e){root.notice="Action failed.";}}}}
}
