pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool isDark: false

    // Los tres los escribe el dominio de apariencia (Appearance), igual que
    // isDark. El tema solo pinta: no los edites a mano.
    property string accentName: "blue"
    property real glassTint: 0.5   // 0 transparente · 0.5 como siempre · 1 tintado

    // Colores de acento, los de macOS. "blue" conserva tu acento de siempre.
    readonly property var accents: ({
        blue:     { light: "#0284c7", dark: "#0091ff" },
        purple:   { light: "#9a4fd0", dark: "#bf5af2" },
        pink:     { light: "#e8336d", dark: "#ff375f" },
        red:      { light: "#e0352b", dark: "#ff453a" },
        orange:   { light: "#f08a00", dark: "#ff9f0a" },
        yellow:   { light: "#e6b400", dark: "#ffd60a" },
        green:    { light: "#28a745", dark: "#32d74b" },
        graphite: { light: "#7d7d82", dark: "#98989d" }
    })

    // Liquid Glass: escala la opacidad de un vidrio. En 0.5 la deja tal cual
    // (tu look de siempre); hacia 0 baja hasta el 40 %; hacia 1 se acerca a
    // opaco. Una sola curva para todo el vidrio: por eso el deslizador de
    // Ajustes mueve la barra, el Centro de control y los menús a la vez.
    function glassAlpha(alpha: real): real {
        const t = Math.max(0, Math.min(1, root.glassTint));
        if (t <= 0.5)
            return alpha * (0.4 + 1.2 * t);
        return alpha + (0.96 - alpha) * (t - 0.5) * 2;
    }

    readonly property QtObject colors: QtObject {
        // --- Brand Colors and Accent Colors ---
        readonly property color primary: root.isDark ? "#2563eb" : "#1d4ed8"
        readonly property color secondary: root.isDark ? "#1c2838" : "#e2e8f0"
        readonly property color accent: {
            const palette = root.accents[root.accentName] ?? root.accents.blue;
            return root.isDark ? palette.dark : palette.light;
        }

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

    // Movimiento: el rebote que usan botones, interruptores y deslizadores.
    readonly property QtObject motion: QtObject {
        readonly property int duration: 300
        readonly property var spring: [0.55, -0.04, 0.3, 1.44, 1, 1]
    }

    // “Glass” style bar.
    readonly property QtObject glass: QtObject {
        // Píldora. Su opacidad sigue al deslizador de Liquid Glass.
        readonly property color top: Qt.rgba(0.45, 0.45, 0.45, root.glassAlpha(0.55))
        readonly property color middle: Qt.rgba(0.35, 0.35, 0.35, root.glassAlpha(0.55))
        readonly property color bottom: Qt.rgba(0.25, 0.25, 0.25, root.glassAlpha(0.60))
        readonly property color border: Qt.rgba(1, 1, 1, 0.18)

        // Menús desplegables y Spotlight.
        readonly property color menu: Qt.alpha(root.colors.base100, root.glassAlpha(0.85))

        // --- Space between the content and the button ---
        readonly property int padding: 3
        // --- Space between buttons ---
        readonly property int spacing: 3

        // buttons
        readonly property int itemSize: 30
        readonly property color hover: Qt.rgba(1, 1, 1, 0.12)
        readonly property color active: Qt.rgba(0, 0, 0, 0.30)

        // Contenido sobre vidrio: íconos y texto de la barra y del Centro de
        // control. Fijo en blanco: el vidrio es oscuro en ambos modos, y
        // base100 se invierte con isDark.
        readonly property color content: "#ffffff"
        readonly property color contentMuted: Qt.rgba(1, 1, 1, 0.6)

        // La barra sólida (cuando se oculta sola). Oscura en los dos modos por
        // lo mismo que `content`: los íconos de la barra son siempre blancos.
        // En claro conserva el azul marino de siempre; antes era base800, que
        // en oscuro se invierte a casi blanco y dejaba los íconos sin verse.
        readonly property color solid: root.isDark ? "#1c1c1e" : "#0f172a"

        // Centro de control (estilo Tahoe).
        readonly property color panel: Qt.rgba(0.12, 0.12, 0.14, root.glassAlpha(0.55))
        readonly property color tile: Qt.rgba(1, 1, 1, 0.12)
        readonly property color tileHover: Qt.rgba(1, 1, 1, 0.18)
        readonly property color control: Qt.rgba(1, 1, 1, 0.18)   // círculo apagado
        readonly property color controlOn: "#ffffff"               // círculo encendido
        readonly property color track: Qt.rgba(1, 1, 1, 0.25)      // pista de deslizador
        readonly property int panelRadius: 28
        readonly property int tileRadius: 22
    }

    // Ventanas de aplicación (Ajustes), estilo macOS Golden Gate: claras u
    // oscuras según isDark, con la barra lateral de vidrio de borde a borde.
    // El contenido es opaco a propósito: Golden Gate devolvió la legibilidad
    // al texto, y el vidrio queda para la barra lateral.
    readonly property QtObject window: QtObject {
        readonly property color sidebar: root.isDark
            ? Qt.rgba(0.13, 0.13, 0.15, root.glassAlpha(0.8))
            : Qt.rgba(0.93, 0.93, 0.95, root.glassAlpha(0.8))
        readonly property color background: root.isDark ? "#1e1e20" : "#f5f5f7"
        readonly property color divider: root.isDark ? Qt.rgba(0, 0, 0, 0.6) : Qt.rgba(0, 0, 0, 0.1)

        // Los grupos redondeados del contenido.
        readonly property color group: root.isDark ? "#2a2a2c" : "#ffffff"
        readonly property color groupBorder: root.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.06)
        readonly property color separator: root.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.08)

        readonly property color text: root.isDark ? "#f5f5f7" : "#1d1d1f"
        readonly property color textMuted: root.isDark ? "#98989d" : "#6e6e73"
        readonly property color hover: root.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.045)

        // Controles: fondo de buscador y segmentados, y lo que va "encima"
        // (segmento elegido, botones, perilla).
        readonly property color control: root.isDark ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.06)
        readonly property color controlRaised: root.isDark ? "#5b5b5f" : "#ffffff"
        readonly property color controlBorder: root.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.12)
        readonly property color track: root.isDark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.1)
        readonly property color knob: "#ffffff"
        readonly property color shadow: Qt.rgba(0, 0, 0, root.isDark ? 0.45 : 0.16)

        // Los tres botones de ventana. Apagado = el gris de macOS.
        readonly property color closeButton: "#ff5f57"
        readonly property color minimizeButton: "#febc2e"
        readonly property color zoomButton: "#28c840"
        readonly property color buttonOff: root.isDark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.12)

        readonly property int sidebarWidth: 236
        readonly property int toolbarHeight: 52
        readonly property int contentWidth: 600   // ancho máximo de una página
        readonly property int radius: 12          // grupos
        readonly property int rowHeight: 42

        readonly property int fontBody: 13
        readonly property int fontCaption: 11
        readonly property int fontTitle: 15
        readonly property int fontHero: 22
    }

    readonly property QtObject systemIcons: QtObject {
        readonly property var arch: ({
            icon: "󰣇",
            size: 25,
            family: root.font.iconNerd
        })

        readonly property string squirrel: ""
        readonly property string search: ""
        readonly property string calendar: ""
        readonly property string controlCenter: ""
        readonly property string lock: ""
        readonly property string chevronLeft: ""
        readonly property string chevronRight: ""

        readonly property string mic: ""
        readonly property string micOff: ""
        readonly property string sunDim: ""
        readonly property string sun: ""
        readonly property string moon: ""
        readonly property string darkMode: ""
        readonly property string stayAwake: ""
        readonly property string screenshot: ""
        readonly property string colorPicker: ""
        readonly property string audioOutput: ""
        readonly property string music: ""

        // Ajustes. Van como \uXXXX a propósito: los glifos de Lucide son
        // caracteres de uso privado y se pierden al copiarlos por el chat;
        // el código escapado llega siempre igual.
        readonly property string settings: "\ue154"       // Lucide: settings
        readonly property string bell: "\ue059"           // bell
        readonly property string monitor: "\ue11d"        // monitor
        readonly property string panelTop: "\ue435"       // panel-top
        readonly property string island: "\ue376"         // rectangle-horizontal
        readonly property string info: "\ue0f9"           // info
        readonly property string check: "\ue06c"          // check
        readonly property string xMark: "\ue1b2"          // x
        readonly property string minus: "\ue11c"          // minus
        readonly property string plus: "\ue13d"           // plus
        readonly property string clearField: "\ue084"     // circle-x
        readonly property string trash: "\ue18e"          // trash-2
        readonly property string history: "\ue1f5"        // history
        readonly property string warmth: "\ue188"         // thermometer-sun
        readonly property string phoneCall: "\ue134"      // phone-call
        readonly property string battery: "\ue057"        // battery-medium
        readonly property string scanning: "\ue1ba"       // bluetooth-searching
        readonly property string cpu: "\ue0a9"            // cpu
        readonly property string memory: "\ue445"         // memory-stick
        readonly property string gpu: "\ue66a"            // gpu
        readonly property string clock: "\ue250"          // clock-3
        readonly property string user: "\ue19f"           // user

        // Menú de Arch (antes iban vacíos: sus glifos se perdieron al copiarlos).
        readonly property string forceQuit: "\ue084"      // circle-x
        readonly property string restart: "\ue148"        // rotate-ccw
        readonly property string power: "\ue140"          // power
        readonly property string logout: "\ue10e"         // log-out

        readonly property var media: ({
            play: "",
            pause: "",
            previous: "",
            next: ""
        })

        readonly property var volume: ({
            muted: "",
            low: "",
            medium: "",
            high: ""   
        })

        readonly property var wifi: ({
            high: "",
            medium: "",
            low: "",
            none: "",
            off: ""
        })

        readonly property var bluetooth: ({
            on: "",
            off: ""
        })

        readonly property var device: ({
            speaker: "",   
            headphones: "",
            display: "",
            phone: "",
            keyboard: "",
            mouse: "",
            gamepad: "",
            laptop: "",
            bluetooth: ""
        })
    }

    readonly property QtObject island: QtObject {
        // Cerrada y abierta: las medidas reales de Boring Notch.
        readonly property int minWidth: 185
        readonly property int closedHeight: 32
        readonly property int openWidth: 640
        readonly property int openHeight: 190

        // Las de arriba son las alas (cóncavas), las de abajo el cuerpo.
        // Los cuatro valores crecen al desplegarse.
        readonly property int closedTopRadius: 6
        readonly property int closedBottomRadius: 14
        readonly property int openTopRadius: 19
        readonly property int openBottomRadius: 24

        // La carátula: 20/4 plegada, 90/13 desplegada.
        readonly property int artClosed: 20
        readonly property int artClosedRadius: 4
        readonly property int artOpen: 90
        readonly property int artOpenRadius: 13

        readonly property int spacing: 16

        readonly property color bg: "#000000"
        readonly property color fg: "#f2f2f7"
        readonly property color muted: Qt.rgba(1, 1, 1, 0.55)
        readonly property color track: Qt.rgba(1, 1, 1, 0.22)

        // Abrir rebasa un poco y vuelve; cerrar no rebasa nada. Son sus dos
        // muelles: amortiguación 0.8 al abrir, 1.0 al cerrar. El 0.65 de
        // rebase en OutBack da ese 1.5 % de sobrepaso, no el 10 % del valor
        // por defecto de Qt.
        readonly property int openDuration: 420
        readonly property real openOvershoot: 0.65
        readonly property int closeDuration: 380

        // Entrada y salida desde el borde de la pantalla.
        readonly property int enterDuration: 420
        readonly property int exitDuration: 260

        readonly property int contentDuration: 180
    }
}
