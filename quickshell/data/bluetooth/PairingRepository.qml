pragma Singleton

// REPOSITORIO: el único que habla con pair-agent.py, el agente de
// emparejamiento (está en esta misma carpeta; su cabecera explica por qué hace
// falta). Capa de datos: transporte y nada más. Qué significa cada evento y
// qué texto se enseña lo decide domain/bluetooth/BluetoothPairing.
//
// El agente es un proceso de Python que vive lo que dura UN emparejamiento:
// arranca al tocar "Conectar" y se cierra al terminar. No se queda en memoria
// esperando, como el puente de BlueFerry.
//
// Por stdin van las respuestas (el PIN que escribes, "sí coincide"). Por argv
// solo va la dirección del dispositivo, que no es nada privado.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string script: Quickshell.shellPath("data/bluetooth/pair-agent.py")

    // El que se está emparejando, o "".
    property string address: ""
    // `agent ?`: al cerrar la shell el proceso se destruye antes que esto.
    readonly property bool running: agent ? agent.running : false

    // Cada línea del agente, ya convertida en objeto: { event, code, ... }.
    signal event(var payload)

    // El proceso terminó: 0 = emparejado; otro = falló o se canceló (el
    // porqué llegó antes como evento "failed").
    signal ended(string address, int exitCode)

    // Un emparejamiento a la vez, como BlueZ. Si ya hay uno, se ignora.
    function start(address): bool {
        if (agent.running)
            return false;

        root.address = address;
        agent.command = ["python3", "-I", root.script, address];
        agent.running = true;
        return true;
    }

    function send(command): void {
        if (agent.running)
            agent.write(JSON.stringify(command) + "\n");
    }

    function accept(): void {
        root.send({ action: "accept" });
    }

    function reject(): void {
        root.send({ action: "reject" });
    }

    function answerPin(pin): void {
        root.send({ action: "pin", value: String(pin) });
    }

    function answerPasskey(passkey): void {
        root.send({ action: "passkey", value: String(passkey) });
    }

    // Cancelar con calma: el agente le dice a BlueZ que pare y sale solo.
    function cancel(): void {
        root.send({ action: "cancel" });
    }

    Process {
        id: agent

        // Abierto todo el rato: si stdin se cierra, el agente entiende que la
        // shell se fue y cancela.
        stdinEnabled: true

        stdout: SplitParser {
            onRead: function (line) {
                let payload = null;
                try {
                    payload = JSON.parse(line);
                } catch (error) {
                    return;
                }
                if (payload && typeof payload.event === "string")
                    root.event(payload);
            }
        }

        onExited: function (exitCode, exitStatus) {
            const address = root.address;
            root.address = "";
            root.ended(address, exitCode);
        }

        // Si ni siquiera arranca (no hay python3), Quickshell no emite
        // `exited`: solo deja de correr. 127 es lo que da la terminal cuando
        // un comando no existe.
        onRunningChanged: {
            if (!agent.running && root.address !== "") {
                const address = root.address;
                root.address = "";
                root.ended(address, 127);
            }
        }
    }
}
