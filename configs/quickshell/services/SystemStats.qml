pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Networking

// One collector shared by every monitor. UI components only consume properties.
Item {
    id: root
    property int cpuUsage: -1
    property int gpuUsage: -1
    property string gpuStatus: "unavailable"
    readonly property string gpuDescription: gpuStatus === "virtual"
        ? "Virtual GPU: this guest driver does not expose utilization; host GPU usage is unavailable."
        : gpuStatus === "error" ? "GPU utilization provider failed or returned no valid reading."
        : gpuUsage >= 0 ? "Busiest supported GPU utilization."
        : "This GPU does not expose a supported utilization counter."
    property bool visualActive: true
    onVisualActiveChanged: if (visualActive) cpu.reload()
    readonly property int volume: DesktopService.audioReady ? Math.round(DesktopService.volume) : -1
    readonly property bool muted: DesktopService.muted
    readonly property string network: DesktopService.connectedDevices.some(device=>device.type===DeviceType.Wifi) ? "WiFi"
        : DesktopService.connectedDevices.some(device=>device.type===DeviceType.Wired) ? "Wired" : "Offline"
    property real previousNetworkBytes: -1
    property int networkActivitySerial: 0
    property real previousTotal: -1
    property real previousIdle: -1
    readonly property string collector: Qt.resolvedUrl("collect.sh").toString().replace(/^file:\/\//, "")

    function readCpu(data: string): void {
        const fields = data.split("\n")[0].trim().split(/\s+/);
        if (fields[0] !== "cpu" || fields.length < 9) {
            cpuUsage = -1;
            return;
        }
        // guest and guest_nice are already included in user/nice: omit them.
        const values = fields.slice(1, 9).map(Number);
        if (values.some(value => !Number.isFinite(value))) return;
        const total = values.reduce((sum, value) => sum + value, 0);
        const idle = values[3] + values[4];
        const delta = total - previousTotal;
        if (previousTotal >= 0 && delta > 0 && idle >= previousIdle)
            cpuUsage = Math.max(0, Math.min(100, Math.round(100 * (1 - (idle - previousIdle) / delta))));
        else cpuUsage = -1;
        previousTotal = total;
        previousIdle = idle;
    }

    function readGpu(data: string): void {
        const values = data.trim().split(/\s+/).filter(value => /^\d+$/.test(value)).map(Number);
        // Multi-GPU machines show the busiest supported GPU.
        gpuUsage = values.length ? Math.min(100, Math.max(...values)) : -1;
        gpuStatus = gpuUsage >= 0 ? "available"
            : data.trim() === "virtual" ? "virtual"
            : data.trim() === "error" ? "error" : "unavailable";
    }

    function readTraffic(data: string): void {
        let total = 0;
        for (const line of data.split("\n")) {
            const parts = line.split(":");
            if (parts.length !== 2 || parts[0].trim() === "lo") continue;
            const fields = parts[1].trim().split(/\s+/).map(Number);
            if (fields.length >= 9 && Number.isFinite(fields[0]) && Number.isFinite(fields[8])) total += fields[0] + fields[8];
        }
        if (previousNetworkBytes >= 0 && total > previousNetworkBytes) networkActivitySerial++;
        previousNetworkBytes = total;
    }

    FileView {
        id: cpu
        path: "/proc/stat"
        printErrors:false
        onLoaded:root.readCpu(text())
    }
    Process {
        id: gpu
        command: ["bash", root.collector, "gpu"]
        stdout: StdioCollector { onStreamFinished: root.readGpu(text) }
    }
    FileView {
        id: traffic
        path: "/proc/net/dev"
        printErrors:false
        onLoaded:root.readTraffic(text())
    }
    Timer {
        interval: 1000; running: root.visualActive; repeat: true; triggeredOnStart: true
        onTriggered: {
            cpu.reload();
        }
    }
    Timer {
        interval:root.gpuStatus === "virtual" || root.gpuStatus === "unavailable" ? 30000 : 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            if (!gpu.running) gpu.running = true;
        }
    }
    Timer { interval:2000;running:root.visualActive;repeat:true;onTriggered:traffic.reload() }
}
