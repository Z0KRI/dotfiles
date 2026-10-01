pragma Singleton

// Las REGLAS de las notificaciones: la cola de lo que se enseña y el historial
// de lo que quedó.
//
// La island es un consumidor de esto, no su dueña. El día que exista el centro
// de control, lee `history` desde aquí y no hay que mover nada.
//
// Una distinción que conviene no perder: pasar a la siguiente NO es descartar.
// `dismiss()` le dice a la aplicación "el usuario la cerró" y la destruye; la
// cola solo deja de enseñarla. Por eso el historial sale gratis.

import QtQuick
import Quickshell
import qs.data.notifications

Singleton {
    id: root

    // La que se está enseñando. null cuando no hay nada que enseñar.
    property var current: null

    // Las que esperan turno: las que han llegado y todavía no han salido.
    property var queue: []

    readonly property bool hasCurrent: root.current !== null

    // El historial, de la más nueva a la más vieja. Sale de la lista del
    // servidor, así que se poda solo: lo descartado desaparece.
    //
    // Las `transient` se quedan fuera: el que las manda pide explícitamente
    // que no se guarden en ningún área de notificaciones.
    readonly property var history: {
        const all = NotificationRepository.all
        const out = []
        for (let i = all.length - 1; i >= 0; --i) {
            const item = all[i]
            if (item && !item.transient)
                out.push(item)
        }
        return out
    }

    readonly property int count: root.history.length

    // ── lo que la vista lee de la actual ──────────────────────────
    //
    // Muchas aplicaciones mandan el nombre vacío —Zen entre ellas— y lo único
    // que las identifica es su entrada de escritorio. De "app.zen_browser.zen"
    // sale "Zen", que es mejor que un hueco.
    readonly property string appName: {
        if (!root.hasCurrent)
            return ""

        const given = root.current.appName
        if (given.length > 0)
            return given

        const entry = root.current.desktopEntry
        if (entry.length === 0)
            return ""

        const parts = entry.split(".")
        const last = parts[parts.length - 1]
        return last.charAt(0).toUpperCase() + last.slice(1)
    }

    readonly property string summary: root.hasCurrent ? root.current.summary : ""
    readonly property string body: root.hasCurrent ? root.current.body : ""
    readonly property string image: root.hasCurrent ? root.current.image : ""
    readonly property string appIcon: root.hasCurrent ? root.current.appIcon : ""

    // ── las acciones ──────────────────────────────────────────────
    //
    // "default" NO es un botón: por especificación es lo que se invoca al
    // pulsar el cuerpo de la notificación, y suele venir con el texto vacío.
    // Dibujarla como botón deja un rectángulo sin etiqueta.
    readonly property var allActions: root.hasCurrent ? root.current.actions : []

    readonly property var defaultAction: {
        const list = root.allActions
        for (let i = 0; i < list.length; ++i) {
            if (list[i] && list[i].identifier === "default")
                return list[i]
        }
        return null
    }

    readonly property var actions: {
        const list = root.allActions
        const out = []
        for (let i = 0; i < list.length; ++i) {
            const item = list[i]
            if (item && item.identifier !== "default" && item.text.length > 0)
                out.push(item)
        }
        return out
    }

    readonly property bool hasActions: root.actions.length > 0
    readonly property bool hasDefaultAction: root.defaultAction !== null

    // ── la cola ───────────────────────────────────────────────────

    function show(notification): void {
        if (!notification)
            return;

        if (!root.hasCurrent) {
            root.current = notification;
            return;
        }

        root.queue = root.queue.concat([notification]);
    }

    // Saca la primera viva de la cola. Devuelve null si no queda ninguna.
    function takeFromQueue(): var {
        let rest = root.queue;
        let next = null;

        while (rest.length > 0 && next === null) {
            const candidate = rest[0];
            rest = rest.slice(1);
            if (candidate)
                next = candidate;
        }

        root.queue = rest;
        return next;
    }

    // La más reciente de las que siguen sin atender, saltándose una.
    function nextPending(excluding): var {
        const list = root.history;
        for (let i = 0; i < list.length; ++i) {
            if (list[i] && list[i] !== excluding)
                return list[i];
        }
        return null;
    }

    // Se le acabó el tiempo: la siguiente de la cola y punto. Si no queda
    // ninguna, la island se retira — nadie estaba mirando.
    function advance(): void {
        const leaving = root.current;
        const next = root.takeFromQueue();

        root.current = next;

        // Una transient no va al historial, así que si no se destruye aquí se
        // queda viva para siempre sin que nadie la vea. `expire()` y no
        // `dismiss()`: se acabó su tiempo, el usuario no la cerró.
        if (leaving && leaving !== next && leaving.transient)
            leaving.expire();
    }

    // El usuario la cerró. Aquí SÍ se busca entre las pendientes: si está
    // descartando es que está mirando, y retirar la island en ese momento lo
    // deja esperando a que vuelva sola.
    //
    // El orden importa: primero se elige la siguiente y se pone, y solo
    // después se destruye la vieja. Al revés, la poda automática vería una
    // `current` muerta y se adelantaría a cerrar.
    function dismissCurrent(): void {
        const leaving = root.current;
        if (!leaving)
            return;

        let next = root.takeFromQueue();
        if (next === null)
            next = root.nextPending(leaving);

        root.current = next;
        leaving.dismiss();
    }

    function dismiss(notification): void {
        if (!notification)
            return;

        if (notification === root.current) {
            root.dismissCurrent();
            return;
        }

        notification.dismiss();
    }

    function dismissAll(): void {
        const all = NotificationRepository.all.slice();
        root.queue = [];
        root.current = null;
        for (let i = 0; i < all.length; ++i) {
            if (all[i])
                all[i].dismiss();
        }
    }

    // Invocar una acción destruye la notificación salvo que sea `resident`,
    // así que se trata igual que un descarte: se elige la siguiente antes.
    function invoke(action): void {
        if (!action)
            return;

        const owner = root.current;

        let next = root.takeFromQueue();
        if (next === null)
            next = root.nextPending(owner);

        root.current = next;
        action.invoke();
    }

    function invokeDefault(): void {
        root.invoke(root.defaultAction);
    }

    // ── mantenimiento ─────────────────────────────────────────────
    //
    // Una aplicación puede cerrar su propia notificación en cualquier momento.
    // Cuando eso pasa desaparece de la lista del servidor y aquí quedaría una
    // referencia muerta, así que se revisa en cada cambio.
    function prune(): void {
        const all = NotificationRepository.all;

        root.queue = root.queue.filter(function (item) {
            return item && all.indexOf(item) !== -1;
        });

        if (root.hasCurrent && all.indexOf(root.current) === -1)
            root.advance();
    }

    Connections {
        target: NotificationRepository

        function onArrived(notification) { root.show(notification); }

        // Las reemitidas al recargar no se enseñan: ya se vieron en su momento.
        // Se quedan en el historial, que sale de la lista del servidor.
        function onRestored(notification) {}

        function onAllChanged() { root.prune(); }
    }
}