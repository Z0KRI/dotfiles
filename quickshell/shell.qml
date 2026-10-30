//@ pragma DropExpensiveFonts

// Pragmas (van antes de cualquier import):
//   DropExpensiveFonts  fontconfig ignora las fuentes .woff/.woff2, que se
//                       descomprimen en memoria. Tus fuentes son .ttf.
//   UseQApplication     NO está a propósito: solo lo necesitan los menús
//                       nativos de la bandeja. La bandeja sí se usa (para
//                       LibrePods), pero su menú se lee desde QML, sin abrirlo.
//                       Sin él Quickshell usa QGuiApplication y no levanta la
//                       parte de widgets.

// La raíz de tu shell. Cada feature vive en modules/ y se declara aquí una
// sola vez. Las que se manejan desde Hyprland abren su puerta por IPC:
//   qs ipc call launcher open|close|toggle
//   qs ipc call settings open|close|toggle|go <sección>
//   qs ipc call capture  region|screen|color
//   qs ipc call brightness up|down
//   qs ipc call media    playPause|next|previous

import QtQuick
import Quickshell
import qs.modules.bar
import qs.modules.launcher
import qs.modules.island
import qs.modules.settings
import qs.modules.capture
import qs.modules.keys

ShellRoot {
    Bar {}
    Island {}
    Launcher {}
    Settings {}
    Capture {}
    MediaKeys {}
}
