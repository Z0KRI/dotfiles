pragma Singleton

// REPOSITORIO: las carátulas, guardadas en disco.
//
// El reproductor manda la carátula como una dirección de internet (Spotify:
// https://i.scdn.co/image/…). Si la isla la pide tal cual, Qt la baja cada vez
// que se abre: la vista desplegada se crea al abrir y se destruye al cerrar, y
// Qt solo guarda unos segundos una imagen que nadie está usando. Pasado eso,
// abrir la isla la volvía a bajar: un momento en gris y, si la red fallaba,
// gris hasta la siguiente canción. Esa era la carátula que "a veces no
// carga".
//
// Aquí se baja UNA vez con curl, que reintenta, a ~/.cache/dotfiles/covers, y
// la vista la lee de disco al instante. Una carátula ya bajada (la misma
// canción otra vez, o el mismo disco) ni siquiera se vuelve a pedir.
//
// Lo que no es http(s) ya está en tu computadora (un file:// de Firefox o de
// Chrome, un data:) y pasa tal cual.
//
// Qué se dibuja cuando no hay carátula no se decide aquí: es "" y ya
// (Player.kind y la vista se encargan).

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string dir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache"))
                                  + "/dotfiles/covers"

    // Lo que manda el reproductor, ya corregido.
    readonly property string remote: root.normalized(MediaRepository.artUrl)

    // Lo que se puede enseñar: un archivo que ya existe (o lo que ya era
    // local). Vacío mientras se baja, si falló o si no hay carátula.
    property string local: ""

    // Lo que ya se bajó en esta sesión: dirección → file://.
    property var known: ({})

    // La que hay que bajar cuando termine la que está en curso.
    property string pending: ""

    onRemoteChanged: root.resolve()
    Component.onCompleted: root.resolve()

    // Spotify, en algunas versiones, todavía manda sus carátulas con el
    // dominio viejo (open.spotify.com/image), que ya no las sirve. El mismo
    // id vive en i.scdn.co.
    function normalized(url): string {
        return String(url || "").replace(/^https?:\/\/open\.spotify\.com\/image\//,
                                         "https://i.scdn.co/image/");
    }

    function isRemote(url): bool {
        return /^https?:\/\//.test(url);
    }

    function resolve(): void {
        const url = root.remote;

        if (!root.isRemote(url)) {
            root.local = url;
            return;
        }

        if (root.known[url] !== undefined) {
            root.local = root.known[url];
            return;
        }

        // Nada que enseñar hasta que llegue: mejor el glifo que la carátula
        // de la canción anterior con el título de esta.
        root.local = "";
        root.fetch(url);
    }

    function fetch(url): void {
        if (download.running) {
            root.pending = url;
            return;
        }

        download.url = url;
        download.file = root.dir + "/" + Qt.md5(url);
        download.running = true;
    }

    Process {
        id: download

        property string url: ""
        property string file: ""

        // Si ya está en disco, se le actualiza la fecha (la limpieza borra
        // las que llevan un mes sin usarse) y listo. Si no, se baja a un
        // .part y se renombra al final: nunca queda un archivo a medias con
        // el nombre bueno.
        command: ["sh", "-c",
            'f="$1"\n'
            + '[ -s "$f" ] && { touch "$f"; exit 0; }\n'
            + 'mkdir -p "${f%/*}" || exit 1\n'
            + 'if curl -fsL --retry 2 --retry-delay 1 --connect-timeout 5 --max-time 20 -o "$f.part" "$2"; then\n'
            + '    mv -f "$f.part" "$f"\n'
            + 'else\n'
            + '    rm -f "$f.part"; exit 1\n'
            + 'fi',
            "sh", download.file, download.url]

        onExited: (exitCode, exitStatus) => {
            const ok = exitCode === 0;

            if (ok)
                root.known[download.url] = "file://" + download.file;

            // Si mientras tanto cambió de canción, esta ya no es la que se ve
            // (pero queda guardada para cuando vuelva).
            if (download.url === root.remote)
                root.local = ok ? root.known[download.url] : "";

            const next = root.pending;
            root.pending = "";
            if (next !== "" && next === root.remote && root.known[next] === undefined)
                root.fetch(next);
        }
    }

    // Al arrancar, fuera las que llevan más de 30 días sin usarse y los
    // .part que haya dejado un apagón. Solo los .part viejos: uno reciente
    // puede ser el de la canción que suena, que se está bajando ahora mismo.
    Process {
        running: true
        command: ["sh", "-c",
            '[ -d "$1" ] || exit 0\n'
            + 'find "$1" -type f \\( -mtime +30 -o \\( -name "*.part" -mmin +5 \\) \\) -delete',
            "sh", root.dir]
    }
}
