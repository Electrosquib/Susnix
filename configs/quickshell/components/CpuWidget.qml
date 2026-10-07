import QtQuick
import "../services"

ResourceWidget {
    label: "CPU"
    iconName: "cpu"
    value: SystemStats.cpuUsage < 0 ? "—" : SystemStats.cpuUsage + "%"
}
