pragma Singleton

// A qué símbolo se parece cada aplicación.
//
// Vive en el tema porque es apariencia, no lógica: cambiar el glifo de
// WhatsApp no cambia nada de cómo se interpreta una notificación. Y están aquí
// y no en una tabla de iconos del sistema porque son glifos de Nerd Font: no
// dependen del tema de iconos instalado, así que no fallan nunca. Eso es justo
// lo que se quiere de un respaldo.

import QtQuick
import Quickshell

Singleton {
    id: root

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

    // Por NOMBRE de aplicación. Se recorre en orden y gana la primera que
    // encaje, así que lo específico va arriba. La comparación es en minúsculas
    // y por trozo, no completa: "WhatsApp Business" encaja con "whatsapp".
    //
    // Aquí es donde vas añadiendo lo que uses.
    readonly property var byApp: [
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

    // El tipo primero, el nombre después, la campana al final.
    function glyph(appName, kind): string {
        const direct = root.byKind[String(kind || "")];

        if (direct)
            return direct;

        return root.forApp(appName);
    }

    function forApp(appName): string {
        const name = String(appName || "").toLowerCase();
        const table = root.byApp;

        for (let i = 0; i < table.length; ++i) {
            if (name.indexOf(table[i].match) !== -1)
                return table[i].glyph;
        }

        return root.fallback;
    }
}