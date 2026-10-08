pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import "../theme"

Item {
    id: root
    property bool active: false
    property string error: ""
    property string notice: ""
    property string details: ""
    property bool lockAvailable: false
    property bool bluetoothAvailable:false
    property bool pairingAvailable: false
    property real brightness: -1
    readonly property string helper: Qt.resolvedUrl("desktop-control.sh").toString().replace(/^file:\/\//, "")
    readonly property var wifiDevices: Networking.devices.values.filter(device => device.type === DeviceType.Wifi)
    readonly property var wifi: wifiDevices[0] || null
    readonly property var networks: wifi ? wifi.networks.values.slice().sort((a,b) => Number(b.connected)-Number(a.connected) || b.signalStrength-a.signalStrength) : []
    readonly property var connectedDevices: Networking.devices.values.filter(device => device.connected)
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property var outputs: Pipewire.nodes.values.filter(node => node.audio && node.isSink && !node.isStream)
    readonly property var inputs: Pipewire.nodes.values.filter(node => node.audio && !node.isSink && !node.isStream)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool audioReady: sink !== null && sink.ready && sink.audio !== null
    readonly property real volume: audioReady ? sink.audio.volume*100 : -1
    readonly property bool muted: audioReady && sink.audio.muted
    // qmllint disable unresolved-type
    readonly property var adapter: bluetoothAvailable ? Bluetooth.defaultAdapter : null
    // qmllint enable unresolved-type
    readonly property var bluetoothDevices: adapter ? adapter.devices.values.slice().sort((a,b) => Number(b.connected)-Number(a.connected) || Number(b.paired)-Number(a.paired)) : []
    readonly property bool bluetoothEnabled: adapter !== null && adapter.enabled
    readonly property bool busy: action.running
    property var selectedNetwork: null
    PwObjectTracker { objects: [root.sink,root.source] }
    onActiveChanged: {
        if (active) refresh();
        else { details=""; selectedNetwork=null; }
    }
    // Scan only while the appropriate device sheet is open.
    onDetailsChanged: {
        for (const device of wifiDevices) device.scannerEnabled = active && details === "network";
        if (adapter) adapter.discovering = active && details === "bluetooth" && adapter.enabled;
        selectedNetwork=null; error=""; notice="";
    }
    onWifiChanged: if (wifi) wifi.scannerEnabled=active && details === "network"
    onBluetoothEnabledChanged: if (adapter) adapter.discovering=active && details === "bluetooth" && adapter.enabled
    onAdapterChanged: if (adapter) adapter.discovering = active && details === "bluetooth" && adapter.enabled
    function refresh(): void { if (!snapshot.running && !action.running) snapshot.running=true; }
    function run(args: var): void {
        if (busy) return;
        error=""; notice="";
        action.command=["bash",helper].concat(args); action.running=true;
    }
    function setVolume(percent: real): void {
        if (audioReady) sink.audio.volume=Math.max(0,Math.min(100,percent))/100;
    }
    function toggleMute(): void { if (audioReady) sink.audio.muted=!sink.audio.muted; }
    function setOutput(node: var): void { if (node) Pipewire.preferredDefaultAudioSink=node; }
    function setInput(node: var): void { if (node) Pipewire.preferredDefaultAudioSource=node; }
    function toggleWifi(): void { if (wifi && Networking.wifiHardwareEnabled) Networking.wifiEnabled=!Networking.wifiEnabled; }
    function toggleBluetooth(): void { if (adapter) adapter.enabled=!adapter.enabled; }
    function connectNetwork(network: var, password: string): void {
        error=""; selectedNetwork=network;
        if (network.connected) network.disconnect();
        else if ((network.known && !password) || network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe) network.connect();
        else if ([WifiSecurityType.WpaPsk,WifiSecurityType.Wpa2Psk,WifiSecurityType.Sae].includes(network.security)) network.connectWithPsk(password);
        else error="Configure an enterprise Wi-Fi profile in NetworkManager first.";
    }
    Connections {
        target: root.selectedNetwork
        function onConnectionFailed(reason: int): void { root.error="Wi-Fi: "+ConnectionFailReason.toString(reason); }
    }
    function connectBluetooth(device: var): void {
        if (device.paired) run(["bluetooth",device.dbusPath,device.connected?"Disconnect":"Connect"]);
        else if (pairingAvailable) run(["pairing"]);
        else error="Install blueman to pair devices and confirm PINs.";
    }
    function session(actionName: string): void {
        if (actionName === "lock") run(["lock",Theme.background.toString(),Theme.text.toString(),Theme.primary.toString()]);
        else if (["logout","reboot","poweroff"].includes(actionName)) run([actionName]);
    }
    Process {
        id: snapshot
        command: ["bash",root.helper,"snapshot"]
        stdout: StdioCollector {
            onStreamFinished: {
                const fields=text.trim().split("\n");
                root.lockAvailable=fields.includes("lock=1");
                root.pairingAvailable=fields.includes("pairing=1");
                root.bluetoothAvailable=fields.includes("bluetooth=1");
                const line=fields.find(value=>value.startsWith("brightness="));
                root.brightness=line ? Number(line.slice(11)) : -1;
            }
        }
    }
    Process {
        id: action
        stdout: StdioCollector {}
        stderr: StdioCollector { id: failures }
        // Qt tooling omits QProcess::ExitStatus; this signal is valid at runtime.
        // qmllint disable signal-handler-parameters
        onExited: code => {
            root.error=code === 0 ? "" : failures.text.trim().slice(0,180) || "Action failed. Check the service and permissions.";
            root.notice=code === 0 ? "Applied" : "";
            Qt.callLater(root.refresh);
        }
        // qmllint enable signal-handler-parameters
    }
    Timer { interval: 10000; running: root.active; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
