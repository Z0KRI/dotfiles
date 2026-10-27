// CASO DE USO: Spotlight completo. Junta las fuentes según el modo, las
// ordena en secciones y decide qué pasa al elegir un resultado.
//
// Tres funciones, tres momentos:
//
//   begin(mode)            al abrir o al cambiar de modo. Pide lo que se
//                          carga una vez: los recientes, el portapapeles.
//   prepare(query, mode)   en cada tecla. Lanza lo que es asíncrono (plocate).
//   results(query, mode)   la lista que se dibuja. No lanza nada: solo LEE
//                          lo que las fuentes tienen ahora.
//
// ¿Por qué separar prepare() de results()? Porque results() vive en un
// binding, y un binding se puede reevaluar cuantas veces Qt quiera (cuando
// llega lo de plocate, cuando abres una ventana…). Si lanzara procesos, cada
// reevaluación sería un plocate nuevo. prepare() es la única puerta con
// efectos, y se llama solo cuando el texto cambia.
//
// Qué sale en cada modo:
//   all        nada sin texto. Con texto: dirección o comando arriba, luego
//              Aplicaciones, Archivos y al final "Buscar en la web".
//   apps       todas las apps (las más usadas primero) o las que coinciden.
//   files      los recientes, o lo que encuentra plocate.
//   clipboard  el historial, completo o filtrado.

pragma Singleton

import Quickshell
import qs.data.system

Singleton {
    id: root

    readonly property int generalApps: 6
    readonly property int generalFiles: 5
    readonly property int filesLimit: 40
    readonly property int clipboardLimit: 200

    function begin(mode): void {
        if (mode === "files")
            SearchFiles.loadRecent();
        if (mode === "clipboard")
            SearchClipboard.refresh();
    }

    function prepare(query, mode): void {
        const wantsFiles = mode === "files" || (mode === "all" && SearchFiles.inGeneral);
        if (wantsFiles)
            SearchFiles.request(query);
    }

    function results(query, mode) {
        const text = String(query ?? "").trim();

        switch (mode) {
        case "apps":
            return root.apps(text, Infinity);
        case "files":
            return root.filesMode(text);
        case "clipboard":
            return root.clipboardMode(text);
        default:
            return root.general(text);
        }
    }

    // ── por modo ─────────────────────────────────────────────────

    function apps(text, limit) {
        return SearchApps.execute(text)
            .slice(0, limit)
            .map(entry => Results.app(entry, LaunchApp.windowFor(entry)));
    }

    function files(text, limit) {
        return SearchFiles.find(text, limit).map(Results.file);
    }

    function general(text) {
        if (text === "")
            return [];

        const out = [];

        // "> comando" y las direcciones van solas, arriba, sin encabezado:
        // si escribiste eso, es casi seguro lo que quieres con Enter.
        const command = /^>\s*(.+)$/.exec(text);
        if (command)
            out.push(Results.command(command[1]));
        else if (WebSearch.looksLikeUrl(text))
            out.push(Results.url(WebSearch.toUrl(text)));

        const apps = root.apps(text, root.generalApps);
        if (apps.length > 0)
            out.push(Results.header("Aplicaciones"), ...apps);

        if (SearchFiles.inGeneral && SearchFiles.available) {
            const files = root.files(text, root.generalFiles);
            if (files.length > 0)
                out.push(Results.header("Archivos"), ...files);
        }

        if (!command)
            out.push(Results.header("Web"),
                     Results.web(text, WebSearch.engine, WebSearch.searchUrl(text)));

        return out;
    }

    function filesMode(text) {
        if (!SearchFiles.available)
            return [Results.notice("plocate no está instalado",
                                   "Instálalo con ./install.sh para buscar en tus archivos.")];

        if (text === "") {
            const recent = SearchFiles.recent(root.filesLimit).map(Results.file);
            return recent.length > 0
                ? [Results.header("Recientes")].concat(recent)
                : [Results.notice("Sin archivos recientes", "Escribe para buscar en tu carpeta personal.")];
        }

        if (!SearchFiles.searchable(text))
            return [Results.notice("Sigue escribiendo", "Se busca desde " + SearchFiles.minLength + " letras.")];

        const found = root.files(text, root.filesLimit);
        if (found.length > 0)
            return found;

        // La primera búsqueda todavía no vuelve: decir "nada" sería mentir.
        if (SearchFiles.busy)
            return [Results.notice("Buscando…", "")];

        return [Results.notice("Ningún archivo coincide",
                               "plocate lee un índice que se actualiza una vez al día: "
                               + "lo que creaste hoy puede tardar en aparecer.")];
    }

    function clipboardMode(text) {
        if (!SearchClipboard.available)
            return [Results.notice("cliphist no está instalado", "Instálalo con ./install.sh.")];

        const found = SearchClipboard.find(text, root.clipboardLimit)
            .map(entry => Results.clip(entry, SearchClipboard.pastes));

        if (found.length > 0)
            return found;

        if (!SearchClipboard.loaded)
            return [];

        return [SearchClipboard.empty
            ? Results.notice("El portapapeles está vacío", "Lo que copies aparece aquí.")
            : Results.notice("Nada coincide", "")];
    }

    // ── elegir ───────────────────────────────────────────────────
    //
    // `alternate` es Ctrl + Enter:
    //   app        abre otra ventana aunque ya haya una
    //   archivo    lo muestra en su carpeta en vez de abrirlo
    //   portapap.  solo copia, no pega
    //
    // Devuelve true si Spotlight debe cerrarse.
    function activate(result, alternate) {
        if (!Results.selectable(result))
            return false;

        switch (result.kind) {
        case "app":
            LaunchApp.execute(result.target, alternate);
            break;
        case "folder":
            if (alternate)
                OpenerRepository.reveal(result.target.path);
            else
                OpenerRepository.openFolder(result.target.path);
            break;
        case "file":
            if (alternate)
                OpenerRepository.reveal(result.target.path);
            else
                OpenerRepository.openFile(result.target.path);
            break;
        case "clip":
        case "image":
            SearchClipboard.choose(result.target, alternate);
            break;
        case "url":
        case "web":
            WebSearch.open(result.target);
            break;
        case "command":
            OpenerRepository.run(result.target);
            break;
        }
        return true;
    }

    // Shift + Supr: hoy solo el portapapeles se puede borrar desde aquí.
    function remove(result) {
        if (result && (result.kind === "clip" || result.kind === "image")) {
            SearchClipboard.remove(result.target);
            return true;
        }
        return false;
    }
}
