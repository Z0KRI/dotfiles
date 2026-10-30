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
        readonly property color accent: {
            const palette = root.accents[root.accentName] ?? root.accents.blue;
            return root.isDark ? palette.dark : palette.light;
        }

        // --- Surfaces and backgrounds ---
        readonly property color neutral: root.isDark ? "#282828" : "#f1f5f9"
        readonly property color base100: root.isDark ? "#181818" : "#ffffff"
        readonly property color base800: root.isDark ? "#f5f5f5" : "#0f172a"

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

        // La barra mide lo mismo que la isla cerrada y empieza en el mismo
        // borde: las dos comparten la franja de arriba. Cambia la altura de la
        // isla y la barra la sigue.
        readonly property int barHeight: root.island.closedHeight

        // Botones: lo que queda dentro de la píldora.
        readonly property int itemSize: root.glass.barHeight - root.glass.padding * 2
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

    // Liquid Glass de macOS 27 (Golden Gate), para Spotlight. Lo usa el átomo
    // GlassSurface. Cuatro capas, de abajo hacia arriba:
    //
    //   1. El DESENFOQUE: no es de QML. Lo pinta Hyprland detrás de la capa
    //      (hl.layer_rule en workspace_windows_rules.lua). QML no puede ver lo
    //      que hay detrás de su ventana.
    //   2. El TINTE: un color translúcido encima. Su opacidad sigue al
    //      deslizador de Liquid Glass de Ajustes, igual que la barra.
    //   3. El BORDE OSCURO: Golden Gate oscureció los bordes para separar
    //      capas sobre fondos claros.
    //   4. El REFLEJO: un borde de luz más brillante en la esquina de arriba a
    //      la izquierda y en la de abajo a la derecha, como luz sobre un vidrio
    //      grueso.
    //
    // El vidrio es oscuro en los dos modos, como la barra y el Centro de
    // control: el texto encima va siempre en blanco. QML no sabe qué hay
    // detrás, así que no puede elegir un color de texto según el fondo.
    readonly property QtObject liquid: QtObject {
        // Los tintes nunca bajan de 0.26: Hyprland solo desenfoca donde el
        // alfa supera su ignore_alpha (0.2). Más transparente que eso y el
        // vidrio dejaría de desenfocar.
        readonly property color field: Qt.rgba(0.06, 0.06, 0.08, root.liquidAlpha(0.72))  // la barra
        readonly property color panel: Qt.rgba(0.10, 0.10, 0.12, root.liquidAlpha(0.48))  // los resultados

        readonly property color highlight: Qt.rgba(1, 1, 1, 0.55)   // el punto más brillante del reflejo
        readonly property color edge: Qt.rgba(0, 0, 0, 0.34)        // el borde oscuro
        readonly property color sheen: Qt.rgba(1, 1, 1, 0.07)       // luz interior, arriba

        readonly property color content: "#ffffff"
        // La fila elegida: el acento, casi opaco, para que el texto blanco
        // se lea encima en cualquier fondo.
        readonly property color selection: Qt.alpha(root.colors.accent, 0.82)
        readonly property color tile: Qt.rgba(1, 1, 1, 0.14)        // fondo de un ícono de respaldo

        // Golden Gate bajó el radio de las esquinas respecto a Tahoe.
        readonly property int radius: 22
        readonly property int gap: 10          // entre la barra y los resultados
        readonly property int barHeight: 54
        readonly property int barFont: 19
        readonly property int rowHeight: 48
        readonly property int iconSize: 34
    }

    // Opacidad del tinte de Liquid Glass: la misma curva que el resto del
    // vidrio (glassAlpha), con un piso. Ver `liquid` arriba.
    function liquidAlpha(alpha: real): real {
        return Math.max(0.26, root.glassAlpha(alpha));
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
        // Texto de los botones destructivos (Restablecer, Olvidar). En oscuro
        // el rojo de error se pierde sobre el gris del botón: va uno más claro.
        readonly property color destructive: root.isDark ? "#ff7b72" : "#b91c1c"
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

    // El ícono de batería para un nivel de 0 a 1: cargando gana; de 60 % para
    // arriba, llena; hasta 20 %, baja. Lo usan los AirPods, los teclados y el
    // iPhone, en la isla y en Ajustes.
    function batteryIcon(level: real, charging: bool): string {
        const glyphs = root.systemIcons.batteryLevel;
        if (charging)
            return glyphs.charging;
        if (level > 0.6)
            return glyphs.full;
        if (level > 0.2)
            return glyphs.medium;
        return glyphs.low;
    }

    readonly property QtObject systemIcons: QtObject {
        // El logo de Arch es un glifo de Nerd Font: su tamaño va por `ink`
        // (lo que mide el DIBUJO), no por tamaño de fuente. Ver Icon.qml.
        readonly property var arch: ({
            icon: "\udb82\udcc7",   // nf-md-arch (U+F08C7), como par sustituto
            ink: 17,
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
        readonly property string scanning: "\ue1ba"       // bluetooth-searching
        readonly property string cpu: "\ue0a9"            // cpu
        readonly property string memory: "\ue445"         // memory-stick
        readonly property string gpu: "\ue66a"            // gpu
        readonly property string clock: "\ue250"          // clock-3
        readonly property string user: "\ue19f"           // user

        // Pantallas.
        readonly property string monitorCheck: "\ue482"   // monitor-check
        readonly property string monitorOff: "\ue1dc"     // monitor-off
        readonly property string rotate: "\ue149"         // rotate-cw
        readonly property string mirror: "\ue09e"         // copy
        readonly property string resolution: "\ue2ec"     // scaling
        readonly property string vrr: "\ue1b4"            // zap

        // AirPods (Lucide): modos de ruido, conversación y modo Apple. Su
        // batería usa la de todos (batteryLevel).
        readonly property var airpods: ({
            off: "\ue401",            // circle-off
            transparency: "\ue382",   // ear
            adaptive: "\ue412",       // sparkles
            anc: "\ue383",            // ear-off
            conversation: "\ue51e",   // speech
            appleMode: "\ue34e"       // apple
        })

        // Teclado: Ajustes › Teclado, la hoja de emparejamiento y la isla.
        readonly property string functionKeys: "\ue22d"   // function-square
        readonly property string command: "\ue09a"        // command
        readonly property string swapKeys: "\ue24a"       // arrow-left-right
        readonly property string languages: "\ue0fe"      // languages
        readonly property string launchpad: "\ue0ff"      // layout-grid
        readonly property string warning: "\ue193"        // alert-triangle

        // Batería, de todo lo que la tiene (AirPods, teclados, el iPhone).
        // Cuál toca según el nivel lo decide Theme.batteryIcon().
        readonly property var batteryLevel: ({
            full: "\ue055",      // battery-full
            medium: "\ue057",    // battery-medium
            low: "\ue056",       // battery-low
            charging: "\ue054",  // battery-charging
            warning: "\ue3ac"    // battery-warning
        })

        // Spotlight: los chips de modo y el glifo de respaldo de cada tipo de
        // resultado (cuando el tema de íconos no trae uno).
        readonly property var launcher: ({
            all: "\ue151",         // search
            apps: "\ue0ff",        // layout-grid
            files: "\ue0d7",       // folder
            clipboard: "\ue085",   // clipboard
            file: "\ue0c0",        // file
            image: "\ue0f6",       // image
            text: "\ue0cc",        // file-text
            web: "\ue0e8",         // globe
            link: "\ue102",        // link
            command: "\ue181",     // terminal
            enter: "\ue0a1"        // corner-down-left
        })

        // Responder un mensaje desde la isla: mandar, y mientras se manda.
        readonly property string send: "\ue152"          // send
        readonly property string sending: "\ue109"       // loader

        // Llamada en curso (Lucide). Colgar es el mismo teléfono, girado.
        readonly property var call: ({
            phone: "\ue133",         // phone
            speaker: "\ue1ab",       // volume-2
            mic: "\ue118",           // mic
            micOff: "\ue119",        // mic-off
            more: "\ue0b6"           // ellipsis
        })

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

        // Los avisos de una línea de un aparato (AirPods, teclados): las
        // medidas que comparten la vista (DevicePeek) y la cuenta del ancho
        // (PeekWidth). Cambiar una aquí cambia las dos.
        readonly property int peekEdge: 12        // aire a cada lado
        readonly property int peekGlyph: 14       // los íconos
        readonly property int peekGap: 8          // ícono → nombre
        readonly property int peekSplit: 16       // nombre → lo de la derecha
        readonly property int peekIconGap: 6      // ícono → texto, a la derecha
        readonly property int peekText: 12
        readonly property int peekMaxWidth: 460   // más allá, el nombre se corta

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
