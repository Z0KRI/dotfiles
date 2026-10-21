pragma Singleton

// El ÚNICO archivo que habla con BlueFerry. Capa de datos: sabe de transporte
// y de nada más.
//
// Quickshell no tiene un tipo QML para D-Bus genérico, así que no se puede
// llamar a io.weirdware.BlueFerry directamente. BlueFerry resuelve eso con un
// ejecutable puente que habla JSON por líneas: una línea por petición, una por
// respuesta. Se mantiene vivo todo el rato, no se arranca uno por llamada.
//
// Por stdin y no por argumentos: lo que escribes en argv lo lee cualquier
// proceso de tu usuario en /proc. Un mensaje privado no va por ahí.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string executable: "/usr/bin/blueferry-quickshell-bridge"

    // ¿el puente está vivo? Si BlueFerry no está instalado, esto se queda en
    // false y toda la feature se apaga sola en lugar de dar errores.
    readonly property bool ready: bridge.running && root._started

    property bool _started: false
    property int _nextId: 1

    // id → { ok: function, fail: function }. Las peticiones son asíncronas y
    // pueden volver desordenadas, así que cada una se guarda con su número.
    property var _pending: ({})

    signal event(string name, var data)
    signal failed(string method, string message)

    // ── pedir ─────────────────────────────────────────────────────
    //
    // `onOk` y `onFail` son opcionales. Devuelve el id por si quieres
    // descartar una respuesta vieja.
    function call(method, args, onOk, onFail) {
        if (!bridge.running)
            bridge.running = true;

        const id = root._nextId++;

        root._pending[id] = {
            method: method,
            ok: onOk || null,
            fail: onFail || null
        };

        bridge.write(JSON.stringify({
            id: id,
            method: method,
            args: args || {}
        }) + "\n");

        return id;
    }

    // ── recibir ───────────────────────────────────────────────────
    function _line(text): void {
        let payload = null;

        try {
            payload = JSON.parse(text);
        } catch (error) {
            root.failed("", "el puente de BlueFerry devolvió datos inválidos");
            return;
        }

        // Los eventos no llevan id: son avisos del teléfono, no respuestas.
        if (typeof payload.event === "string") {
            root.event(payload.event, payload.data);
            return;
        }

        const waiting = root._pending[payload.id];
        delete root._pending[payload.id];

        if (payload.ok === true) {
            if (waiting && waiting.ok)
                waiting.ok(payload.result);
            return;
        }

        const method = payload.method || (waiting ? waiting.method : "");
        const message = payload.error || "la petición a BlueFerry falló";

        if (waiting && waiting.fail)
            waiting.fail(message);

        root.failed(method, message);
    }

    Process {
        id: bridge

        command: [root.executable]
        running: true
        stdinEnabled: true

        stdout: SplitParser {
            onRead: function (line) { root._line(line); }
        }

        onStarted: root._started = true

        // Si BlueFerry no está instalado o el demonio se cae, no se reintenta
        // en bucle: se apaga y `ready` queda en false. Quien lo necesite, lo
        // vuelve a arrancar con la siguiente llamada a `call()`.
        onExited: function (code, status) {
            root._started = false;

            const ids = Object.keys(root._pending);
            for (let i = 0; i < ids.length; ++i) {
                const waiting = root._pending[ids[i]];
                if (waiting && waiting.fail)
                    waiting.fail("el puente de BlueFerry se cerró");
            }

            root._pending = ({});
        }
    }
}