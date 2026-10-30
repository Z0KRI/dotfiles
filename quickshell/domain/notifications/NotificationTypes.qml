pragma Singleton

// TIPAR: convertir lo que llega por el bus —tres cadenas de texto libre— en un
// objeto con campos fijos que la vista pueda pintar sin preguntar de dónde vino.
//
// BlueFerry manda sus formatos por el mismo canal y los distingue un emoji al
// principio del resumen (src/blueferry/sinks/libnotify.py):
//
//   📱  app del teléfono (ANCS)  summary="📱 App · título"    body="subtítulo\nmensaje"
//                                (antes de la 0.8: "📱 App" y "remitente — mensaje")
//   💬  mensaje (MAP)            summary="💬 quien"           body="texto"
//   📞  llamada sonando          summary="📞 Incoming call"   body="nombre\nnúmero"
//                                acciones answer / decline (con ./install.sh --calls)
//   📞  llamada perdida          summary="📞 quien"           body="Missed call · hora"
//                                sin acciones
//   🔋  batería baja             summary="🔋 ..."             body="texto"
//
// Una llamada también puede llegar como notificación de la app Teléfono (o
// WhatsApp, FaceTime…) por ANCS. Si BlueFerry trae sus botones del iPhone
// ("blueferry notification-actions enable"), Aceptar y Rechazar llegan como
// las acciones ancs-positive y ancs-negative, y se trata como llamada.
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
    // Desde la 0.8 el título va en el resumen, junto a la app: " · ".
    readonly property string joiner: " \u2014 "
    readonly property string titleJoiner: " \u00b7 "

    // Apps del iPhone cuyas notificaciones con Aceptar/Rechazar son llamadas.
    // Por trozo y en minúsculas, como en AppGlyphs.
    readonly property var callApps: ["phone", "teléfono", "telefono", "facetime", "whatsapp",
                                     "telegram", "signal", "messenger", "teams", "zoom",
                                     "skype", "discord"]
    readonly property var callWords: /incoming|entrante|calling|llamando|videollamada|llamada de voz|voice call|video call/i

    // Una llamada perdida también puede traer botones ("Devolver llamada",
    // "Borrar"): esa NO es una llamada sonando, y Contestar marcaría.
    readonly property var missedWords: /missed|perdida|no contestada|sin contestar/i

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
            glyphFamily: AppGlyphs.defaultFamily,
            fromPhone: false,
            replyable: false,
            holds: false,
            keep: false,
            answerAction: "",
            declineAction: "",
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

    // ¿la notificación trae esta acción? (por su identificador)
    function hasAction(n, id) {
        const list = n && n.actions ? n.actions : [];
        for (let i = 0; i < list.length; ++i) {
            if (list[i] && list[i].identifier === id)
                return true;
        }
        return false;
    }

    function isCallApp(app) {
        const name = String(app || "").toLowerCase();
        return root.callApps.some(match => name.indexOf(match) >= 0);
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

        // ── llamada perdida ──
        //
        // Mismo emoji que la que suena, pero sin botones: "📞 quien" (o
        // "📞 3 missed calls") y la hora. No retiene la isla.
        if (kind === root.markCall && !root.hasAction(n, "answer")) {
            return {
                kind: "missed-call",
                appName: "Llamadas",
                title: root.unescapeMarkup(root.strip(summary)),
                message: root.unescapeMarkup(body),
                image: "",
                icon: "",
                glyph: AppGlyphs.glyph("", "missed-call"),
                glyphFamily: AppGlyphs.family("", "missed-call"),
                fromPhone: true,
                replyable: false,
                holds: false,
                keep: true,
                answerAction: "",
                declineAction: "",
                source: n
            };
        }

        // ── llamada entrante (con ./install.sh --calls: el audio, en la PC) ──
        //
        // El cuerpo trae nombre y número en dos líneas. Si el contacto no
        // tiene nombre, viene una sola.
        if (kind === root.markCall) {
            const lines = root.unescapeMarkup(body).split("\n");
            const heading = root.unescapeMarkup(root.strip(summary));

            return {
                kind: "call",
                // BlueFerry escribe "Incoming call" o "Call waiting".
                appName: /waiting/i.test(heading) ? "Llamada en espera"
                         : /incoming/i.test(heading) ? "Llamada" : heading,
                title: (lines[0] || "").trim(),
                message: lines.length > 1 ? (lines[1] || "").trim() : "",
                image: String(n.image || ""),
                icon: "",
                glyph: AppGlyphs.glyph("", "call"),
                glyphFamily: AppGlyphs.family("", "call"),
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
                answerAction: "answer",
                declineAction: "decline",
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
                glyphFamily: AppGlyphs.family("", "phone-message"),
                fromPhone: true,

                // Lo único a lo que se puede contestar desde aquí: BlueFerry
                // sabe mandar SMS e iMessage, no un WhatsApp.
                replyable: true,
                holds: false,
                keep: true,
                answerAction: "",
                declineAction: "",
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
                glyphFamily: AppGlyphs.family("", "phone-battery"),
                fromPhone: true,
                replyable: false,
                holds: false,
                keep: true,
                answerAction: "",
                declineAction: "",
                source: n
            };
        }

        // ── app del teléfono (ANCS) ──
        //
        // Desde BlueFerry 0.8: "📱 App · título" y en el cuerpo subtítulo y
        // mensaje, en líneas. Antes: "📱 App" y "remitente — mensaje". Las dos
        // vienen escapadas como HTML.
        const head = root.unescapeMarkup(root.strip(summary));
        const text = root.unescapeMarkup(body);
        const dot = head.indexOf(root.titleJoiner);

        let app = head;
        let title = "";
        let message = text;

        if (dot > 0) {
            app = head.slice(0, dot);
            title = head.slice(dot + root.titleJoiner.length);
        } else {
            // La PRIMERA raya, no todas: si el mensaje lleva otra dentro, se
            // queda donde está. Sin ninguna, todo el cuerpo es el mensaje.
            const cut = text.indexOf(root.joiner);
            if (cut > 0) {
                title = text.slice(0, cut);
                message = text.slice(cut + root.joiner.length);
            }
        }

        app = app.trim();
        title = title.trim();
        message = message.trim();

        // ── …que es una llamada sonando ──
        //
        // Con los botones del iPhone encendidos, una llamada trae Aceptar y
        // Rechazar. Una invitación del calendario también, por eso además
        // tiene que ser de una app de llamadas o decir que es una llamada; y
        // no puede ser una perdida.
        const ringing = root.hasAction(n, "ancs-positive")
                        && root.hasAction(n, "ancs-negative")
                        && !root.missedWords.test(title + " " + message)
                        && (root.isCallApp(app) || root.callWords.test(message));

        if (ringing) {
            return {
                kind: "call",
                appName: app.length > 0 ? app : "iPhone",
                title: title.length > 0 ? title : message,
                // "mobile\nIncoming Call" → "mobile · Incoming Call"
                message: title.length > 0 ? message.split("\n").join(root.titleJoiner) : "",
                image: String(n.image || ""),
                icon: "",
                glyph: AppGlyphs.glyph("", "call"),
                glyphFamily: AppGlyphs.family("", "call"),
                fromPhone: true,
                replyable: false,

                // Igual que la de --calls: se queda mientras suena. Cuando deja
                // de sonar, el iPhone retira su notificación y BlueFerry cierra
                // la de aquí.
                holds: true,
                keep: false,

                // Contestar y rechazar son las acciones del iPhone: se
                // contesta EN el iPhone (hablas por él o por tus AirPods).
                answerAction: "ancs-positive",
                declineAction: "ancs-negative",
                source: n
            };
        }

        // ── …o que suena sin botones ──
        //
        // El iPhone avisa de la llamada pero no manda Aceptar/Rechazar: pasa
        // con las llamadas normales (app Teléfono), y con todas si los botones
        // del iPhone están apagados. Se enseña como llamada para que no se
        // pierda entre las demás, pero sin Contestar (`answerAction` vacío).
        // Con ./install.sh --calls listo, la de BlueFerry (📞, que sí se
        // contesta, en la PC) llega a la par y la reemplaza: Notifications.
        const ringingOnly = root.isCallApp(app)
                            && root.callWords.test(title + " " + message)
                            && !root.missedWords.test(title + " " + message);

        if (ringingOnly) {
            const lines = message.split("\n");

            return {
                kind: "call",
                appName: app.length > 0 ? app : "iPhone",
                title: title.length > 0 ? title : message,

                // El iPhone pone la etiqueta del número ("mobile") en la
                // primera línea. Sirve para nombrar la llamada de BlueFerry.
                callerLabel: lines.length > 1 ? lines[0].trim() : "",
                message: title.length > 0 ? message.split("\n").join(root.titleJoiner) : "",
                image: String(n.image || ""),
                icon: "",
                glyph: AppGlyphs.glyph("", "call"),
                glyphFamily: AppGlyphs.family("", "call"),
                fromPhone: true,
                replyable: false,

                // Se queda mientras suena: cuando deja de sonar, el iPhone
                // retira su notificación y BlueFerry cierra la de aquí.
                holds: true,
                keep: false,
                answerAction: "",
                declineAction: "",
                source: n
            };
        }

        return {
            kind: "phone-app",
            appName: app.length > 0 ? app : "iPhone",
            title: title,
            message: message,
            image: String(n.image || ""),

            // Vacío a propósito: el icono del puente es el mismo teléfono
            // genérico para todo, y el glifo de la app dice mucho más.
            icon: "",
            glyph: AppGlyphs.glyph(app, "phone-app"),
            glyphFamily: AppGlyphs.family(app, "phone-app"),
            fromPhone: true,
            replyable: false,
            holds: false,

            // BlueFerry las manda `transient` ("no la guardes"). Aquí se decide
            // lo contrario: ver en el centro de control lo que pasó en el
            // teléfono mientras no mirabas es justo para lo que sirve. Ponlo a
            // `false` si prefieres respetar lo que pide el puente.
            keep: true,
            answerAction: "",
            declineAction: "",
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
            glyphFamily: AppGlyphs.family(app.length > 0 ? app : entry, "desktop"),
            fromPhone: false,
            replyable: false,
            holds: false,

            // Aquí sí se respeta: una app que pide no ser guardada sabe lo que
            // dice (un aviso de volumen, por ejemplo).
            keep: !n.transient,
            answerAction: "",
            declineAction: "",
            source: n
        };
    }
}