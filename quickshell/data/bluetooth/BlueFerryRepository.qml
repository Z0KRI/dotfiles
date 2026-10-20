// REPOSITORIO: el servicio de BlueFerry (puente con el iPhone).
// Lo administra systemd (blueferry.service, de usuario): aquí solo se
// pregunta si corre, se arranca o se detiene, y se abre su ventana.

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string unit: "blueferry.service"

    property bool running: false

    // Cuántos están mirando el estado (el Centro de control abierto).
    property int watchers: 0

    function watch(): void {
        root.watchers++;
        root.refresh();
    }

    function unwatch(): void {
        root.watchers = Math.max(0, root.watchers - 1);
    }

    function refresh(): void {
        if (!probe.running)
            probe.running = true;
    }

    function setRunning(on): void {
        Quickshell.execDetached(["systemctl", "--user", on ? "start" : "stop", root.unit]);

        // Respuesta inmediata; la consulta real lo confirma después.
        root.running = on;
        confirm.restart();
    }

    function openApp(): void {
        Quickshell.execDetached(["blueferry-quickshell"]);
    }

    // "is-active --quiet" no imprime nada: sale con 0 si el servicio corre.
    Process {
        id: probe
        command: ["systemctl", "--user", "is-active", "--quiet", root.unit]
        onExited: (exitCode, exitStatus) => {
            root.running = exitCode === 0;
        }
    }

    // Tras arrancar o detener, confirmar con el estado real.
    Timer {
        id: confirm
        interval: 1500
        onTriggered: root.refresh()
    }

    // Mientras alguien mira, revisar de vez en cuando.
    Timer {
        interval: 5000
        repeat: true
        running: root.watchers > 0
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}