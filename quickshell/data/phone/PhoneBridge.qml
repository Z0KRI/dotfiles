pragma Singleton

// El ÚNICO archivo que habla con BlueFerry. Capa de datos: sabe de transporte
// y de nada más.
//
// Quickshell no tiene un tipo QML para D-Bus genérico, así que no se puede
// llamar a io.weirdware.BlueFerry directamente. BlueFerry resuelve eso con un
// ejecutable puente que habla JSON por líneas: una línea por petición, una por
// respuesta.
//
// Por stdin y no por argumentos: lo que escribes en argv lo lee cualquier
// proceso de tu usuario en /proc. Un mensaje privado no va por ahí.
//
// El puente es un proceso de Python (decenas de MB) y solo hace falta para
// responder mensajes. Por eso NO vive todo el rato: arranca con la primera
// petición y se apaga solo tras un rato sin uso. Al arrancar la shell solo se
// comprueba que esté instalado, con un proceso que dura milisegundos.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string executable: "/usr/bin/blueferry-quickshell-bridge"

    // ¿se puede usar? = está instalado. Si BlueFerry no está, la función de
    // responder se apaga sola en lugar de dar errores.
    property bool installed: false

    // Cuánto se queda vivo el puente después de la última respuesta. Si
    // contestas varios mensajes seguidos, no se arranca uno por cada uno.
    readonly property int idleTimeout: 120000

    property int _nextId: 1

    // id → { ok: function, fail: function }. Las peticiones son asíncronas y
    // pueden volver desordenadas, así que cada una se guarda con su número.
    property var _pending: ({})

    // Lo que se pidió antes de que el proceso terminara de arrancar.
    property var _outbox: []

    // ── pedir ─────────────────────────────────────────────────────
    //
    // `onOk` y `onFail` son opcionales. Devuelve el id por si quieres
    // descartar una respuesta vieja.
    function call(method, args, onOk, onFail) {
        const id = root._nextId++;

        root._pending[id] = {
            ok: onOk || null,
            fail: onFail || null
        };

        const line = JSON.stringify({ id: id, method: method, args: args || {} }) + "\n";

        idle.stop();

        if (bridge.running) {
            bridge.write(line);
        } else {
            root._outbox = root._outbox.concat([line]);
            bridge.running = true;
        }

        return id;
    }

    // ── recibir ───────────────────────────────────────────────────
    function _line(text): void {
        let payload = null;

        // Una línea que no es JSON no es una respuesta: no hay a quién
        // avisarle, así que se descarta.
        try {
            payload = JSON.parse(text);
        } catch (error) {
            return;
        }

        // Los eventos no llevan id: son avisos del teléfono, no respuestas.
        // Hoy nadie los usa (las notificaciones llegan por el bus), así que
        // se ignoran.
        if (typeof payload.event === "string")
            return;

        const waiting = root._pending[payload.id];
        delete root._pending[payload.id];

        if (Object.keys(root._pending).length === 0)
            idle.restart();

        if (payload.ok === true) {
            if (waiting && waiting.ok)
                waiting.ok(payload.result);
            return;
        }

        if (waiting && waiting.fail)
            waiting.fail(payload.error || "la petición a BlueFerry falló");
    }

    // ¿Está instalado? Una sola vez, al arrancar.
    Process {
        command: ["test", "-x", root.executable]
        running: true
        onExited: (exitCode, exitStatus) => root.installed = exitCode === 0
    }

    Process {
        id: bridge

        command: [root.executable]
        stdinEnabled: true

        stdout: SplitParser {
            onRead: function (line) { root._line(line); }
        }

        onStarted: {
            const lines = root._outbox;
            root._outbox = [];
            for (let i = 0; i < lines.length; ++i)
                bridge.write(lines[i]);
        }

        // Al apagarlo por inactividad no queda nada pendiente. Si se cae con
        // peticiones en vuelo (BlueFerry sin desbloquear, el demonio caído),
        // se avisa a cada una; no se reintenta en bucle: la siguiente llamada
        // lo vuelve a arrancar.
        onExited: function (code, status) {
            idle.stop();

            const ids = Object.keys(root._pending);
            for (let i = 0; i < ids.length; ++i) {
                const waiting = root._pending[ids[i]];
                if (waiting && waiting.fail)
                    waiting.fail("el puente de BlueFerry se cerró");
            }

            root._pending = ({});
            root._outbox = [];
        }
    }

    Timer {
        id: idle
        interval: root.idleTimeout
        onTriggered: bridge.running = false
    }
}
