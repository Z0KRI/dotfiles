pragma Singleton

// Las REGLAS de lo que suena. El repositorio da segundos y cadenas sueltas;
// aquí se decide qué cuenta como "hay música", cómo se escribe un tiempo,
// cómo se junta lo que hay del artista y el disco, y si lo que suena es
// música o un video.
//
// Los glifos no viven aquí: son apariencia (Theme.systemIcons.transport para
// los botones, Theme.systemIcons.cover[kind] para cuando no hay carátula).
//
// La UI se enlaza aquí y nunca a MPRIS.

import QtQuick
import Quickshell
import qs.data.media

Singleton {
    id: root

    // Un reproductor abierto sin pista no es música: es una ventana abierta.
    // Por eso la island no sale solo porque exista el proceso.
    readonly property bool hasTrack: MediaRepository.hasPlayer
                                     && MediaRepository.title.length > 0

    readonly property bool isPlaying: MediaRepository.isPlaying
    readonly property string title: MediaRepository.title
    readonly property string artist: MediaRepository.artist
    readonly property string album: MediaRepository.album

    // La carátula ya en disco (CoverRepository): se abre al instante cada vez
    // que se despliega la isla. Vacía si no hay, si todavía no llega o si no
    // se pudo bajar; entonces la vista dibuja el glifo de `kind`.
    readonly property string artUrl: CoverRepository.local

    // "music" o "video". Solo decide el dibujo de cuando no hay carátula: la
    // nota o la tele.
    readonly property string kind: root.classify(MediaRepository.url,
        MediaRepository.desktopEntry + " " + MediaRepository.source,
        MediaRepository.album)

    // "Bee Gees — Saturday Night Fever", como en macOS. Sin disco, solo el
    // artista; sin artista, solo el disco.
    readonly property string subtitle: [root.artist, root.album]
        .filter(part => part.length > 0)
        .join(" \u2014 ")

    // El programa que suena ("Google Chrome").
    readonly property string source: MediaRepository.source

    readonly property bool hasTimeline: MediaRepository.hasLength

    readonly property real progress: root.hasTimeline
        ? Math.max(0, Math.min(1, MediaRepository.position / MediaRepository.length))
        : 0

    readonly property string elapsed: root.formatTime(MediaRepository.position)

    // Lo que dura toda la pista ("4:58"), no lo que falta: como macOS.
    readonly property string duration: root.hasTimeline
        ? root.formatTime(MediaRepository.length)
        : ""

    readonly property bool canGoNext: MediaRepository.canGoNext
    readonly property bool canGoPrevious: MediaRepository.canGoPrevious
    readonly property bool canControl: MediaRepository.canControl

    // Se puede adelantar o regresar arrastrando la línea de tiempo. Sin
    // duración conocida no hay a dónde.
    readonly property bool canSeek: MediaRepository.canSeek && root.hasTimeline

    // ── ¿música o video? ─────────────────────────────────────────
    //
    // Se pregunta en orden, de la pista más segura a la más floja:
    //   1. La dirección es de un servicio de música (Spotify, YouTube Music…).
    //   2. La extensión del archivo (mpv o VLC abriendo un .mkv o un .flac).
    //   3. La dirección es de un sitio de video (YouTube, Twitch, Netflix…).
    //   4. El programa es de video (mpv, VLC, Celluloid…).
    //   5. Un navegador casi nunca da la dirección. Lo que lo delata es el
    //      disco: YouTube Music y Spotify web lo dan, un video de YouTube no.
    //   6. Si nada lo dice, música.
    readonly property var musicSites: ["open.spotify.com", "music.youtube.com", "music.apple.com",
                                       "soundcloud.com", "bandcamp.com", "deezer.com", "tidal.com"]
    readonly property var videoSites: ["youtube.com", "youtu.be", "twitch.tv", "vimeo.com",
                                       "netflix.com", "primevideo.com", "disneyplus.com",
                                       "max.com", "crunchyroll.com", "tiktok.com"]
    readonly property var musicFiles: ["mp3", "flac", "ogg", "oga", "opus", "m4a", "aac",
                                       "wav", "wma", "aiff", "alac"]
    readonly property var videoFiles: ["mp4", "mkv", "webm", "avi", "mov", "m4v", "wmv",
                                       "flv", "mpg", "mpeg", "ts"]
    readonly property var videoApps: ["mpv", "vlc", "celluloid", "totem", "showtime", "haruna",
                                      "smplayer", "kodi", "jellyfin", "plex", "stremio", "freetube"]
    readonly property var browsers: ["chrom", "firefox", "brave", "vivaldi", "edge", "zen",
                                     "librewolf", "floorp", "waterfox", "opera", "epiphany"]

    function classify(url, app, album): string {
        const address = String(url || "").toLowerCase();
        const program = String(app || "").toLowerCase();
        const has = (list, text) => list.some(item => text.includes(item));

        if (has(root.musicSites, address))
            return "music";

        // La extensión, sin "?tiempo=…" ni "#…".
        const ext = (address.split(/[?#]/)[0].match(/\.([a-z0-9]{2,4})$/) || [])[1] ?? "";
        if (root.musicFiles.includes(ext))
            return "music";
        if (root.videoFiles.includes(ext))
            return "video";

        if (has(root.videoSites, address) || has(root.videoApps, program))
            return "video";

        if (has(root.browsers, program))
            return String(album || "").length > 0 ? "music" : "video";

        return "music";
    }

    function formatTime(seconds): string {
        const total = Math.max(0, Math.floor(seconds));
        const minutes = Math.floor(total / 60);
        const rest = total % 60;
        return minutes + ":" + (rest < 10 ? "0" + rest : rest);
    }

    function next(): void {
        MediaRepository.next();
    }

    function previous(): void {
        MediaRepository.previous();
    }

    function togglePlaying(): void {
        MediaRepository.togglePlaying();
    }

    // `fraction` de 0 a 1: el punto de la línea de tiempo donde soltaste.
    function seekTo(fraction): void {
        if (root.canSeek)
            MediaRepository.seek(Math.max(0, Math.min(1, fraction)) * MediaRepository.length);
    }

    // Las llama la vista desplegada mientras está en pantalla.
    function watchPosition(): void {
        MediaRepository.watchPosition();
    }

    function unwatchPosition(): void {
        MediaRepository.unwatchPosition();
    }
}