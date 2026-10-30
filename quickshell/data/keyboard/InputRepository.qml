pragma Singleton

// REPOSITORIO: lo que el kernel sabe de tus dispositivos de entrada, leído de
// /sys/class/input. Cada "nodo" (input12, input13…) es una parte de un
// aparato: un teclado USB suele traer tres (las letras, las teclas multimedia
// o "Consumer Control" y las de apagado o "System Control").
//
// Hyprland ya dice qué teclados hay, pero con nombres para reglas
// ("dell-dell-usb-entry-keyboard"). De aquí sale lo que le falta:
//   name      el nombre de verdad ("Dell Dell USB Entry Keyboard")
//   bus       usb | bluetooth | internal (el de una laptop) | other
//   driver    el que lo maneja: "apple" es hid_apple, el driver de Apple (ojo:
//             también maneja algunos genéricos que se hacen pasar por Apple)
//   vendor, product   los números del fabricante y del modelo (hex)
//   uniq      la MAC, en los de Bluetooth: así se cruza con BlueZ
//   phys      dónde está conectado: los nodos de un mismo aparato lo comparten
//   letters   ¿tiene teclas de letras? Es la misma prueba que usa udev: si
//             están de Esc a la D, es un teclado completo. Un mouse con
//             botones extra o una cámara con un botón también salen como
//             "teclados" en Hyprland, y así se distinguen.
//
// /sys no avisa de cambios, pero el kernel sí: cada vez que conectas o
// desconectas algo (por cable o Bluetooth) manda un "uevent". `udevadm
// monitor` los escucha y aquí solo se avisa con `changed()`; el dominio
// decide cuándo volver a leer (un `sh` de milisegundos). Es un solo proceso
// pequeño que se queda escuchando, sin revisar nada cada tantos segundos.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // [{ node, bus, driver, vendor, product, uniq, phys, letters, name }]
    property var devices: []

    // Se conectó o se desconectó algo que el kernel ve como "entrada"
    // (teclado, mouse, control…).
    signal changed()

    function refresh(): void {
        if (reader.running)
            reader.rerun = true;
        else
            reader.running = true;
    }

    // `read` del shell en lugar de `cat`: un proceso menos por archivo.
    readonly property string readScript: [
        "get() { v=''; [ -r \"$1\" ] && IFS= read -r v < \"$1\"; }",
        "for i in /sys/class/input/input*; do",
        "  [ -r \"$i/name\" ] || continue",
        "  get \"$i/name\"; name=$v",
        "  get \"$i/id/bustype\"; bus=$v",
        "  get \"$i/id/vendor\"; vendor=$v",
        "  get \"$i/id/product\"; product=$v",
        "  get \"$i/uniq\"; uniq=$v",
        "  get \"$i/phys\"; phys=$v",
        "  get \"$i/capabilities/key\"; keys=$v",
        "  driver=''",
        "  if [ -e \"$i/device/driver\" ]; then driver=$(readlink \"$i/device/driver\"); driver=${driver##*/}; fi",
        "  printf 'input\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"${i##*/}\" \"$bus\" \"$driver\" \"$vendor\" \"$product\" \"$uniq\" \"$phys\" \"$keys\" \"$name\"",
        "done",
        "exit 0"
    ].join("\n")

    // 0003 USB, 0005 Bluetooth, 0011 el teclado de una laptop (i8042).
    function busName(code): string {
        switch (String(code).toLowerCase()) {
        case "0003":
            return "usb";
        case "0005":
            return "bluetooth";
        case "0011":
            return "internal";
        }
        return "other";
    }

    // capabilities/key es un mapa de bits en hexadecimal, en palabras de 64
    // bits separadas por espacios, la más alta primero. Las teclas 1 a 31
    // (Esc, los números, Q…D) caen en los 32 bits de más abajo: la última
    // palabra, sus últimos 8 caracteres.
    function hasLetters(keys): bool {
        const words = String(keys || "").trim().split(/\s+/);
        const last = words[words.length - 1] || "";
        const low = parseInt(last.slice(-8), 16);
        if (isNaN(low))
            return false;
        return ((low & 0xfffffffe) >>> 0) === 0xfffffffe;
    }

    function parse(text): void {
        const out = [];
        for (const line of text.split("\n")) {
            const parts = line.split("\t");
            if (parts[0] !== "input" || parts.length < 10)
                continue;
            out.push({
                node: parts[1],
                bus: root.busName(parts[2]),
                driver: parts[3],
                vendor: parts[4].toLowerCase(),
                product: parts[5].toLowerCase(),
                uniq: parts[6].toLowerCase(),
                phys: parts[7],
                letters: root.hasLetters(parts[8]),
                name: parts.slice(9).join("\t")
            });
        }
        root.devices = out;
    }

    Process {
        id: reader

        property bool rerun: false

        command: ["sh", "-c", root.readScript]

        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }

        onExited: (exitCode, exitStatus) => {
            if (reader.rerun) {
                reader.rerun = false;
                reader.running = true;
            }
        }
    }

    // ── conectar y desconectar ────────────────────────────────────
    //
    // Cada evento es una línea como:
    //   KERNEL[1234.567890] add      /devices/…/input/input23 (input)
    // Solo importan "add" y "remove" (un teclado manda varias: una por
    // pedazo); el dominio las junta en una sola lectura.
    //
    // Sin root: el kernel deja que cualquier usuario escuche estos avisos.
    // Si udevadm se cae, se vuelve a abrir al rato, pero solo si alcanzó a
    // funcionar: si no existe, no se insiste.
    Process {
        id: monitor

        property int failures: 0

        command: ["udevadm", "monitor", "--kernel", "--subsystem-match=input"]
        running: true

        stdout: SplitParser {
            onRead: function (line) {
                if (/^KERNEL\[[^\]]*\]\s+(add|remove)\s/.test(line))
                    root.changed();
            }
        }

        onStarted: monitor.failures = 0

        onExited: (exitCode, exitStatus) => {
            monitor.failures++;
            if (monitor.failures < 3)
                reopen.restart();
        }

        // Si ni siquiera arranca (no hay udevadm), Quickshell no emite
        // `exited`: solo deja de correr. Eso cuenta como falla.
        onRunningChanged: {
            if (!monitor.running && !reopen.running && monitor.failures === 0)
                monitor.failures = 3;
        }
    }

    Timer {
        id: reopen
        interval: 30000
        onTriggered: monitor.running = true
    }
}
