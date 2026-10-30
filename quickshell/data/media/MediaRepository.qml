pragma Singleton

// El único que habla con MPRIS.
//
// Lo que no es obvio: `position` NO se actualiza sola. La documentación lo dice
// sin rodeos — leerla siempre devuelve el valor correcto, pero no avisa de que
// cambió, así que un binding se queda congelado. Hay que pedirle al reproductor
// que reemita su señal, y eso solo tiene sentido mientras alguien la mire: de
// ahí el contador de mirones.

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    // El que suena; si ninguno suena, el primero que haya.
    readonly property var player: {
        const players = Mpris.players ? Mpris.players.values : []
        for (let i = 0; i < players.length; ++i) {
            if (players[i].isPlaying)
                return players[i]
        }
        return players.length > 0 ? players[0] : null
    }

    readonly property bool hasPlayer: root.player !== null
    readonly property bool isPlaying: root.hasPlayer && root.player.isPlaying

    readonly property string title: root.hasPlayer ? root.player.trackTitle : ""
    readonly property string artist: root.hasPlayer ? root.player.trackArtist : ""
    readonly property string album: root.hasPlayer ? root.player.trackAlbum : ""
    readonly property string artUrl: root.hasPlayer ? root.player.trackArtUrl : ""

    // Qué programa suena ("Google Chrome", "Spotify"): el nombre con que el
    // reproductor se presenta por MPRIS, y el de su .desktop ("spotify",
    // "mpv"), que no cambia con el idioma.
    readonly property string source: root.hasPlayer ? root.player.identity : ""
    readonly property string desktopEntry: root.hasPlayer ? root.player.desktopEntry : ""

    // La dirección de lo que suena (xesam:url): el archivo en mpv, la canción
    // en Spotify. Los navegadores casi nunca la dan.
    readonly property string url: root.hasPlayer
        ? String(root.player.metadata["xesam:url"] ?? "")
        : ""

    readonly property bool hasLength: root.hasPlayer
                                      && root.player.lengthSupported
                                      && root.player.length > 0

    readonly property real length: root.hasLength ? root.player.length : 0

    readonly property real position: root.hasPlayer && root.player.positionSupported
        ? root.player.position
        : 0

    readonly property bool canGoNext: root.hasPlayer && root.player.canGoNext
    readonly property bool canGoPrevious: root.hasPlayer && root.player.canGoPrevious
    readonly property bool canControl: root.hasPlayer && root.player.canControl
    readonly property bool canSeek: root.hasPlayer && root.player.canSeek

    // Cuántos están mirando la línea de tiempo.
    property int positionWatchers: 0

    function watchPosition(): void {
        root.positionWatchers++;
    }

    function unwatchPosition(): void {
        root.positionWatchers = Math.max(0, root.positionWatchers - 1);
    }

    function next(): void {
        if (root.canGoNext)
            root.player.next();
    }

    function previous(): void {
        if (root.canGoPrevious)
            root.player.previous();
    }

    function togglePlaying(): void {
        if (root.hasPlayer && root.player.canControl)
            root.player.togglePlaying();
    }

    // Saltar a ese segundo de la pista. `position` se puede escribir: MPRIS
    // lo convierte en su SetPosition.
    function seek(seconds): void {
        if (root.canSeek)
            root.player.position = Math.max(0, Math.min(root.length, seconds));
    }

    // Empujar a `position` a que se entere de que el tiempo pasa.
    Timer {
        interval: 1000
        repeat: true
        running: root.isPlaying && root.positionWatchers > 0
        onTriggered: root.player.positionChanged()
    }
}