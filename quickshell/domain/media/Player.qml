pragma Singleton

// Las REGLAS de lo que suena. El repositorio da segundos y cadenas sueltas;
// aquí se decide qué cuenta como "hay música", cómo se escribe un tiempo y qué
// texto se enseña cuando falta el artista.
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
    readonly property string artUrl: MediaRepository.artUrl

    // "Título • Artista", y solo el título cuando no hay artista.
    readonly property string headline: root.artist.length > 0
        ? root.title + " • " + root.artist
        : root.title

    readonly property string playingOn: MediaRepository.identity.length > 0
        ? "Sonando en " + MediaRepository.identity
        : ""

    readonly property bool hasTimeline: MediaRepository.hasLength

    readonly property real progress: root.hasTimeline
        ? Math.max(0, Math.min(1, MediaRepository.position / MediaRepository.length))
        : 0

    readonly property string elapsed: root.formatTime(MediaRepository.position)

    readonly property string remaining: root.hasTimeline
        ? "-" + root.formatTime(MediaRepository.length - MediaRepository.position)
        : ""

    readonly property bool canGoNext: MediaRepository.canGoNext
    readonly property bool canGoPrevious: MediaRepository.canGoPrevious
    readonly property bool canControl: MediaRepository.canControl

    // Glifos de tu Nerd Font (rango Font Awesome).
    readonly property string playIcon: root.isPlaying ? "\uf04c" : "\uf04b"
    readonly property string previousIcon: "\uf048"
    readonly property string nextIcon: "\uf051"

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

    // Las llama la vista desplegada mientras está en pantalla.
    function watchPosition(): void {
        MediaRepository.watchPosition();
    }

    function unwatchPosition(): void {
        MediaRepository.unwatchPosition();
    }
}