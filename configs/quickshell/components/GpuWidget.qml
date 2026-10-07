import QtQuick
import "../services"

ResourceWidget {
    label: "GPU"
    iconName: "gpu"
    Accessible.description: SystemStats.gpuDescription
    value: SystemStats.gpuUsage >= 0 ? SystemStats.gpuUsage + "%"
        : SystemStats.gpuStatus === "virtual" ? "VM"
        : SystemStats.gpuStatus === "error" ? "ERR" : "—"
}
