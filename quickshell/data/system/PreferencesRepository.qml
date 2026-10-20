// REPOSITORIO: preferencias del Centro de control que sobreviven a
// reinicios: modo oscuro, brillo y No molestar. Se guardan en JSON,
// igual que el historial del launcher.

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias dark: adapter.dark
    property alias brightness: adapter.brightness
    property alias doNotDisturb: adapter.doNotDisturb

    FileView {
        path: Quickshell.statePath("preferences.json")
        watchChanges: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        // La primera vez el archivo no existe: se crea con los valores por defecto.
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter

            property bool dark: false
            property real brightness: 1.0
            property bool doNotDisturb: false
        }
    }
}