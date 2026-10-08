pragma Singleton
import QtQuick

QtObject {
    readonly property color background: ThemeManager.colors.background
    readonly property color backgroundRaised: ThemeManager.colors.backgroundRaised
    readonly property color surface: ThemeManager.colors.surface
    readonly property color surfaceRaised: ThemeManager.colors.surfaceRaised
    readonly property color primary: ThemeManager.colors.primary
    readonly property color secondary: ThemeManager.colors.secondary
    readonly property color accent: ThemeManager.colors.accent
    readonly property color text: ThemeManager.colors.text
    readonly property color textMuted: ThemeManager.colors.textMuted
    readonly property color border: ThemeManager.colors.border
    readonly property color success: ThemeManager.colors.success
    readonly property color warning: ThemeManager.colors.warning
    readonly property color danger: ThemeManager.colors.danger
    readonly property color dev: ThemeManager.colors.dev
    readonly property color browser: ThemeManager.colors.browser
    readonly property color ai: ThemeManager.colors.ai
    readonly property color media: ThemeManager.colors.media
    readonly property color system: ThemeManager.colors.system
    readonly property real opacityGlass: ThemeManager.effects.opacityGlass
    readonly property real opacityPanel: ThemeManager.effects.opacityPanel
    readonly property real opacityBackdrop: ThemeManager.effects.opacityBackdrop
    readonly property real opacityInactive: ThemeManager.effects.opacityInactive
    readonly property real opacityDisabled: ThemeManager.effects.opacityDisabled
    readonly property real opacityBorder: ThemeManager.effects.opacityBorder
    readonly property real opacityGlow: ThemeManager.effects.opacityGlow
    readonly property real opacityHover: ThemeManager.effects.opacityHover
    readonly property int blurRadius: ThemeManager.effects.blurRadius
    readonly property real glowStrength: ThemeManager.effects.glowStrength
    readonly property int borderWidth: ThemeManager.effects.borderWidth
    readonly property int cornerRadius: ThemeManager.effects.cornerRadius
    readonly property int animationFast: ThemeManager.effects.animationFast
    readonly property int animationDropdown: ThemeManager.effects.animationDropdown
    readonly property int animationNormal: ThemeManager.effects.animationNormal
    // One motion profile for the bar, its dropdowns, and the control center.
    readonly property int animationReveal: animationFast
    readonly property int revealEasing: Easing.OutQuart

    readonly property color transparent: Qt.alpha(background, 0)
    readonly property color glass: Qt.alpha(background, opacityPanel)
    readonly property color glow: Qt.alpha(primary, opacityGlow * glowStrength)
    readonly property int barHeight: 36
    readonly property int barSideHeight: 26
    readonly property int padding: 14
    readonly property int resourcePadding: 4
    readonly property int resourceSpacing: 4
    readonly property int resourceGap: 6
    readonly property int fontSize: 12
    readonly property string fontFamily: "monospace"

    function categoryColor(category: string): color {
        switch (category.toLowerCase()) {
        case "dev": return dev;
        case "browser": return browser;
        case "ai": return ai;
        case "media": return media;
        default: return system;
        }
    }
}
