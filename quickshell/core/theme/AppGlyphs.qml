pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string defaultFamily: Theme.font.mono

    // Cuando no reconocemos nada: una campana.
    readonly property string fallback: "\uf0f3"

    // Por TIPO de notificación, y gana sobre la tabla de abajo: una llamada es
    // un teléfono aunque la haya lanzado WhatsApp.
    readonly property var byKind: ({
        "call": "\uf095",
        "missed-call": "\uf095",
        "phone-message": "\uf075",
        "phone-battery": "\uf243"
    })

    readonly property var byApp: [
        { match: "warp", glyph: "\ue20a", family: Theme.font.icon },
        { match: "x",   glyph: "\ue8c9" },
        { match: "spotify", glyph: "\uf1bc" },
        { match: "health",   glyph: "\uf004" },
        { match: "reddit",   glyph: "\uf281" },
        { match: "google",   glyph: "\ue7f0" },
        { match: "whatsapp",   glyph: "\uf232" },
        { match: "telegram",   glyph: "\uf2c6" },
        { match: "instagram",  glyph: "\uf16d" },
        { match: "messenger",  glyph: "\uf25f" },
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
        { match: "discord",   glyph: "\uf1ff" },
        { match: "zen",        glyph: "\ue745" },
        { match: "firefox",    glyph: "\uf269" },
        { match: "chrom",      glyph: "\uf268" },
        { match: "code",       glyph: "\uf121" }
    ]

    // El tipo primero, el nombre después, la campana al final.
    function glyph(appName, kind): string {
        const direct = root.byKind[String(kind || "")];

        if (direct)
            return direct;

        return root.forApp(appName);
    }


    function family(appName, kind): string {
        if (root.byKind[String(kind || "")])
            return root.defaultFamily;

        return root.familyForApp(appName);
    }

    // La primera que encaje con el nombre, o null.
    function entryFor(appName) {
        const name = String(appName || "").toLowerCase();
        return root.byApp.find(entry => name.indexOf(entry.match) !== -1) ?? null;
    }

    function forApp(appName): string {
        return root.entryFor(appName)?.glyph ?? root.fallback;
    }

    function familyForApp(appName): string {
        return root.entryFor(appName)?.family ?? root.defaultFamily;
    }
}