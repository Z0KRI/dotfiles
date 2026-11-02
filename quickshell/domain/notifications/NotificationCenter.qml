// CASO DE USO: el panel de notificaciones (el Centro de notificaciones).
// Reglas:
//   - Hay uno solo, en la pantalla donde lo abriste. Abrirlo en otra lo
//     cierra en la primera, como en macOS.
//   - Es una barra lateral, no un menú: las ventanas se apartan para dejarle
//     sitio (lo resuelve el módulo con la zona reservada) y no se cierra con
//     un clic afuera, solo con su botón (o por IPC).
//   - El punto azul del botón: llegó algo nuevo desde la última vez que
//     abriste el panel. Lo que se reemite al recargar `qs` no cuenta: esas ya
//     las habías visto.
//
// Qué se muestra en él lo decide Notifications (el historial).
//
// Por IPC (ver modules/bar/Bar.qml):
//   qs ipc call notifications toggle|open|close

pragma Singleton

import QtQuick
import Quickshell
import qs.data.hyprland

Singleton {
    id: root

    // Nombre de la pantalla donde está abierto; "" si está cerrado.
    property string screenName: ""

    readonly property bool open: root.screenName !== ""

    // ¿Está abierto en el monitor enfocado? Lo usan los cajones que se abren
    // ahí (el portapapeles se corre para no quedar debajo del panel).
    readonly property bool openOnFocused: root.open
        && root.screenName === HyprlandRepository.focusedMonitorName

    // Lo de antes de esto ya lo viste. Empieza al arrancar la shell.
    property real seenAt: Date.now()

    // Algo llegó después de la última vez que miraste. Con el panel abierto
    // no hay nada pendiente: lo estás viendo.
    readonly property bool unread: !root.open && Notifications.history.some(
        entry => (entry.arrived || 0) > root.seenAt)

    function isOpenOn(name): bool {
        return root.open && root.screenName === String(name || "");
    }

    function openOn(name): void {
        root.screenName = String(name || "");
        root.seenAt = Date.now();
    }

    function close(): void {
        if (!root.open)
            return;

        // Lo que llegó mientras estaba abierto también se vio.
        root.seenAt = Date.now();
        root.screenName = "";
    }

    function toggle(name): void {
        if (root.isOpenOn(name))
            root.close();
        else
            root.openOn(name);
    }

    // Desde el teclado (IPC): en el monitor enfocado.
    function toggleHere(): void {
        root.toggle(HyprlandRepository.focusedMonitorName);
    }

    function openHere(): void {
        root.openOn(HyprlandRepository.focusedMonitorName);
    }
}
