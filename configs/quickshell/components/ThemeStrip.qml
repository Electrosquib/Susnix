pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../theme"

PanelCard {
    id: root
    signal glitchRequested()
    readonly property alias themeTiles: tiles
    implicitWidth: 306
    implicitHeight: 48
    radius: Theme.cornerRadius
    Flickable {
        anchors.fill: parent
        anchors.margins: 8
        contentWidth: tiles.width
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        Row {
            id: tiles
            spacing: 4
            Repeater {
                model: ThemeManager.availableThemes
                delegate: AbstractButton {
                    id: tile
                    required property string modelData
                    readonly property bool selected: ThemeManager.currentTheme === modelData
                    readonly property var previewColors: ThemeManager.previews[modelData] || ThemeManager.defaults.colors
                    objectName: "theme" + modelData
                    width: 41; height: 32
                    hoverEnabled: true
                    enabled: !ThemeManager.saving
                    opacity: enabled ? 1 : Theme.opacityDisabled
                    Accessible.name: "Apply " + modelData + " theme"
                    onHoveredChanged: if (hovered) cube.triggerShock()
                    onClicked: { ThemeManager.select(modelData); root.glitchRequested(); }
                    background: Rectangle {
                        radius: Theme.cornerRadius
                        color: tile.hovered || tile.selected ? Qt.alpha(tile.previewColors.primary, Theme.opacityHover) : Qt.alpha(Theme.surface, Theme.opacityGlass)
                        border.width: Theme.borderWidth
                        border.color: Qt.alpha(tile.previewColors.primary, tile.selected || tile.hovered ? Theme.opacityBorder : Theme.opacityGlow)
                    }
                    contentItem: Item {
                        ThemeCube {
                            id: cube
                            width: 24; height: 24
                            anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                            primary: tile.previewColors.primary
                            secondary: tile.previewColors.secondary
                            accent: tile.previewColors.accent
                            opacity: tile.selected || tile.hovered ? 1 : Theme.opacityInactive
                        }
                        Text {
                            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                            text: tile.modelData.toUpperCase()
                            color: tile.selected || tile.hovered ? Theme.text : Theme.textMuted
                            font { family: Theme.fontFamily; pixelSize: 7; letterSpacing: 0.4 }
                        }
                    }
                }
            }
        }
    }
}
