pragma Singleton

// REPOSITORIO: hid_apple, el driver del kernel para los teclados Apple. Es el
// que traduce la tecla fn, ⌘ y ⌥, y la fila de arriba (brillo, música,
// volumen). Solo maneja aparatos con el número de fabricante de Apple: un
// teclado Dell o un ROG nunca pasan por él. Ojo: algunos genéricos (chip
// SONiX, un Keychron en modo Mac…) se presentan con ese número y el kernel
// también los maneja con este driver. Dos cosas, y ninguna decide nada (eso
// es de domain/keyboard):
//
//   1. LEER cómo están sus opciones, en /sys. Un `sh` de milisegundos, cuando
//      el dominio lo pide: /sys no avisa de cambios. Qué teclados maneja lo
//      dice InputRepository (su driver es "apple").
//   2. CAMBIAR sus opciones. Son de root, así que van por pkexec: tu agente
//      de polkit (mate-polkit, del autostart) te pide la contraseña. Se
//      escriben dos veces: en /sys/module/hid_apple/parameters, para que valga
//      YA, y en /etc/modprobe.d/hid_apple.conf, para que valga al reiniciar.
//
// Las tres opciones que se tocan (las demás de ese archivo se respetan):
//   fnmode        1 o 3 = la fila de arriba hace brillo/música (como macOS);
//                 2 = F1–F12 primero; 0 = solo F1–F12. 3 es "automático".
//   swap_opt_cmd  0 = como Mac; 1 = ⌘ y ⌥ intercambiadas. La shell lo deja en
//                 0: eso lo hace por teclado con xkb (ver AppleKeyboard),
//                 porque aquí valdría también para los genéricos.
//   iso_layout    -1 automático; 0 no; 1 sí intercambia ° con < (teclados ISO)

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ¿Está cargado el driver? Se carga solo al conectar un teclado Apple.
    property bool loaded: false

    // Lo que hay en /sys/module/hid_apple/parameters.
    property int fnmode: 3
    property int swapOptCmd: 0
    property int isoLayout: -1
    property bool hasIsoLayout: false

    property bool applying: false
    property string lastError: ""

    // ── leer ─────────────────────────────────────────────────────
    function refresh(): void {
        if (reader.running)
            reader.rerun = true;
        else
            reader.running = true;
    }

    // ── cambiar ──────────────────────────────────────────────────
    //
    // Las tres juntas, en UNA llamada: una sola contraseña.
    function apply(fnmode, swapOptCmd, isoLayout): void {
        const valid = [0, 1, 2, 3, 4].indexOf(fnmode) >= 0
                      && [0, 1].indexOf(swapOptCmd) >= 0
                      && [-1, 0, 1].indexOf(isoLayout) >= 0;
        if (!valid || writer.running)
            return;

        root.lastError = "";
        root.applying = true;
        writer.command = ["pkexec", "/bin/sh", "-c", root.writeScript, "sh",
                          String(fnmode), String(swapOptCmd), String(isoLayout)];
        writer.running = true;
    }

    // Lo que corre como root. Va como texto fijo y los valores como
    // argumentos ($1 $2 $3), nunca pegados al script: así un valor raro no
    // puede convertirse en un comando. Y se revisan otra vez aquí adentro.
    readonly property string writeScript: [
        "set -eu",
        "case \"$1\" in 0|1|2|3|4) ;; *) exit 2 ;; esac",
        "case \"$2\" in 0|1) ;; *) exit 2 ;; esac",
        "case \"$3\" in -1|0|1) ;; *) exit 2 ;; esac",
        "params=/sys/module/hid_apple/parameters",
        "conf=/etc/modprobe.d/hid_apple.conf",
        "if [ -d \"$params\" ]; then",
        "  printf '%s\\n' \"$1\" > \"$params/fnmode\"",
        "  printf '%s\\n' \"$2\" > \"$params/swap_opt_cmd\"",
        "  if [ -e \"$params/iso_layout\" ]; then printf '%s\\n' \"$3\" > \"$params/iso_layout\"; fi",
        "fi",
        "keep=''",
        "if [ -f \"$conf\" ]; then",
        "  keep=$(sed -n 's/^[[:space:]]*options[[:space:]][[:space:]]*hid_apple[[:space:]]//p' \"$conf\" | tr -s ' \\t' '\\n\\n' | grep -vE '^(fnmode|swap_opt_cmd|iso_layout)=|^$' | tr '\\n' ' ' || true)",
        "fi",
        "mkdir -p /etc/modprobe.d",
        "{",
        "  echo '# Lo escribe tu shell: Ajustes › Teclado. Se reescribe cada vez que'",
        "  echo '# cambias algo ahí; otras opciones de hid_apple en esta línea se conservan.'",
        "  printf 'options hid_apple fnmode=%s swap_opt_cmd=%s iso_layout=%s %s\\n' \"$1\" \"$2\" \"$3\" \"$keep\"",
        "} > \"$conf.new\"",
        "mv \"$conf.new\" \"$conf\""
    ].join("\n")

    // ── internos ─────────────────────────────────────────────────

    readonly property string readScript: [
        "p=/sys/module/hid_apple/parameters",
        "if [ -d \"$p\" ]; then",
        "  echo loaded",
        "  for f in fnmode swap_opt_cmd iso_layout; do",
        "    [ -r \"$p/$f\" ] && printf 'param\\t%s\\t%s\\n' \"$f\" \"$(cat \"$p/$f\")\"",
        "  done",
        "fi",
        "exit 0"
    ].join("\n")

    function parse(text): void {
        let loaded = false;
        let hasIso = false;

        for (const line of text.split("\n")) {
            const parts = line.split("\t");

            if (parts[0] === "loaded") {
                loaded = true;
            } else if (parts[0] === "param" && parts.length === 3) {
                const value = parseInt(parts[2]);
                if (isNaN(value))
                    continue;
                if (parts[1] === "fnmode")
                    root.fnmode = value;
                else if (parts[1] === "swap_opt_cmd")
                    root.swapOptCmd = value;
                else if (parts[1] === "iso_layout") {
                    root.isoLayout = value;
                    hasIso = true;
                }
            }
        }

        root.loaded = loaded;
        root.hasIsoLayout = hasIso;
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

    Process {
        id: writer

        onExited: (exitCode, exitStatus) => {
            root.applying = false;
            // pkexec: 126 = cerraste la ventana de la contraseña o no te
            // autorizó; 127 = no hay agente de polkit que la pregunte.
            if (exitCode === 126)
                root.lastError = "No se cambió: no se autorizó.";
            else if (exitCode === 127)
                root.lastError = "No se cambió: no hay quien pida la contraseña (¿corre mate-polkit?).";
            else if (exitCode !== 0)
                root.lastError = "No se pudo cambiar la opción del teclado.";
            root.refresh();
        }
    }
}
