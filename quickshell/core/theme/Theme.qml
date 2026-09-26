pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool isDark: true

    readonly property QtObject colors: QtObject {
        // --- Colores de marca y acento ---
        readonly property color primary: root.isDark ? "#2563eb" : "#1d4ed8"
        readonly property color secondary: root.isDark ? "#1c2838" : "#e2e8f0"
        readonly property color accent: root.isDark ? "#0091ff" : "#0284c7"

        // --- Superficies y fondos ---
        readonly property color neutral: root.isDark ? "#282828" : "#f1f5f9"
        readonly property color surface: root.isDark ? "#313244" : "#ffffff"
        readonly property color base100: root.isDark ? "#181818" : "#ffffff"
        readonly property color base800: root.isDark ? "#f5f5f5" : "#0f172a"
        readonly property color border: root.isDark ? "#282828" : "#cbd5e1"

        // --- Texto y Contenido ---
        readonly property color baseContent: root.isDark ? "#a6adbb" : "#334155"

        // --- Estados del sistema ---
        readonly property color info: root.isDark ? "#0088ff" : "#0284c7"
        readonly property color success: root.isDark ? "#28bf28" : "#16a34a"
        readonly property color warning: root.isDark ? "#e5a900" : "#d97706"
        readonly property color error: root.isDark ? "#dc2626" : "#b91c1c"
    }

    readonly property QtObject spacing: QtObject {
        readonly property int xs: 2
        readonly property int sm: 6
        readonly property int md: 12
        readonly property int lg: 20
    }

    readonly property QtObject radius: QtObject {
        readonly property int sm: 8
        readonly property int md: 14
        readonly property int lg: 20
    }

    readonly property QtObject font: QtObject {
        readonly property string icon: "lucide"
        readonly property string ui: "Adwaita Sans"
        readonly property string mono: "JetBrainsMono Nerd Font"
        readonly property int small: 11
        readonly property int normal: 14
        readonly property int large: 16
    }
}
