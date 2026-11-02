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
    // opaco. Hoy el único vidrio es la barra lateral de Ajustes: el marco y
    // todo lo que sale de él (barra, menús, Centro de control, notificaciones,
    // Spotlight y el portapapeles) es negro, como la isla.
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

    // Lo que va ENCIMA de una superficie oscura: los botones de la barra, los
    // menús y los mosaicos del Centro de control. Se llama "glass" por
    // historia (antes la barra eran píldoras de vidrio); hoy todo eso vive
    // sobre el negro del marco.
    readonly property QtObject glass: QtObject {
        readonly property color border: Qt.rgba(1, 1, 1, 0.18)

        // Aire entre el borde de la pestaña y un botón, arriba y abajo.
        readonly property int padding: 3

        // La parte de la pestaña que queda DEBAJO del marco mide lo mismo
        // que la isla cerrada: las dos cuelgan del mismo borde y llegan a la
        // misma altura. Cambia la altura de la isla y la barra la sigue.
        readonly property int barHeight: root.island.closedHeight

        // Botones de la barra.
        readonly property int itemSize: root.glass.barHeight - root.glass.padding * 2
        readonly property color hover: Qt.rgba(1, 1, 1, 0.12)

        // Texto e íconos encima: blancos en ambos modos. Lo de abajo es
        // oscuro siempre, y base100 se invierte con isDark.
        readonly property color content: "#ffffff"
        readonly property color contentMuted: Qt.rgba(1, 1, 1, 0.6)

        // Centro de control (estilo Tahoe).
        readonly property color tile: Qt.rgba(1, 1, 1, 0.12)
        readonly property color tileHover: Qt.rgba(1, 1, 1, 0.18)
        readonly property color control: Qt.rgba(1, 1, 1, 0.18)   // círculo apagado
        readonly property color controlOn: "#ffffff"               // círculo encendido
        readonly property color track: Qt.rgba(1, 1, 1, 0.25)      // pista de deslizador
        readonly property int panelRadius: 28
        readonly property int tileRadius: 22
    }

    // El marco: una sola figura negra alrededor de la pantalla, con dos
    // pestañas que bajan del borde de arriba y los cajones que salen de él
    // (Centro de control, calendario y menú del sistema). Es la dirección
    // "C · Marco" del lienzo "Shell orgánica"; cada medida de aquí es una de
    // las que se probaron allí.
    //
    // Dos tipos de curva, y no son la misma:
    //   ala      CÓNCAVA. Donde una pestaña o un cajón se une al marco: la
    //            figura entra hacia la pestaña en vez de hacer un ángulo.
    //   esquina  CONVEXA. La punta de la pestaña o del cajón, la de afuera.
    readonly property QtObject frame: QtObject {
        // El mismo negro que la isla: la isla cuelga del marco y las dos
        // piezas tienen que leerse como una sola.
        readonly property color fill: root.island.bg

        // Grosor del marco en los cuatro lados. En pantalla completa se va a 0.
        readonly property int thickness: 6

        // Las esquinas de la pantalla que quedan DENTRO del marco: lo que
        // ves del escritorio es un rectángulo redondeado.
        readonly property int screenRadius: 14

        // Las pestañas cerradas.
        readonly property int wing: 14
        readonly property int corner: 14
        readonly property int tabPadding: 8      // del borde de la pestaña al primer botón

        // Un cajón de la pestaña derecha abierto (Centro de control,
        // calendario): el ala crece y la punta toma el radio del panel.
        readonly property int drawerWing: 20
        readonly property int drawerCorner: root.glass.panelRadius

        // El menú del sistema, que sale del borde izquierdo.
        readonly property int menuCorner: 18

        // El panel de notificaciones: el borde derecho engorda esto, de
        // arriba abajo, y las ventanas se apartan lo mismo.
        readonly property int notificationsWidth: 372

        // Los cajones de abajo (Spotlight, portapapeles): esquinas más
        // redondas que las pestañas, y se meten 2 px en el marco para que
        // no quede costura entre las dos ventanas.
        readonly property int bottomCorner: 26
        readonly property int overlap: 2

        // Spotlight: crece al centro desde un tope de 220 de ancho.
        readonly property int spotlightClosedWidth: 220
        readonly property int spotlightWidth: 640
        readonly property int spotlightMaxList: 420

        // El portapapeles, en la esquina.
        readonly property int clipboardWidth: 360
        readonly property int clipboardHeight: 352

        // Mission Control y los fondos: el mismo cajón de tarjetas verticales.
        // Crece desde un tope de 300 de ancho; su ancho final depende de
        // cuántas tarjetas lleva (ver deckWidth()).
        readonly property int deckClosedWidth: 300
        readonly property int cardWidth: 148
        readonly property int cardHeight: 300
        readonly property int cardRadius: 16
        readonly property int cardGap: 16
        readonly property int cardLabel: 28        // la pastilla con el nombre
        readonly property int deckSide: 28         // aire a los lados del cajón
        readonly property int deckEnd: 18          // aire arriba y abajo
        readonly property int deckHeight: root.frame.deckEnd * 2 + root.frame.cardHeight
                                          + 10 + root.frame.cardLabel
        readonly property real missionDim: 0.28    // cuánto se oscurece la pantalla
        readonly property color cardChosen: "#4db2ff"
        readonly property color cardGlow: Qt.rgba(0, 0.57, 1, 0.28)

        // El aire entre la orilla de un cajón o panel y lo que lleva dentro.
        readonly property int inset: 14

        // Escondida, la barra deja esta tira para volver a destaparla.
        readonly property int revealStrip: 2

        // Los botones encima del negro.
        readonly property color hover: root.glass.hover
        readonly property color active: Qt.rgba(1, 1, 1, 0.16)

        // El rebote: los mismos dos muelles que la isla (abrir rebasa un
        // poco y vuelve; cerrar no rebasa). Lo de en medio, para el
        // contenido, que entra cuando el cajón ya casi terminó de abrirse.
        readonly property int openDuration: root.island.openDuration
        readonly property real openOvershoot: root.island.openOvershoot
        readonly property int closeDuration: root.island.closeDuration
        readonly property int slideDuration: 250   // esconderse y destaparse
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

    // El ancho del cajón de tarjetas (Mission Control, fondos) para `cards`
    // tarjetas: las tarjetas, sus huecos y el aire de los lados.
    function deckWidth(cards: int): int {
        const n = Math.max(1, cards);
        return n * root.frame.cardWidth + (n - 1) * root.frame.cardGap + root.frame.deckSide * 2;
    }

    // Cuántas tarjetas caben a lo ancho de una pantalla, dejando `margin` a
    // cada lado. Más que eso, el cajón se desplaza de lado.
    function deckFits(screenWidth: real, margin: real): int {
        const room = screenWidth - margin * 2 - root.frame.deckSide * 2 + root.frame.cardGap;
        return Math.max(1, Math.floor(room / (root.frame.cardWidth + root.frame.cardGap)));
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
            code: "\ue093",        // code
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

        // Los del reproductor de la isla: rellenos, como los de macOS. Son de
        // la Nerd Font (Font Awesome), no de Lucide, que solo tiene contornos.
        readonly property var transport: ({
            play: "\uf04b",       // fa-play
            pause: "\uf04c",      // fa-pause
            previous: "\uf04a",   // fa-backward
            next: "\uf04e"        // fa-forward
        })

        readonly property var media: ({
            play: "",
            pause: "",
            previous: "",
            next: ""
        })

        // Sin carátula: lo que suena, según Player.kind (Lucide).
        readonly property var cover: ({
            music: "\ue122",      // music (el mismo de `music`)
            video: "\ue5ec"       // tv-minimal-play
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
        // Cerrada y abierta. Las medidas INCLUYEN las alas. Con el marco, las
        // alas pasaron a ser las de las pestañas (Theme.frame.wing), así que
        // el total creció justo lo que crecieron ellas: el ancho entre las
        // dos curvas sigue siendo el de Boring Notch (173 cerrada, 602
        // abierta) y, abierta, el alto que queda debajo de las alas también
        // (171). Las vistas de los ocupantes no se enteran del cambio.
        readonly property int minWidth: 201
        readonly property int closedHeight: 32
        readonly property int openWidth: 648
        readonly property int openHeight: 194

        // Las de arriba son las alas (cóncavas), las de abajo el cuerpo.
        // Los cuatro valores crecen al desplegarse.
        readonly property int closedTopRadius: 14
        readonly property int closedBottomRadius: 14
        readonly property int openTopRadius: 23
        readonly property int openBottomRadius: 24

        // La carátula: 20/4 plegada; desplegada, grande como en el
        // reproductor de macOS, casi del alto de la isla.
        readonly property int artClosed: 20
        readonly property int artClosedRadius: 4
        readonly property int artOpen: 136
        readonly property int artOpenRadius: 10

        // El desplegado con imagen, el del reproductor y el de las
        // notificaciones: la imagen grande a la izquierda y, a su lado y
        // dentro de su altura, el texto. Las dos vistas leen de aquí para
        // verse de la misma familia.
        readonly property int openStart: 16       // borde → imagen (aire para su halo)
        readonly property int openEnd: 14         // texto → borde derecho
        readonly property int openBottom: 18      // por encima de la curva de abajo
        readonly property int openGap: 18         // imagen → texto
        readonly property int openTitle: 17       // la canción, quien escribe
        readonly property int openSubtitle: 13    // el artista, el mensaje
        readonly property int openCaption: 11     // el programa o la app, en la esquina

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
        readonly property int peekMaxWidth: 476   // más allá, el nombre se corta (alas incluidas)

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
