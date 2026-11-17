pragma Singleton

// REPETIDAS: el mismo mensaje que llega dos veces, una por la computadora y
// otra por el iPhone.
//
// Pasa con cualquier cosa que tengas abierta en los dos lados: WhatsApp Web en
// Zen y WhatsApp en el iPhone, Telegram, Discord, el correo. El iPhone no sabe
// que la computadora ya te avisó, así que manda la suya igual.
//
// La regla no conoce ninguna app. Dos notificaciones son la misma cuando:
//
//   1. Una viene del iPhone y la otra de la computadora. Dos del mismo lado
//      nunca son repetidas: si alguien te escribe "ok" dos veces, son dos.
//   2. Llegaron con menos de `window` de diferencia.
//   3. Dicen lo mismo (`same`): mismo mensaje, y mismo remitente o un mensaje
//      lo bastante largo para que no sea casualidad.
//
// Aquí solo se RECONOCEN. Qué se hace con ellas (gana la de la computadora,
// que es la que se puede tocar para abrir la conversación) lo decide
// Notifications, que es el dueño de la cola.

import QtQuick
import Quickshell
import qs.data.system

Singleton {
    id: root

    readonly property bool enabled: PreferencesRepository.notificationDedupe

    function setEnabled(on): void {
        PreferencesRepository.notificationDedupe = on;
    }

    // Cuánto puede tardar la segunda copia. El iPhone suele llegar un par de
    // segundos después (o antes); un navegador dormido puede tardar más.
    readonly property int window: 30000

    // Con el remitente distinto, el mensaje tiene que medir al menos esto (ya
    // sin espacios ni signos) para contar como el mismo. Un número sin
    // guardar se escribe distinto en cada lado ("+52 1 55…" y "+52 55…"), y
    // ahí el mensaje decide; pero un "ok" de dos personas distintas no es el
    // mismo mensaje.
    readonly property int minLength: 12

    // Solo lo que es un mensaje. Las llamadas tienen su propia regla
    // (Notifications.showCall), y la batería o una llamada perdida solo las
    // manda el iPhone.
    function eligible(typed): bool {
        return !!typed && (typed.kind === "desktop"
                           || typed.kind === "phone-app"
                           || typed.kind === "phone-message");
    }

    // El texto reducido a lo que no cambia entre un lado y otro: letras y
    // números en minúsculas. Fuera espacios, saltos, signos y emojis.
    //
    // Hace falta porque cada lado escribe lo mismo a su manera. Un grupo de
    // WhatsApp es "Ana: hola" en el navegador y "Ana" + salto + "hola" en el
    // iPhone; el iPhone además mete marcas invisibles alrededor de los
    // nombres, y un emoji puede traer o no su selector de variación.
    //
    // Lo natural sería "todo lo que no sea letra o número" (\p{L}, \p{N}),
    // pero el motor de JavaScript de QML no entiende esas clases: no falla,
    // simplemente no quita nada. Por eso van los rangos a mano:
    //
    //   \s                  espacios y saltos
    //   0000-002F … 007B-00BF  signos de ASCII y de Latin-1 (¿ ¡ « » ·)
    //   2000-2BFF            puntuación general, marcas invisibles, flechas,
    //                        símbolos y los emojis viejos (☀ ✔)
    //   3000-303F            puntuación china y japonesa
    //   FE00-FE0F            selectores de variación
    //   D800-DFFF            las dos mitades de todo lo que está fuera del
    //                        plano básico: ahí viven los emojis
    readonly property var noise: /[\s\u0000-\u002F\u003A-\u0040\u005B-\u0060\u007B-\u00BF\u2000-\u2BFF\u3000-\u303F\uFE00-\uFE0F\uD800-\uDFFF]+/g

    function squash(text): string {
        return String(text || "").toLowerCase().replace(root.noise, "");
    }

    function same(a, b): bool {
        if (a.message !== b.message)
            return false;

        if (a.title === b.title)
            return a.title.length + a.message.length > 0;

        return a.message.length >= root.minLength;
    }

    // ── la memoria ────────────────────────────────────────────────
    //
    // Lo que llegó en los últimos `window` milisegundos:
    // [{ source, fromPhone, title, message, at }]. Se guarda aparte de la
    // cola porque la primera copia puede haberse enseñado y cerrado ya cuando
    // llega la segunda.
    property var recent: []

    function note(typed): void {
        const now = Date.now();

        root.recent = root.recent
            .filter(entry => now - entry.at < root.window)
            .concat([{
                source: typed.source,
                fromPhone: typed.fromPhone,
                title: root.squash(typed.title),
                message: root.squash(typed.message),
                at: now
            }]);
    }

    // La otra copia de esta notificación, si ya llegó: la notificación de
    // verdad (para poder cerrarla), o null. Cada copia se empareja una sola
    // vez: `forget` la saca de la memoria.
    function twinOf(typed) {
        if (!root.enabled || !root.eligible(typed))
            return null;

        const now = Date.now();
        const mine = {
            title: root.squash(typed.title),
            message: root.squash(typed.message)
        };

        for (let i = root.recent.length - 1; i >= 0; --i) {
            const entry = root.recent[i];

            if (now - entry.at < root.window
                    && entry.fromPhone !== typed.fromPhone
                    && root.same(entry, mine))
                return entry.source;
        }

        return null;
    }

    function forget(notification): void {
        root.recent = root.recent.filter(entry => entry.source !== notification);
    }
}
