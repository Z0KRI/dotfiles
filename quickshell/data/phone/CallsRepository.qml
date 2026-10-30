pragma Singleton

// REPOSITORIO: las llamadas del iPhone que pasan por la PC (las de
// ./install.sh --calls), según BlueFerry. Sabe de transporte y de nada más.
//
// BlueFerry publica sus llamadas por D-Bus (Calls1.ListCalls, un JSON) y avisa
// de cada cambio con una señal vacía (Events1.CallsChanged). Quickshell no
// habla D-Bus genérico, así que:
//   - la señal se escucha con `gdbus monitor`, que vive mientras la shell:
//     unos pocos MB, y solo escribe una línea por aviso;
//   - la lista se pide con `busctl --json`, que la entrega como JSON y no hay
//     que descifrar el formato de GVariant.
// Las dos vienen con glib2 y systemd: no hay que instalar nada.
//
// Al puente de mensajes (PhoneBridge) no se le pregunta: no sabe de llamadas,
// y es un proceso de Python que solo arranca para responder.
//
// Datos planos hacia afuera: { id, state, direction, number, name, network }.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string busName: "io.weirdware.BlueFerry"
    readonly property string objectPath: "/io/weirdware/BlueFerry"
    readonly property string callsIface: "io.weirdware.BlueFerry.Calls1"

    // El estado de las llamadas en la PC ("ready", "disabled", "searching"…)
    // y las que hay ahora. Vacíos si BlueFerry no está o no responde.
    property string state: ""
    property var calls: []

    // ── pedir la lista ────────────────────────────────────────────
    //
    // Si llega otro aviso mientras se pide, se vuelve a pedir al terminar:
    // los avisos vienen en ráfaga (suena → activa) y el último manda.
    property bool _again: false

    function refresh(): void {
        if (list.running) {
            root._again = true;
            return;
        }
        list.running = true;
    }

    function hangup(id): void {
        Quickshell.execDetached(["busctl", "--user", "call", root.busName, root.objectPath,
                                 root.callsIface, "Hangup", "s", String(id)]);
    }

    function _parse(text): void {
        try {
            // busctl: {"type":"s","data":["<el JSON de BlueFerry>"]}
            const reply = JSON.parse(text);
            const payload = JSON.parse(reply.data[0]);

            root.state = String(payload.state || "");
            root.calls = (payload.calls || []).map(call => ({
                id: String(call.call_id || ""),
                state: String(call.state || ""),
                direction: String(call.direction || ""),
                number: String(call.number || ""),
                name: String(call.contact_name || ""),
                network: String(call.network_name || "")
            }));
        } catch (error) {
            // Sin BlueFerry, o con las llamadas apagadas, busctl falla y no
            // escribe nada: no hay llamadas.
            root.state = "";
            root.calls = [];
        }
    }

    Process {
        id: list

        command: ["busctl", "--user", "--json=short", "call", root.busName, root.objectPath,
                  root.callsIface, "ListCalls"]

        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }

        onExited: (exitCode, exitStatus) => {
            if (root._again) {
                root._again = false;
                list.running = true;
            }
        }
    }

    // ── los avisos ────────────────────────────────────────────────
    //
    // Al arrancar (y cada vez que BlueFerry vuelve) gdbus dice "is owned by":
    // se pide la lista, por si la shell arrancó con una llamada en curso. Sin
    // BlueFerry instalado no se queda nada corriendo.
    Process {
        command: ["sh", "-c", "command -v blueferry >/dev/null || exit 0; "
                  + "exec gdbus monitor --session --dest \"$1\" --object-path \"$2\"",
                  "sh", root.busName, root.objectPath]
        running: true

        stdout: SplitParser {
            onRead: line => {
                if (/\.CallsChanged\b/.test(line) || /is owned by/.test(line))
                    root.refresh();
                else if (/does not have an owner/.test(line)) {
                    root.state = "";
                    root.calls = [];
                }
            }
        }
    }
}
