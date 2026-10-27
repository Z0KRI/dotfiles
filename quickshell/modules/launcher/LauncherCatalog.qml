pragma Singleton

// El catálogo de Spotlight: todo lo que es pura VISTA y por eso no vive en
// domain. Los chips de modo con su glifo y su texto, el glifo de respaldo de
// cada tipo de resultado, cómo se lee cada acción ("Abrir", "Pegar") y cómo
// se escribe una fecha.
//
// domain/launcher/Results entrega el modelo (qué es cada resultado). decorate()
// le agrega lo que solo importa para dibujarlo. Es el mismo reparto que en
// S.I.R.A tienen tus mappers de tabla (asset-table.mapper.ts): el modelo de
// dominio no sabe de columnas ni de íconos.

import QtQuick
import Quickshell
import qs.core.theme

Singleton {
    id: root

    // Los chips, en el orden de sus atajos (Super + 1, 2, 3).
    readonly property var modes: [
        { value: "apps", glyph: Theme.systemIcons.launcher.apps, label: "Aplicaciones",
          placeholder: "Buscar aplicaciones" },
        { value: "files", glyph: Theme.systemIcons.launcher.files, label: "Archivos",
          placeholder: "Buscar archivos" },
        { value: "clipboard", glyph: Theme.systemIcons.launcher.clipboard, label: "Portapapeles",
          placeholder: "Buscar en el portapapeles" }
    ]

    function find(mode) {
        return root.modes.find(m => m.value === mode) ?? null;
    }

    function placeholderFor(mode) {
        return root.find(mode)?.placeholder ?? "Buscar en Spotlight";
    }

    // El modo del atajo con número (Super + 1 → Aplicaciones), o "".
    function modeForNumber(number) {
        return root.modes[number - 1]?.value ?? "";
    }

    readonly property var glyphs: ({
        app: Theme.systemIcons.launcher.apps,
        file: Theme.systemIcons.launcher.file,
        folder: Theme.systemIcons.launcher.files,
        clip: Theme.systemIcons.launcher.text,
        image: Theme.systemIcons.launcher.image,
        url: Theme.systemIcons.launcher.link,
        web: Theme.systemIcons.launcher.web,
        command: Theme.systemIcons.launcher.command
    })

    readonly property var hints: ({
        open: "Abrir",
        "switch": "Ir a la ventana",
        paste: "Pegar",
        copy: "Copiar",
        search: "Buscar",
        run: "Ejecutar"
    })

    // Resultado del dominio → fila lista para dibujar.
    function decorate(result) {
        if (result.kind === "header" || result.kind === "notice")
            return result;

        const hint = root.hints[result.action];
        return Object.assign({}, result, {
            glyph: root.glyphs[result.kind] ?? Theme.systemIcons.squirrel,
            hint: hint ? hint + "  ↵" : "",
            detail: result.modified > 0 ? root.formatDate(result.modified) : ""
        });
    }

    readonly property var months: ["ene", "feb", "mar", "abr", "may", "jun",
                                   "jul", "ago", "sep", "oct", "nov", "dic"]

    // Como Finder: "Hoy, 14:05", "Ayer, 09:12", "12 oct", "3 mar 2024".
    function formatDate(seconds) {
        const date = new Date(seconds * 1000);
        const now = new Date();

        const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
        const day = 24 * 60 * 60 * 1000;
        const time = String(date.getHours()).padStart(2, "0") + ":" + String(date.getMinutes()).padStart(2, "0");

        if (date.getTime() >= startOfToday)
            return "Hoy, " + time;
        if (date.getTime() >= startOfToday - day)
            return "Ayer, " + time;

        const label = date.getDate() + " " + root.months[date.getMonth()];
        return date.getFullYear() === now.getFullYear() ? label : label + " " + date.getFullYear();
    }
}
