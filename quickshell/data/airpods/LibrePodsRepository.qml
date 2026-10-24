// REPOSITORIO: LibrePods, el programa que habla el protocolo de los AirPods
// (modos de ruido, detección de conversación, batería de cada pieza).
//
// LibrePods no tiene una API para otros programas. Lo que sí tiene es su
// ícono de bandeja (StatusNotifierItem), y ese ícono publica por D-Bus:
//   - un menú (DBusMenu) con los modos de ruido como opciones marcables y la
//     detección de conversación como casilla;
//   - un tooltip con la batería: "L: 80% R: 75% C: 40%" en la versión nueva
//     (Rust) o "Left: 80%, Right: 75%, Case: 40%" en la vieja (Qt).
// Quickshell lee las dos cosas (Quickshell.Services.SystemTray), así que tu
// shell usa ese menú como API: lee qué opción está marcada y la "pulsa".
// No hay que parchear LibrePods y sirve con las dos versiones.
//
// Para que haya bandeja alguien tiene que hospedarla: al usar SystemTray tu
// shell se registra como StatusNotifierWatcher. LibrePods (Rust) se cierra
// si al arrancar no encuentra uno, por eso lo arranca la shell DESPUÉS de
// registrarse, y no el autostart de Hyprland.
//
// Datos planos hacia afuera: nunca objetos de la bandeja ni del menú.

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

Singleton {
    id: root

    // Cómo se arranca. --start-minimized es de la versión nueva (la del AUR
    // librepods-rust-git); la vieja (Qt) usa --hide.
    readonly property var command: ["librepods", "--start-minimized"]

    // Su ícono en la bandeja. La versión nueva se identifica como
    // "librepods" y se titula "AirPods"; la vieja usa el nombre del programa.
    readonly property var item: SystemTray.items.values.find(
        entry => /librepods/i.test(entry.id) || entry.title === "AirPods") ?? null

    readonly property bool running: root.item !== null

    // ¿está instalado? Se mira al arrancar la shell (ver abajo); y si corre,
    // lo está aunque se haya instalado después.
    property bool found: false
    readonly property bool installed: root.found || root.running

    // Modo Apple: ¿/etc/bluetooth/main.conf tiene el DeviceID de Apple? Lo
    // pone ./install.sh --airpods. No se mira al arrancar: solo cuando alguien
    // lo pregunta (Ajustes › AirPods), con un grep que dura milisegundos.
    readonly property string bluetoothConf: "/etc/bluetooth/main.conf"
    property bool appleMode: false

    function refreshAppleMode(): void {
        if (!appleProbe.running)
            appleProbe.running = true;
    }

    // El tooltip tal cual: título y descripción juntos (cada versión pone la
    // batería en uno distinto).
    readonly property string batteryText: root.item
        ? (root.item.tooltipTitle + " " + root.item.tooltipDescription)
        : ""

    // Las opciones del menú, en plano. `checked` es lo que LibrePods tiene
    // marcado ahora: el modo de ruido actual, si la detección está encendida.
    readonly property var entries: {
        const list = opener.children ? opener.children.values : [];
        const out = [];

        for (let i = 0; i < list.length; ++i) {
            const entry = list[i];
            if (!entry || entry.isSeparator)
                continue;

            out.push({
                text: entry.text,
                enabled: entry.enabled,
                checkable: entry.buttonType !== QsMenuButtonType.None,
                checked: entry.checkState === Qt.Checked
            });
        }

        return out;
    }

    // "Pulsar" una opción, por su texto: lo mismo que hacer clic en ella en el
    // menú de la bandeja.
    function trigger(text): void {
        const list = opener.children ? opener.children.values : [];
        const entry = list.find(item => item && item.text === text);

        if (entry)
            entry.triggered();
    }

    function start(): void {
        Quickshell.execDetached(root.command);
    }

    // Mantiene el menú cargado mientras exista el ícono: sin un "opener",
    // Quickshell no pide el menú a LibrePods.
    QsMenuOpener {
        id: opener
        menu: root.item ? root.item.menu : null
    }

    Process {
        id: appleProbe
        command: ["grep", "-qiE",
            "^[[:space:]]*DeviceID[[:space:]]*=[[:space:]]*bluetooth:004c:", root.bluetoothConf]
        onExited: (exitCode, exitStatus) => root.appleMode = exitCode === 0
    }

    // Al arrancar la shell: si LibrePods está instalado y no corre, se
    // arranca. Para entonces la bandeja ya está registrada (la lectura de
    // `item` de arriba la creó). Si no está instalado no se intenta nada y
    // todo lo de los AirPods se queda en "audífonos normales".
    //   salida 2: no está instalado · 1: instalado, no corre · 0: ya corre
    Process {
        command: ["sh", "-c",
            "command -v librepods >/dev/null || exit 2; pgrep -x librepods >/dev/null || exit 1"]
        running: true
        onExited: (exitCode, exitStatus) => {
            root.found = exitCode !== 2;
            if (exitCode === 1)
                root.start();
        }
    }
}
