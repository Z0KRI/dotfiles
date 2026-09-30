pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool isDark: false

    readonly property QtObject colors: QtObject {
        // --- Brand Colors and Accent Colors ---
        readonly property color primary: root.isDark ? "#2563eb" : "#1d4ed8"
        readonly property color secondary: root.isDark ? "#1c2838" : "#e2e8f0"
        readonly property color accent: root.isDark ? "#0091ff" : "#0284c7"

        // --- Surfaces and backgrounds ---
        readonly property color neutral: root.isDark ? "#282828" : "#f1f5f9"
        readonly property color surface: root.isDark ? "#313244" : "#ffffff"
        readonly property color base100: root.isDark ? "#181818" : "#ffffff"
        readonly property color base800: root.isDark ? "#f5f5f5" : "#0f172a"
        readonly property color border: root.isDark ? "#282828" : "#cbd5e1"

        // --- Text and Content ---
        readonly property color baseContent: root.isDark ? "#a6adbb" : "#334155"

        // --- System States ---
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
        readonly property string iconNerd: "JetBrainsMono Nerd Font Propo"
        readonly property string ui: "Adwaita Sans"
        readonly property string mono: "JetBrainsMono Nerd Font"
        readonly property int small: 11
        readonly property int normal: 14
        readonly property int large: 16
    }

    // “Glass” style bar.
    readonly property QtObject glass: QtObject {
        // Píldora
        readonly property color top: Qt.rgba(0.45, 0.45, 0.45, 0.55)
        readonly property color middle: Qt.rgba(0.35, 0.35, 0.35, 0.55)
        readonly property color bottom: Qt.rgba(0.25, 0.25, 0.25, 0.60)
        readonly property color border: Qt.rgba(1, 1, 1, 0.18)

        // --- Space between the content and the button ---
        readonly property int padding: 3
        // --- Space between buttons ---
        readonly property int spacing: 3

        // buttons
        readonly property int itemSize: 30
        readonly property color hover: Qt.rgba(1, 1, 1, 0.12)
        readonly property color active: Qt.rgba(0, 0, 0, 0.30)
    }

    readonly property QtObject systemIcons: QtObject {
        readonly property var volume: ({
            muted: "",
            low: "",
            medium: "",
            high: ""   
        })

        readonly property var device: ({
            speaker: "",   
            headphones: "",
            display: ""    
        })
    }

    readonly property QtObject island: QtObject {
        readonly property int minWidth: 180
        readonly property int minHeight: 34

        // El alto de la píldora. Lo comparten TODOS los ocupantes plegados:
        // la island cambia de ancho al cambiar de inquilino, nunca de alto.
        readonly property int pillHeight: 44

        // El aire a los costados del contenido plegado.
        readonly property int pillPadding: 14

        readonly property int radius: 18
        readonly property int expandedRadius: 40
        readonly property int wing: 14

        readonly property color bg: "#0b0b0e"
        readonly property color fg: "#f2f2f7"
        readonly property color muted: Qt.rgba(1, 1, 1, 0.55)
        readonly property color track: Qt.rgba(1, 1, 1, 0.22)

        // Entrada y salida desde el borde.
        readonly property int enterDuration: 460
        readonly property int exitDuration: 240
        readonly property real enterOvershoot: 1.1

        // El estirón. Una sola duración y un solo rebase para el ancho, el
        // alto y el redondeo: si llegan a destiempo, parecen tres cosas.
        readonly property int sizeDuration: 520
        readonly property real sizeOvershoot: 0.9

        // El relevo de una vista por otra. Corto a propósito: acompaña al
        // estirón, no compite con él.
        readonly property int contentDuration: 180
    }
}
