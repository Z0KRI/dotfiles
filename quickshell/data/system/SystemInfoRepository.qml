// REPOSITORIO: los datos del equipo para "Acerca de". Se piden UNA vez, con
// un solo script que imprime "clave=valor" por línea, y se entregan en crudo:
// limpiar el nombre del procesador o pasar kB a GB es regla, va en domain.
//
// ¿Por qué un script y no FileView? Los archivos de /proc dicen medir 0 bytes
// (el kernel los genera al leerlos), y varios datos ni siquiera son archivos
// (lspci, hyprctl, qs). Un proceso corto los junta todos de una vez.

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // clave → texto, tal cual salió del sistema.
    property var info: ({})

    function refresh(): void {
        if (!probe.running) {
            probe.collected = ({});
            probe.running = true;
        }
    }

    Process {
        id: probe

        property var collected: ({})

        command: ["sh", "-c", [
            '. /etc/os-release 2>/dev/null; echo "os=${PRETTY_NAME:-$NAME}"',
            'echo "kernel=$(uname -r)"',
            'echo "host=$(cat /etc/hostname 2>/dev/null || uname -n)"',
            'echo "cpu=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2-)"',
            'echo "cores=$(nproc 2>/dev/null)"',
            'echo "memory=$(grep -m1 MemTotal /proc/meminfo | tr -s " " | cut -d" " -f2)"',
            'echo "gpu=$(lspci 2>/dev/null | grep -Ei "vga|3d|display" | head -n1 | cut -d: -f3-)"',
            'echo "hyprland=$(hyprctl version -j 2>/dev/null | grep -m1 "\\"tag\\"" | cut -d\\" -f4)"',
            // qs escribe su versión por el canal de log (stderr), no por stdout.
            'echo "quickshell=$(qs --version 2>&1 | head -n1)"',
            'echo "uptime=$(cut -d. -f1 /proc/uptime)"'
        ].join("\n")]

        stdout: SplitParser {
            onRead: line => {
                const at = line.indexOf("=");
                if (at > 0)
                    probe.collected[line.slice(0, at)] = line.slice(at + 1).trim();
            }
        }

        // Se publica todo junto al terminar: así la página no parpadea
        // llenándose renglón por renglón.
        onExited: (exitCode, exitStatus) => {
            root.info = probe.collected;
        }
    }

    Component.onCompleted: root.refresh()
}
