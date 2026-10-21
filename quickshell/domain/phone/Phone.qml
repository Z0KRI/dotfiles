pragma Singleton

// Las reglas del teléfono: qué se puede responder y cómo.
//
// Responder desde una notificación tiene un problema que no es evidente: la
// notificación trae el NOMBRE de quien escribe, pero BlueFerry necesita la
// clave del hilo. Así que hay que buscarla. Se pide la lista de conversaciones,
// se busca la que coincide por nombre, y se manda ahí.
//
// Y se manda solo si la conversación es de una persona. Los grupos exigen
// confirmar la lista de participantes —el iPhone puede haberla cambiado— y eso
// no se decide desde una isla de 32 píxeles de alto.

import QtQuick
import Quickshell
import qs.data.phone

Singleton {
    id: root

    readonly property bool available: PhoneBridge.ready

    // Lo último que pasó, para poder enseñarlo en la isla.
    property string lastError: ""
    property bool sending: false

    signal sent(string recipient)

    // ── responder ─────────────────────────────────────────────────
    //
    // `name` es el remitente tal y como lo pintó la notificación.
    function reply(name, text): void {
        const body = String(text || "").trim();
        const who = String(name || "").trim();

        if (body.length === 0 || who.length === 0)
            return;

        root.lastError = "";
        root.sending = true;

        // Pocas conversaciones: la que acaba de escribir está arriba. Pedir
        // 200 traería el historial entero de cada una por nada.
        PhoneBridge.call("threads", { limit: 30 },
            function (threads) { root._withThreads(who, body, threads); },
            function (message) { root._fail(message); });
    }

    function _withThreads(who, body, threads): void {
        const thread = root._match(who, threads);

        if (!thread) {
            root._fail("no encuentro la conversación de " + who);
            return;
        }

        if (thread.is_group) {
            root._fail("responder a un grupo se hace en el cliente de BlueFerry");
            return;
        }

        if (thread.reply_ready === false) {
            root._fail("esa conversación todavía no acepta respuestas");
            return;
        }

        PhoneBridge.call("send_to_thread", {
                thread_key: thread.key,
                body: body,
                confirm_group: false,
                expected_group_token: String(thread.confirmation_token || "")
            },
            function (result) {
                root.sending = false;
                root.sent(who);

                // Ya respondiste: en el teléfono tampoco sigue sin leer.
                PhoneBridge.call("mark_thread_read", { thread_key: thread.key });
            },
            function (message) { root._fail(message); });
    }

    // Primero exacto, luego sin distinguir mayúsculas, y por último por
    // número: la notificación de un desconocido trae "+52777..." y el hilo
    // puede guardarlo con espacios.
    function _match(who, threads): var {
        const list = threads || [];
        const target = who.toLowerCase();
        const digits = who.replace(/\D/g, "");

        for (let i = 0; i < list.length; ++i) {
            if (list[i] && list[i].name === who)
                return list[i];
        }

        for (let i = 0; i < list.length; ++i) {
            if (list[i] && String(list[i].name || "").toLowerCase() === target)
                return list[i];
        }

        if (digits.length >= 7) {
            for (let i = 0; i < list.length; ++i) {
                const thread = list[i];
                if (!thread)
                    continue;

                const recipients = thread.recipients || [];
                for (let j = 0; j < recipients.length; ++j) {
                    if (String(recipients[j] || "").replace(/\D/g, "") === digits)
                        return thread;
                }
            }
        }

        return null;
    }

    function _fail(message): void {
        root.sending = false;
        root.lastError = String(message || "");
    }

    // ── llamadas ──────────────────────────────────────────────────
    //
    // Contestar y colgar NO pasan por aquí: llegan como acciones de la
    // notificación de la llamada, y de eso se encarga el servidor de
    // notificaciones que ya tienes. Esto solo enciende la función.
    function setCallsEnabled(enabled): void {
        PhoneBridge.call("set_calls_enabled", { enabled: !!enabled });
    }
}