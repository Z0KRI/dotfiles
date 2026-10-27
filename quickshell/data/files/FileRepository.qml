pragma Singleton

// pragma Singleton va en la PRIMERA línea a propósito: el escáner de
// Quickshell solo lo busca en la cabecera, y la cabecera termina en la
// primera línea que tenga una llave, aunque sea un comentario. El
// comentario de abajo tiene llaves.
//
// REPOSITORIO: los archivos de tu carpeta personal. Dos fuentes, las mismas
// que tenía el modo Archivos de rofi:
//
//   1. search(words)  plocate sobre su propia base de datos. Cubre todo el
//                     disco y responde en milisegundos porque no recorre
//                     nada: consulta un índice que systemd regenera una vez
//                     al día (plocate-updatedb.timer).
//   2. recent         los archivos recientes de GTK (recently-used.xbel), los
//                     mismos que salen en "Recientes" de Nautilus. Es la
//                     primera vista del modo Archivos, como en macOS.
//
// Las dos terminan en el mismo `find -files0-from`, que hace dos cosas de una
// vez: descarta lo que ya no existe (la base de plocate y la lista de
// recientes pueden ir un día atrasadas) y le pone a cada ruta su tipo, fecha y
// tamaño. Así el resto de la shell recibe siempre la misma forma:
//
//   { path: "/home/zokri/Documentos/informe.pdf", folder: false,
//     modified: 1761500000 (segundos), size: 482133 (bytes) }
//
// Qué se muestra, en qué orden y cuántos, lo decide domain/launcher/SearchFiles.


import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || (root.home + "/.local/share")

    // false si plocate no está instalado (la búsqueda salió con 127).
    property bool available: true

    // La última búsqueda que terminó, y con qué palabras se hizo.
    property var results: []
    property var resultsWords: []
    readonly property bool busy: searcher.running

    property var recent: []

    // ── buscar ───────────────────────────────────────────────────
    //
    // Si llega una búsqueda mientras otra corre, no se mata la que corre:
    // se anota y se lanza al terminar. Matarla dejaría su salida a medias en
    // el colector, y esa salida se confundiría con la de la búsqueda nueva.
    // plocate tarda milisegundos, así que esperar no se nota.
    function search(words, includeHidden, limit): void {
        const request = {
            words: words,
            hidden: includeHidden ? "1" : "0",
            limit: String(limit || 200)
        };

        if (searcher.running)
            searcher.pending = request;
        else
            searcher.start(request);
    }

    function clear(): void {
        searcher.pending = null;
        root.results = [];
        root.resultsWords = [];
    }

    // ── recientes ────────────────────────────────────────────────
    //
    // FileView lee el archivo en segundo plano, y este repositorio se crea la
    // primera vez que alguien lo usa (al abrir Spotlight). Esa primera vez
    // text() todavía está vacío. Por eso se recuerda que alguien pidió los
    // recientes, y se vuelven a armar en cuanto el archivo termina de cargar
    // (y cada vez que GTK lo reescribe).
    property int recentLimit: 0

    function refreshRecent(limit): void {
        root.recentLimit = limit || 40;
        root.statRecent();
    }

    function statRecent(): void {
        const paths = root.recentPaths(xbel.text(), root.recentLimit);
        if (paths.length === 0) {
            root.recent = [];
            return;
        }

        if (stat.running)
            stat.rerun = true;
        else
            stat.exec(["find"].concat(paths, ["-maxdepth", "0", "-printf", root.format]));
    }

    // ── internos ─────────────────────────────────────────────────

    // tipo, fecha, tamaño y ruta, separados por tabulador, uno por línea.
    //
    // Dentro del script las rutas viajan separadas por NUL (-0, -z), porque
    // un nombre de archivo puede tener cualquier cosa menos un byte cero.
    // Solo la salida final va por líneas: es texto para QML, y un NUL a mitad
    // de un texto es mala idea. Un nombre con un salto de línea adentro (casi
    // nadie los tiene) sale roto y parse() lo descarta.
    readonly property string format: "%y\\t%T@\\t%s\\t%p\\n"

    function parse(text) {
        return String(text || "").split("\n")
            .filter(record => /^[a-zA-Z]\t/.test(record))
            .map(record => {
                const [type, modified, size, ...rest] = record.split("\t");
                return {
                    path: rest.join("\t"),
                    folder: type === "d",
                    modified: Math.floor(Number(modified) || 0),
                    size: Number(size) || 0
                };
            })
            .filter(file => file.path !== "");
    }

    // Las rutas de recently-used.xbel, de la más nueva a la más vieja.
    // Es XML, pero solo hacen falta dos atributos de cada <bookmark>, y una
    // expresión regular es más simple que un lector de XML completo.
    function recentPaths(xml, limit) {
        const entries = [];
        const bookmark = /<bookmark\s([^>]*)>/g;
        let match;

        while ((match = bookmark.exec(xml)) !== null) {
            const href = /href="file:\/\/([^"]*)"/.exec(match[1]);
            if (!href)
                continue;

            const modified = /modified="([^"]*)"/.exec(match[1]);
            entries.push({
                path: root.decode(href[1]),
                modified: modified ? modified[1] : ""
            });
        }

        // Las fechas son ISO 8601: ordenarlas como texto las ordena en el tiempo.
        entries.sort((a, b) => b.modified.localeCompare(a.modified));

        const seen = {};
        return entries
            .map(entry => entry.path)
            .filter(path => path !== "" && !seen[path] && (seen[path] = true))
            .slice(0, limit);
    }

    // file:///home/zokri/Mis%20cosas/a%26b.txt → /home/zokri/Mis cosas/a&b.txt
    // Primero las entidades de XML (&amp;) y después los %20 de la URL.
    function decode(href) {
        const xml = href.replace(/&quot;/g, '"').replace(/&apos;/g, "'")
                        .replace(/&lt;/g, "<").replace(/&gt;/g, ">")
                        .replace(/&amp;/g, "&");
        try {
            return decodeURIComponent(xml);
        } catch (error) {
            return xml;
        }
    }

    Process {
        id: searcher

        property var current: null     // la búsqueda que está corriendo
        property var pending: null     // la que llegó mientras tanto

        function start(request): void {
            searcher.current = request;
            searcher.exec(["sh", "-c", root.searchScript, "sh",
                           request.hidden, request.limit].concat(request.words));
        }

        stdout: StdioCollector {
            id: found
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 127) {
                root.available = false;
                root.results = [];
            } else {
                root.available = true;
                root.results = root.parse(found.text);
            }
            root.resultsWords = searcher.current?.words ?? [];

            const next = searcher.pending;
            searcher.pending = null;
            if (next)
                searcher.start(next);
        }
    }

    // $1 ocultos (1/0), $2 límite, y luego las palabras.
    //
    // Varias palabras en plocate son un Y, no un O: "$HOME" informe 2025 trae
    // las rutas que contienen las tres cosas. Pasar "$HOME" como una palabra
    // más es lo que deja la búsqueda dentro de tu carpeta personal.
    //
    // El filtro de ocultos va ANTES del límite: si fuera después, una carpeta
    // como ~/.cache podría llenar las 200 plazas y no quedar nada visible.
    readonly property string searchScript: [
        'command -v plocate >/dev/null 2>&1 || exit 127',
        'hidden=$1; limit=$2; shift 2',
        'plocate -0 -i -- "$HOME" "$@" 2>/dev/null \\',
        '| if [ "$hidden" = 1 ]; then cat; else grep -zv -e "/\\." -e "/node_modules/" -e "/__pycache__/"; fi \\',
        '| head -z -n "$limit" \\',
        '| find -files0-from - -maxdepth 0 -printf "' + root.format + '" 2>/dev/null',
        'exit 0'
    ].join("\n")

    Process {
        id: stat

        property bool rerun: false

        stdout: StdioCollector {
            id: statted
        }

        // find termina con 1 si alguna ruta ya no existe; las demás sí salen.
        onExited: (exitCode, exitStatus) => {
            root.recent = root.parse(statted.text);

            if (stat.rerun) {
                stat.rerun = false;
                root.statRecent();
            }
        }
    }

    FileView {
        id: xbel

        path: root.dataHome + "/recently-used.xbel"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            if (root.recentLimit > 0)
                root.statRecent();
        }
    }

    // Una sola vez, para saber si plocate existe antes de la primera búsqueda
    // (así Ajustes y el modo Archivos pueden avisarte sin que escribas nada).
    Process {
        running: true
        command: ["sh", "-c", "command -v plocate >/dev/null 2>&1"]
        onExited: (exitCode, exitStatus) => root.available = exitCode === 0
    }
}
