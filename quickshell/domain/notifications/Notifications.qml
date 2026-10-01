pragma Singleton

// Las REGLAS de las notificaciones: la cola de lo que se enseña y el historial
// de lo que quedó.
//
// Lo que sale de aquí ya viene TIPADO —`appName`, `title`, `message`, `icon`,
// `glyph`—, así que ninguna vista vuelve a leer el texto crudo del bus. Si
// mañana aparece otro puente con otro formato, se añade un caso en
// NotificationTypes y las vistas no se tocan.
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

    // Las que esperan turno.
    property var queue: []

    readonly property bool hasCurrent: root.current !== null

    // ── la actual, tipada ─────────────────────────────────────────
    //
    // Una sola llamada y de ella salen todos los campos. El binding se vuelve
    // a evaluar cuando cambia `current` y también cuando una aplicación
    // REEMPLAZA el contenido de una notificación que ya estaba: `classify` lee
    // `summary` y `body`, y QML apunta como dependencia todo lo que se lee
    // mientras evalúa, aunque se lea dentro de una función.
    readonly property var typed: NotificationTypes.classify(root.current)

    readonly property string kind: root.typed.kind
    readonly property string appName: root.typed.appName
    readonly property string title: root.typed.title
    readonly property string message: root.typed.message
    readonly property string image: root.typed.image
    readonly property string icon: root.typed.icon
    readonly property string glyph: root.typed.glyph
    readonly property bool fromPhone: root.typed.fromPhone

    // ── el historial ──────────────────────────────────────────────
    //
    // De la más nueva a la más vieja, y ya tipado: el centro de control lo
    // leerá de aquí y pintará igual que la island. Cada entrada lleva su
    // `source`, que es la notificación de verdad, para poder descartarla o
    // invocar sus acciones.
    //
    // Sale de la lista del servidor, así que se poda solo: lo descartado
    // desaparece. Lo que entra lo decide `keep`, no `transient` — las del
    // iPhone llegan marcadas como transitorias y aquí sí se guardan.
    readonly property var history: {
        const all = NotificationRepository.all
        const out = []

        for (let i = all.length - 1; i >= 0; --i) {
            const item = all[i]
            if (!item)
                continue

            const entry = NotificationTypes.classify(item)
            if (entry.keep)
                out.push(entry)
        }

        return out
    }

    readonly property int count: root.history.length

    // ── acciones ──────────────────────────────────────────────────
    readonly property var allActions: root.hasCurrent ? root.current.actions : []

    // La "default" no es un botón: es lo que pasa al tocar la notificación
    // entera. Zen manda ["default", ""], sin texto, y si se pintara saldría un
    // botón vacío. En los mensajes del iPhone es "Open conversation", que abre
    // la conversación en el puente — por eso merece la pena distinguirla.
    readonly property var defaultAction: {
        const list = root.allActions

        for (let i = 0; i < list.length; ++i) {
            if (list[i] && list[i].identifier === "default")
                return list[i]
        }

        return null
    }

    // Las que sí son botones: todo lo que no es la default y tiene texto que
    // poner dentro.
    readonly property var actions: {
        const list = root.allActions
        const out = []

        for (let i = 0; i < list.length; ++i) {
            const action = list[i]

            if (action && action.identifier !== "default"
                    && String(action.text || "").length > 0)
                out.push(action)
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

    // Saca la siguiente válida de la cola y la devuelve, o null si no queda
    // ninguna. Salta los huecos: una notificación de la cola puede haber sido
    // cerrada por su aplicación mientras esperaba turno.
    function nextPending() {
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

    // Se le acabó el tiempo. Si no queda ninguna, la island se retira sola
    // porque el ocupante deja de estar activo.
    function advance(): void {
        const leaving = root.current;
        const keep = leaving ? NotificationTypes.classify(leaving).keep : true;

        root.current = root.nextPending();

        // Lo que no se guarda hay que destruirlo aquí: si no va al historial y
        // nadie la cierra, se queda viva para siempre sin que nadie la vea.
        // `expire()` y no `dismiss()`: se acabó su tiempo, el usuario no la
        // cerró, y esa diferencia la ve la aplicación que la mandó.
        if (leaving && leaving !== root.current && !keep)
            leaving.expire();
    }

    // El usuario la cerró de verdad: se destruye y sale del historial.
    function dismissCurrent(): void {
        const leaving = root.current;

        if (!leaving)
            return;

        // El orden importa. Primero se decide quién entra y se pone, y solo
        // después se destruye la que sale. Al revés, destruirla cambia la lista
        // del servidor, `prune()` se dispara con `current` ya muerta, y la
        // island se cierra entera en vez de pasar a la siguiente.
        root.current = root.nextPending();
        leaving.dismiss();
    }

    function dismiss(notification): void {
        if (!notification)
            return;

        if (notification === root.current) {
            root.dismissCurrent();
            return;
        }

        root.queue = root.queue.filter(function (item) {
            return item !== notification;
        });

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

    function invoke(action): void {
        if (!action)
            return;

        // La acción destruye la notificación salvo que sea `resident`, así que
        // se sale de ella antes de invocarla.
        const owner = root.current;
        action.invoke();

        if (owner === root.current)
            root.advance();
    }

    function invokeDefault(): void {
        if (root.hasDefaultAction)
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