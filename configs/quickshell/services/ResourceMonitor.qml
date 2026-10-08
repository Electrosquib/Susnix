pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property bool detailActive: false
    onDetailActiveChanged: if (detailActive && !sampler.running) sampler.running=true
    property var settings: JSON.parse(defaults.text())
    property var previous: ({})
    property var sample: ({cpu:-1,gpu:-1,ram:-1,disk:-1,network:0,diskRate:0,memTotal:0,memUsed:0,groups:[],processes:[]})
    property var history: []
    property string error: ""
    property bool saving: false
    property var savedSettings: null
    readonly property var groups: settings.tasks
    readonly property string configPath: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/susnix/resource-tasks.json"
    readonly property string samplerPath: Qt.resolvedUrl("resource-snapshot.sh").toString().replace(/^file:\/\//, "")
    readonly property string collectorPath: Qt.resolvedUrl("collect.sh").toString().replace(/^file:\/\//, "")
    readonly property bool ready: sample.ram >= 0
    function classify(name: string): string {
        if (settings.assignments[name] && groups.some(group => group.id === settings.assignments[name])) return settings.assignments[name];
        const lower = name.toLowerCase();
        const match = groups.find(group => group.match.some(pattern => lower.includes(pattern.toLowerCase())));
        return match ? match.id : "system";
    }
    function assign(name: string, groupId: string): void {
        if (saving || !groups.some(group => group.id === groupId)) return;
        savedSettings = settings;
        settings = Object.assign({}, settings, {assignments:Object.assign({}, settings.assignments, {[name]:groupId})});
        saving = true;
        config.setText(JSON.stringify(settings,null,4)+"\n");
    }
    function loadConfig(data: string): void {
        if (saving) return;
        try {
            const value=JSON.parse(data);
            const roles=["dev","browser","ai","media","system"];
            if (!value || !Array.isArray(value.tasks) || !value.tasks.length || value.tasks.length>12 ||
                !value.tasks.some(group=>group.id==="system") || new Set(value.tasks.map(group=>group.id)).size!==value.tasks.length ||
                value.tasks.some(group=>typeof group.id!=="string" || !group.id || typeof group.name!=="string" || !roles.includes(group.category) || !Array.isArray(group.match) || group.match.some(pattern=>typeof pattern!=="string")) ||
                !value.assignments || typeof value.assignments!=="object" || Array.isArray(value.assignments)) throw new Error("invalid resource groups");
            settings=value; error="";
        } catch (failure) { error="Invalid resource groups; keeping previous settings"; }
    }
    function ingest(text: string): void {
        const next={time:Date.now(), uptime:0,total:0,idle:0,memTotal:0,memAvailable:0,networkBytes:0,disks:{},pids:{},gpuPids:{}};
        for (const line of text.trim().split("\n")) {
            const f=line.split("\t");
            if(f[0]==="T") next.uptime=Number(f[1]);
            if(f[0]==="C") { next.total=Number(f[1]); next.idle=Number(f[2]); }
            if(f[0]==="M") { next.memTotal=Number(f[1]); next.memAvailable=Number(f[2]); }
            if(f[0]==="N") next.networkBytes=Number(f[1]);
            if(f[0]==="D") next.disks[f[1]]={bytes:Number(f[2]),busy:Number(f[3])};
            if(f[0]==="P" && f.length>=8) next.pids[f[1]]={pid:Number(f[1]),start:f[2],name:f[3],ticks:Number(f[4]),rss:Math.max(0,Number(f[5])),read:Number(f[6]),write:Number(f[7])};
            if(f[0]==="G") next.gpuPids[f[1]]=(next.gpuPids[f[1]]||0)+Number(f[2]);
        }
        if (!next.memTotal || !next.uptime || !next.total) { error="Resource sample unavailable"; return; }
        const dt=next.uptime-(previous.uptime||next.uptime), delta=next.total-(previous.total||next.total);
        const countersValid=dt>0 && delta>0;
        const cpu=countersValid ? Math.max(0,Math.min(100,100*(1-(next.idle-previous.idle)/delta))) : -1;
        const memUsed=Math.max(0,next.memTotal-next.memAvailable);
        let diskBytes=0,diskBusy=-1;
        for (const [name,disk] of Object.entries(next.disks)) {
            const old=previous.disks && previous.disks[name];
            if (old && dt>0) { diskBytes+=Math.max(0,disk.bytes-old.bytes); diskBusy=Math.max(diskBusy,Math.min(100,Math.max(0,disk.busy-old.busy)/(dt*10))); }
        }
        const usage=groups.map(group=>({id:group.id,name:group.name,category:group.category,cpu:0,ram:0,disk:0,gpu:0}));
        const processes=[];
        for (const p of Object.values(next.pids)) {
            const old=previous.pids && previous.pids[String(p.pid)];
            const valid=old && old.start===p.start && countersValid;
            const pct=valid ? Math.max(0,p.ticks-old.ticks)/delta*100 : 0;
            const io=valid && old.read>=0 && p.read>=0 && old.write>=0 && p.write>=0 ? Math.max(0,p.read-old.read)+Math.max(0,p.write-old.write) : 0;
            const group=usage.find(entry=>entry.id===classify(p.name)) || usage.find(entry=>entry.id==="system");
            group.cpu+=pct;group.ram+=p.rss;group.disk+=io;group.gpu+=next.gpuPids[String(p.pid)]||0;
            processes.push({pid:p.pid,name:p.name,group:group.id,cpu:pct,ram:p.rss,disk:dt>0?io/dt:0,ioAvailable:p.read>=0});
        }
        const data={time:next.time,cpu:cpu,gpu:SystemStats.gpuUsage,ram:100*memUsed/next.memTotal,disk:diskBusy,
            diskRate:dt>0?diskBytes/dt:0,network:dt>0?Math.max(0,next.networkBytes-(previous.networkBytes||0))/dt:0,
            memUsed:memUsed,memTotal:next.memTotal,diskBytes:diskBytes,groups:usage,
            processes:processes.sort((a,b)=>b.cpu-a.cpu || b.ram-a.ram).slice(0,32),
            gpuAttributed:Object.keys(next.gpuPids).length>0};
        sample=data;
        history=history.concat([Object.assign({},data,{processes:[]})]).slice(-1800);
        previous=next; error="";
    }
    function segments(metric: string): var {
        const amount=metric==="ram" ? sample.memUsed : metric==="disk" ? sample.diskBytes : sample[metric];
        if (!(amount>0) || metric==="network") return [];
        const sum=sample.groups.reduce((total,group)=>total+group[metric],0);
        const scale=sum>amount ? amount/sum : 1;
        const entries=sample.groups.filter(group=>group[metric]>0).map(group=>({name:group.name,category:group.category,fraction:group[metric]*scale/amount}));
        const remainder=1-entries.reduce((total,entry)=>total+entry.fraction,0);
        if(remainder>0.001) entries.push({name:"Unattributed",category:"unattributed",fraction:remainder});
        return entries;
    }
    function bytes(value: real): string {
        if(value>=1073741824) return (value/1073741824).toFixed(1)+" GiB";
        if(value>=1048576) return (value/1048576).toFixed(1)+" MiB";
        if(value>=1024) return (value/1024).toFixed(0)+" KiB";
        return Math.round(value)+" B";
    }
    FileView { id: defaults; path: Qt.resolvedUrl("resource-tasks.json"); blockLoading:true }
    FileView {
        id: config; path: root.configPath; watchChanges:true; printErrors:false
        onFileChanged: reload()
        onLoaded: root.loadConfig(text())
        onSaved: { root.saving=false;root.savedSettings=null;Qt.callLater(reload); }
        onSaveFailed: { root.settings=root.savedSettings;root.savedSettings=null;root.saving=false;root.error="Could not save resource assignment"; }
    }
    Process {
        command:["bash",root.collectorPath,"init-resources",Qt.resolvedUrl("resource-tasks.json").toString().replace(/^file:\/\//, "")]
        running:true
        onRunningChanged: if(!running) config.reload()
    }
    Process {
        id: sampler
        command:["bash",root.samplerPath,root.detailActive?"full":"light"]
        stdout: StdioCollector { onStreamFinished: root.ingest(text) }
    }
    Timer { interval:root.detailActive?3000:15000;running:true;repeat:true;triggeredOnStart:true;onTriggered:if(!sampler.running) sampler.running=true }
}
