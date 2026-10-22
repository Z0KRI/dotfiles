pragma Singleton

// TIPAR: convertir lo que llega por el bus —tres cadenas de texto libre— en un
// objeto con campos fijos que la vista pueda pintar sin preguntar de dónde vino.
//
// BlueFerry manda CUATRO formatos por el mismo canal y los distingue un emoji
// al principio del resumen (src/blueferry/sinks/libnotify.py):
//
//   📱  app del teléfono (ANCS)  summary="📱 App"            body="remitente — mensaje"
//   💬  mensaje (MAP)            summary="💬 quien"           body="texto"
//   📞  llamada                  summary="📞 Incoming call"   body="nombre\nnúmero"
//   🔋  batería baja             summary="🔋 ..."             body="texto"
//
// Aquí viven las REGLAS. Los símbolos están en el tema (AppGlyphs): cambiar el
// glifo de WhatsApp no cambia nada de cómo se interpreta una notificación.

import QtQuick
import Quickshell
import qs.core.theme

Singleton {
    id: root

    readonly property string bridge: "BlueFerry"

    // Los emojis NO se escriben literales: en el origen son dos unidades
    // UTF-16, aquí solo hace falta el número, y encima es justo el carácter que
    // tu fuente no sabe pintar (la caja ◇ de la captura).
    readonly property int markChat: 0x1F4AC     // 💬
    readonly property int markCall: 0x1F4DE     // 📞
    readonly property int markBattery: 0x1F50B  // 🔋

    // Lo que BlueFerry pone entre remitente y mensaje: " — " (raya, no guion).
    readonly property string joiner: " \u2014 "

    // ── lo vacío ──────────────────────────────────────────────────
    //
    // Que exista un objeto para "no hay nada" ahorra un
    // `hasCurrent ? ... : ""` en cada campo de cada vista.
    function none() {
        return {
            kind: "none",
            appName: "",
            title: "",
            message: "",
            image: "",
            icon: "",
            glyph: AppGlyphs.fallback,
            fromPhone: false,
            replyable: false,
            holds: false,
            keep: false,
            source: null
        };
    }

    // ── utilidades ────────────────────────────────────────────────

    // Quita del principio los emojis, los selectores de variación y el espacio
    // que viene detrás. No busca el emoji concreto: tira todo lo que esté por
    // encima del texto normal, así sigue funcionando si BlueFerry cambia de
    // icono, y un nombre que empieza por "+" se queda intacto.
    function strip(text) {
        let s = String(text || "");

        while (s.length > 0) {
            const c = s.codePointAt(0);

            if (c > 0x2000 || c === 0x20 || c === 0x09) {
                // Un carácter fuera del plano básico ocupa DOS posiciones.
                s = s.slice(c > 0xFFFF ? 2 : 1);
                continue;
            }

            break;
        }

        return s.trim();
    }

    function mark(text) {
        const s = String(text || "");
        return s.length > 0 ? s.codePointAt(0) : 0;
    }

    // El camino inverso al `escape()` de BlueFerry, que escapa como HTML los
    // mensajes y las llamadas —no las notificaciones de apps— porque el campo
    // `body` del estándar acepta marcado. Tu servidor anuncia
    // `bodyMarkupSupported: false` y pinta texto plano, así que sin esto un "&"
    // te llega escrito "&amp;".
    //
    // NO se puede llamar `unescape`: es una global de JavaScript y QML no deja
    // taparla. El `&amp;` va el ÚLTIMO: si fuera el primero, "&amp;lt;"
    // acabaría en "<" en vez de en "&lt;".
    function unescapeMarkup(text) {
        return String(text || "")
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">")
            .replace(/&quot;/g, "\"")
            .replace(/&#x27;/g, "'")
            .replace(/&#39;/g, "'")
            .replace(/&apos;/g, "'")
            .replace(/&amp;/g, "&");
    }

    // Resuelve un nombre de icono del tema a una ruta, y devuelve "" si NO
    // EXISTE. Ese segundo argumento es el que mata el cuadriculado magenta: sin
    // él, `iconPath` devuelve una ruta igualmente, la Image falla al cargarla y
    // Qt pinta su marca de imagen rota.
    function iconFor(name) {
        if (!name)
            return "";

        return Quickshell.iconPath(String(name), true);
    }

    // "app.zen_browser.zen" → "Zen".
    function fromEntry(entry) {
        const parts = String(entry || "").split(".");
        const last = parts.length > 0 ? parts[parts.length - 1] : "";

        if (last.length === 0)
            return "";

        return last.charAt(0).toUpperCase() + last.slice(1);
    }

    // ── las reglas ────────────────────────────────────────────────
    function classify(n) {
        if (!n)
            return root.none();

        if (String(n.appName || "") === root.bridge)
            return root.fromBridge(n);

        return root.fromDesktop(n);
    }

    function fromBridge(n) {
        const summary = String(n.summary || "");
        const body = String(n.body || "");
        const kind = root.mark(summary);

        // ── llamada entrante ──
        //
        // El cuerpo trae nombre y número en dos líneas. Si el contacto no
        // tiene nombre, viene una sola.
        if (kind === root.markCall) {
            const lines = root.unescapeMarkup(body).split("\n");

            return {
                kind: "call",
                appName: root.unescapeMarkup(root.strip(summary)),
                title: (lines[0] || "").trim(),
                message: lines.length > 1 ? (lines[1] || "").trim() : "",
                image: String(n.image || ""),
                icon: "",
                glyph: AppGlyphs.glyph("", "call"),
                fromPhone: true,
                replyable: false,

                // RETIENE la isla: no se pasa a la siguiente mientras suena.
                // BlueFerry la manda con `expire_timeout = 0` y la cierra él
                // cuando deja de sonar, así que el temporizador de la cola no
                // tiene nada que decidir aquí.
                holds: true,

                // Fuera del historial a propósito: las llamadas tienen su
                // propio registro (PBAP), no son notificaciones viejas.
                keep: false,
                source: n
            };
        }

        // ── SMS / iMessage ──
        if (kind === root.markChat) {
            return {
                kind: "phone-message",
                appName: "Mensajes",

                // El remitente también viene escapado en esta rama.
                title: root.unescapeMarkup(root.strip(summary)),
                message: root.unescapeMarkup(body),
                image: String(n.image || ""),
                icon: "",
                glyph: AppGlyphs.glyph("", "phone-message"),
                fromPhone: true,

                // Lo único a lo que se puede contestar desde aquí: BlueFerry
                // sabe mandar SMS e iMessage, no un WhatsApp.
                replyable: true,
                holds: false,
                keep: true,
                source: n
            };
        }

        // ── batería del teléfono ──
        if (kind === root.markBattery) {
            return {
                kind: "phone-battery",
                appName: "iPhone",
                title: root.strip(summary),
                message: body,
                image: "",
                icon: "",
                glyph: AppGlyphs.glyph("", "phone-battery"),
                fromPhone: true,
                replyable: false,
                holds: false,
                keep: true,
                source: n
            };
        }

        // ── app del teléfono: "📱 App" + "remitente — mensaje" ──
        const app = root.strip(summary);
        const cut = body.indexOf(root.joiner);

        // La PRIMERA raya, no todas: si el mensaje lleva otra dentro, se queda
        // donde está. Y si no hay ninguna, la notificación no traía título
        // propio: todo el cuerpo es el mensaje y no hay remitente.
        const title = cut > 0 ? body.slice(0, cut) : "";
        const message = cut > 0 ? body.slice(cut + root.joiner.length) : body;

        return {
            kind: "phone-app",
            appName: app.length > 0 ? app : "iPhone",
            title: title.trim(),
            message: message.trim(),
            image: String(n.image || ""),

            // Vacío a propósito: el icono del puente es el mismo teléfono
            // genérico para todo, y el glifo de la app dice mucho más.
            icon: "",
            glyph: AppGlyphs.glyph(app, "phone-app"),
            fromPhone: true,
            replyable: false,
            holds: false,

            // BlueFerry las manda `transient` ("no la guardes"). Aquí se decide
            // lo contrario: ver en el centro de control lo que pasó en el
            // teléfono mientras no mirabas es justo para lo que sirve. Ponlo a
            // `false` si prefieres respetar lo que pide el puente.
            keep: true,
            source: n
        };
    }

    function fromDesktop(n) {
        const raw = String(n.appName || "");
        const entry = String(n.desktopEntry || "");
        const app = raw.length > 0 ? raw : root.fromEntry(entry);

        // Tres intentos, de lo más preciso a lo más genérico. Zen manda
        // `appIcon` vacío pero sí manda desktop-entry, y de ahí sale.
        const icon = root.iconFor(n.appIcon)
            || root.iconFor(entry)
            || root.iconFor(app.toLowerCase());

        return {
            kind: "desktop",
            appName: app,
            title: String(n.summary || ""),
            message: String(n.body || ""),
            image: String(n.image || ""),
            icon: icon,
            glyph: AppGlyphs.glyph(app.length > 0 ? app : entry, "desktop"),
            fromPhone: false,
            replyable: false,
            holds: false,

            // Aquí sí se respeta: una app que pide no ser guardada sabe lo que
            // dice (un aviso de volumen, por ejemplo).
            keep: !n.transient,
            source: n
        };
    }
}