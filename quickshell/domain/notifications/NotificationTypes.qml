pragma Singleton

// TIPAR: convertir lo que llega por el bus —tres cadenas de texto libre— en un
// objeto con campos fijos que la vista pueda pintar sin preguntar de dónde vino.
//
// Hace falta porque el estándar de notificaciones no tiene sitio para "quién
// manda el mensaje" ni para "qué aplicación del teléfono es". Solo tiene
// app_name, summary y body, así que cada puente mete lo que puede donde puede.
//
// Un detalle de diseño, que es el que hace esto mantenible: las REGLAS son
// código (un caso por cada formato que conocemos) y las TABLAS son datos (qué
// glifo le toca a cada app). Las reglas son pocas y cambian cuando cambia un
// puente; las tablas crecen cada vez que instalas algo nuevo en el teléfono.

import QtQuick
import Quickshell

Singleton {
    id: root

    // ── quién es quién ────────────────────────────────────────────
    readonly property string bridge: "BlueFerry"

    // Los emojis NO se escriben literales a propósito. Dos razones: en el
    // origen son dos unidades UTF-16 y aquí solo hace falta el número, y es
    // justo el carácter que tu fuente no sabe pintar (la caja ◇ de la captura).
    readonly property int markApp: 0x1F4F1      // 📱 → notificación de una app
    readonly property int markChat: 0x1F4AC     // 💬 → mensaje

    // Lo que BlueFerry pone entre remitente y mensaje: " — " (raya, no guion).
    readonly property string joiner: " \u2014 "

    // Cuando no reconocemos la app: una campana.
    readonly property string fallbackGlyph: "\uf0f3"

    // ── la tabla ──────────────────────────────────────────────────
    //
    // Se recorre en orden y gana la primera que encaje, así que lo específico
    // va arriba. `match` se compara en minúsculas y por trozo, no completo:
    // "WhatsApp Business" encaja con "whatsapp".
    //
    // Aquí es donde vas añadiendo lo que use tu teléfono.
    readonly property var glyphs: [
        { match: "whatsapp",   glyph: "\uf232" },
        { match: "telegram",   glyph: "\uf2c6" },
        { match: "instagram",  glyph: "\uf16d" },
        { match: "messenger",  glyph: "\uf09a" },
        { match: "facebook",   glyph: "\uf09a" },
        { match: "twitter",    glyph: "\uf099" },
        { match: "slack",      glyph: "\uf198" },
        { match: "spotify",    glyph: "\uf1bc" },
        { match: "youtube",    glyph: "\uf167" },
        { match: "gmail",      glyph: "\uf0e0" },
        { match: "mail",       glyph: "\uf0e0" },
        { match: "correo",     glyph: "\uf0e0" },
        { match: "calendar",   glyph: "\uf073" },
        { match: "calendario", glyph: "\uf073" },
        { match: "wallet",     glyph: "\uf09d" },
        { match: "cartera",    glyph: "\uf09d" },
        { match: "phone",      glyph: "\uf095" },
        { match: "teléfono",   glyph: "\uf095" },
        { match: "mensaje",    glyph: "\uf075" },
        { match: "message",    glyph: "\uf075" },
        { match: "signal",     glyph: "\uf075" },
        { match: "discord",    glyph: "\uf075" },
        { match: "zen",        glyph: "\uf269" },
        { match: "firefox",    glyph: "\uf269" },
        { match: "chrom",      glyph: "\uf268" },
        { match: "code",       glyph: "\uf121" }
    ]

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
            glyph: root.fallbackGlyph,
            fromPhone: false,
            keep: false,
            source: null
        };
    }

    // ── utilidades ────────────────────────────────────────────────

    // Quita del principio los emojis, los selectores de variación y el espacio
    // que viene detrás, y deja el nombre limpio.
    //
    // No se busca el emoji concreto: se tira todo lo que esté por encima del
    // texto normal. Así sigue funcionando si BlueFerry cambia de icono, y un
    // nombre que empieza por "+" (un número de teléfono) se queda intacto.
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

    // El primer carácter como número, para saber de qué formato se trata.
    function mark(text) {
        const s = String(text || "");
        return s.length > 0 ? s.codePointAt(0) : 0;
    }

    // El camino inverso al `escape()` de BlueFerry. Solo hace falta en los
    // mensajes: el puente los escapa porque el campo `body` del estándar
    // acepta marcado, pero tu servidor anuncia `bodyMarkupSupported: false` y
    // los pinta como texto plano, así que un "&" te llegaría escrito "&amp;".
    //
    // NO se puede llamar `unescape`: eso es una función global de JavaScript
    // —como `escape` o `eval`— y QML no deja declarar un método que la tape.
    // Mismo choque que `transient`, pero del lado de JS.
    //
    // El `&amp;` va el ÚLTIMO. Si fuera el primero, un "&amp;lt;" acabaría
    // convertido en "<" en vez de en "&lt;".
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

    function glyphFor(appName) {
        const name = String(appName || "").toLowerCase();
        const table = root.glyphs;

        for (let i = 0; i < table.length; ++i) {
            if (name.indexOf(table[i].match) !== -1)
                return table[i].glyph;
        }

        return root.fallbackGlyph;
    }

    // Resuelve un nombre de icono del tema a una ruta, y devuelve "" si ese
    // icono NO EXISTE.
    //
    // Ese segundo argumento es el que mata el cuadriculado magenta: sin él,
    // `iconPath` devuelve una ruta igualmente, la Image falla al cargarla y Qt
    // pinta su marca de imagen rota.
    function iconFor(name) {
        if (!name)
            return "";

        return Quickshell.iconPath(String(name), true);
    }

    // Deja presentable un desktop-entry: "app.zen_browser.zen" → "Zen".
    function fromEntry(entry) {
        const parts = String(entry || "").split(".");
        const last = parts.length > 0 ? parts[parts.length - 1] : "";

        if (last.length === 0)
            return "";

        return last.charAt(0).toUpperCase() + last.slice(1);
    }

    // ── las reglas ────────────────────────────────────────────────
    //
    // El punto de entrada. Todo lo que pinta la island sale de aquí.
    function classify(n) {
        if (!n)
            return root.none();

        if (String(n.appName || "") === root.bridge)
            return root.fromBridge(n);

        return root.fromDesktop(n);
    }

    // Lo del iPhone. Dos formatos, y los distingue el primer carácter del
    // resumen.
    function fromBridge(n) {
        const summary = String(n.summary || "");
        const body = String(n.body || "");

        // ── SMS / iMessage: "💬 remitente" + mensaje ──
        if (root.mark(summary) === root.markChat) {
            return {
                kind: "phone-message",
                appName: "Mensajes",
                title: root.strip(summary),
                message: root.unescapeMarkup(body),
                image: String(n.image || ""),
                icon: "",
                glyph: "\uf075",
                fromPhone: true,
                keep: true,
                source: n
            };
        }

        // ── app del teléfono: "📱 App" + "remitente — mensaje" ──
        const app = root.strip(summary);
        const cut = body.indexOf(root.joiner);

        // Se busca la PRIMERA raya, no todas: si el mensaje lleva otra dentro,
        // se queda donde está. Y si no hay ninguna, es que la notificación no
        // traía título propio: entonces todo el cuerpo es el mensaje y no hay
        // remitente que poner.
        const title = cut > 0 ? body.slice(0, cut) : "";
        const message = cut > 0 ? body.slice(cut + root.joiner.length) : body;

        return {
            kind: "phone-app",
            appName: app.length > 0 ? app : "iPhone",
            title: title.trim(),
            message: message.trim(),
            image: String(n.image || ""),

            // Vacío a propósito: el icono que manda el puente es el mismo
            // teléfono genérico para todo, y el glifo de la app concreta dice
            // mucho más de un vistazo.
            icon: "",
            glyph: root.glyphFor(app),
            fromPhone: true,

            // BlueFerry las manda `transient`, que significa "no la guardes en
            // ningún historial". Aquí se decide lo contrario a propósito: ver
            // en el centro de control lo que pasó en el teléfono mientras no
            // mirabas es justo para lo que sirve. Ponlo a `false` si prefieres
            // respetar lo que pide el puente.
            keep: true,
            source: n
        };
    }

    // Todo lo demás: lo que corre en esta máquina.
    function fromDesktop(n) {
        const raw = String(n.appName || "");
        const entry = String(n.desktopEntry || "");
        const app = raw.length > 0 ? raw : root.fromEntry(entry);

        // Tres intentos para el icono, de lo más preciso a lo más genérico.
        // Zen manda `appIcon` vacío pero sí manda desktop-entry, y de ahí sale.
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
            glyph: root.glyphFor(app.length > 0 ? app : entry),
            fromPhone: false,

            // Aquí sí se respeta: una app de escritorio que pide no ser
            // guardada sabe lo que dice (un aviso de volumen, por ejemplo).
            keep: !n.transient,
            source: n
        };
    }
}