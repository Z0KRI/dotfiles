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
import qs.domain.phone

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
    readonly property var typed: root.named(NotificationTypes.classify(root.current))

    // La llamada de BlueFerry (📞) trae el contacto si BlueFerry lo conoce; si
    // no, solo el número. El iPhone sí lo dijo en su propio aviso (la copia
    // sin botones, que no se enseña): de ahí salen el nombre y, arriba, la
    // etiqueta ("mobile"), como en el iPhone. El número queda debajo.
    function named(typed) {
        if (typed.kind !== "call" || typed.answerAction !== "answer")
            return typed;

        const hint = Calls.hintFor(typed.title);
        if (!hint)
            return typed;

        return Object.assign({}, typed, {
            appName: hint.label.length > 0 ? hint.label : typed.appName,
            title: hint.name,
            message: typed.title
        });
    }
    
    readonly property bool replyable: root.typed.replyable
    readonly property bool holds: root.typed.holds

    readonly property string kind: root.typed.kind
    readonly property string appName: root.typed.appName
    readonly property string title: root.typed.title
    readonly property string message: root.typed.message
    readonly property string image: root.typed.image
    readonly property string icon: root.typed.icon
    readonly property string glyph: root.typed.glyph
    readonly property string glyphFamily: root.typed.glyphFamily

    // En una llamada: qué acción contesta y cuál rechaza. "answer"/"decline"
    // si viene de --calls (el audio va a la PC), "ancs-positive"/"ancs-negative"
    // si son los botones del iPhone (se contesta en el iPhone).
    readonly property string answerAction: root.typed.answerAction
    readonly property string declineAction: root.typed.declineAction

    // ¿Se puede contestar desde aquí? Una llamada del iPhone que llegó sin
    // botones suena igual, pero solo se contesta en el iPhone.
    readonly property bool answerable: root.answerAction !== ""

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

    // Tope del historial. Cada notificación guardada vive en memoria (con su
    // imagen, si trae), y las del iPhone se guardan todas: sin tope, el
    // historial crecería hasta que lo borraras a mano. Pasado el tope se
    // expiran las más viejas, como si se les hubiera acabado el tiempo.
    readonly property int historyLimit: 100
    property bool _trimming: false

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

    readonly property bool hasDefaultAction: root.defaultAction !== null

    // ── la cola ───────────────────────────────────────────────────

    // La puerta de entrada: lo que llega del servidor pasa por aquí antes de
    // tocar la cola. Qué se hace con cada una lo decide NotificationSettings
    // (No molestar, avisos apagados, apps silenciadas).
    function receive(notification): void {
        if (!notification)
            return;

        const typed = NotificationTypes.classify(notification);

        // Las llamadas no se apuntan como app: tienen su propia regla.
        if (typed.kind !== "call")
            NotificationSettings.remember(typed.appName, typed.fromPhone);

        const verdict = NotificationSettings.decide(typed);

        if (verdict === "show") {
            root.show(notification);
            return;
        }

        // "keep": no se toca. Sigue viva en el servidor y por eso sale en el
        // historial. "drop": se expira aquí, por la misma razón que en
        // advance(): si nadie la cierra, se queda viva para siempre.
        if (verdict === "drop")
            notification.expire();
    }

    function show(notification): void {
        if (!notification)
            return;

        const typed = NotificationTypes.classify(notification);

        if (typed.kind === "call") {
            root.showCall(notification, typed);
            return;
        }

        if (!root.hasCurrent) {
            root.current = notification;
            return;
        }

        root.queue = root.queue.concat([notification]);
    }

    // ── llamadas ──────────────────────────────────────────────────
    //
    // Una llamada no hace cola detrás de un mensaje: se adelanta, y lo que se
    // estaba enseñando vuelve al frente de la cola.
    //
    // Y de una misma llamada no se enseñan dos. Con ./install.sh --calls, una
    // llamada normal llega dos veces: la del iPhone (📱 Teléfono, sin
    // botones) y la de BlueFerry (📞, con Contestar). El iPhone suele ganar
    // la carrera, y antes su tarjeta tapaba a la que sí se contesta. Ahora se
    // queda la que se puede contestar, llegue primero o después.
    function isCall(item): bool {
        return !!item && NotificationTypes.classify(item).kind === "call";
    }

    function isAnswerableCall(item): bool {
        if (!item)
            return false;
        const typed = NotificationTypes.classify(item);
        return typed.kind === "call" && typed.answerAction !== "";
    }

    // Una llamada que solo avisa (sin botones).
    function isMirror(item): bool {
        if (!item)
            return false;
        const typed = NotificationTypes.classify(item);
        return typed.kind === "call" && typed.answerAction === "";
    }

    function showCall(notification, typed): void {
        const answerable = typed.answerAction !== "";

        // El aviso del iPhone nombra al que llama aunque luego sobre: se
        // apunta antes de decidir si se enseña.
        if (!answerable)
            Calls.noteCaller(typed.title, typed.callerLabel);

        // Llega la que solo avisa y ya hay una que se contesta: sobra.
        if (!answerable && (root.isAnswerableCall(root.current)
                            || root.queue.some(item => root.isAnswerableCall(item)))) {
            notification.expire();
            return;
        }

        // Llega la que se contesta: las que solo avisaban, fuera.
        let mirrors = [];
        if (answerable) {
            mirrors = root.queue.filter(item => root.isMirror(item));
            root.queue = root.queue.filter(item => !root.isMirror(item));
        }

        const leaving = root.current;

        if (!leaving) {
            root.current = notification;
        } else if (answerable && root.isMirror(leaving)) {
            root.current = notification;
            mirrors.push(leaving);
        } else if (!root.isCall(leaving)) {
            root.queue = [leaving].concat(root.queue);
            root.current = notification;
        } else {
            // Ya suena otra llamada: esta espera su turno.
            root.queue = root.queue.concat([notification]);
        }

        // Después de poner la nueva, igual que en dismissCurrent(): expirar
        // cambia la lista del servidor y prune() no debe ver un hueco.
        for (let i = 0; i < mirrors.length; ++i)
            mirrors[i].expire();
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

        root.trimHistory();
    }

    // La lista del servidor va de la más vieja a la más nueva. Expirar una
    // cambia esa lista y vuelve a llamar a prune(): la bandera evita que esa
    // vuelta anidada expire otra vez las mismas.
    function trimHistory(): void {
        if (root._trimming)
            return;

        const all = NotificationRepository.all;
        const kept = [];

        for (let i = 0; i < all.length; ++i) {
            const item = all[i];
            if (item && item !== root.current && root.queue.indexOf(item) === -1
                    && NotificationTypes.classify(item).keep)
                kept.push(item);
        }

        const extra = kept.length - root.historyLimit;
        if (extra <= 0)
            return;

        root._trimming = true;
        for (let i = 0; i < extra; ++i)
            kept[i].expire();
        root._trimming = false;
    }

    Connections {
        target: NotificationRepository

        function onArrived(notification) { root.receive(notification); }

        // Las reemitidas al recargar no se enseñan: ya se vieron en su momento.
        // Se quedan en el historial, que sale de la lista del servidor.
        function onRestored(notification) {}

        function onAllChanged() { root.prune(); }
    }
}