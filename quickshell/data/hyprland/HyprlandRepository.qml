pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property var lastActiveByWorkspace: ({})

    // El monitor enfocado (el que tiene el ratón con follow_mouse).
    readonly property string focusedMonitorName: Hyprland.focusedMonitor?.name ?? ""

    // `hasFullscreen` es propiedad del workspace en Quickshell 0.3, y
    // Quickshell la relee solo cuando Hyprland emite `fullscreen`: no hace
    // falta escuchar eventos a mano.
    readonly property bool focusedHasFullscreen:
        Hyprland.focusedMonitor?.activeWorkspace?.hasFullscreen ?? false

    function monitorFor(screen) {
        if (!screen)
            return null;

        return Hyprland.monitors.values.find(m => m.name === screen.name) ?? null;
    }

    function activeWorkspaceId(screen) {
        return root.monitorFor(screen)?.activeWorkspace?.id ?? -1;
    }

    function hasFullscreen(screen) {
        return root.monitorFor(screen)?.activeWorkspace?.hasFullscreen ?? false;
    }

    function activeAppIdFor(screen) {
        const toplevel = root.activeWindowFor(screen);

        return toplevel?.wayland?.appId ?? toplevel?.lastIpcObject?.class ?? "";
    }

    function activeWindowFor(screen) {
        const workspace = root.monitorFor(screen)?.activeWorkspace;
        if (!workspace)
            return null;

        const windows = workspace.toplevels.values;
        if (windows.length === 0)
            return null;

        const focused = windows.find(w => w.activated);
        if (focused)
            return focused;

        const lastAddress = root.lastActiveByWorkspace[workspace.id];
        return windows.find(w => w.address === lastAddress) ?? windows[0];
    }

    // Todas las ventanas abiertas, en cualquier escritorio.
    readonly property var toplevels: Hyprland.toplevels.values

    // La clase (app id) de una ventana, la misma que ves en `hyprctl clients`.
    //
    // Siempre devuelve texto. La versión con `a ?? b ?? ""` dejó llegar
    // undefined a activeAppId en una recarga (Qt avisó "Unable to assign
    // [undefined] to QString"). Con comprobaciones explícitas y String() no
    // hay camino que no termine en un texto, venga como venga la ventana.
    function appIdOf(toplevel): string {
        if (!toplevel)
            return "";

        const id = toplevel.wayland?.appId || toplevel.lastIpcObject?.class;
        return id ? String(id) : "";
    }

    // La ventana que tiene el foco ahora. Una capa como Spotlight NO cuenta
    // como ventana: mientras está abierta, la activa sigue siendo la de abajo.
    readonly property string activeAppId: root.appIdOf(Hyprland.activeToplevel)

    // Enfoca una ventana, y su escritorio si está en otro.
    //
    // Primero por el protocolo de Wayland (foreign toplevel): no depende de
    // cómo se escriban los dispatchers. Pero Quickshell enlaza ese objeto un
    // instante después de que la ventana aparece; si todavía no está, va por
    // el dispatcher, con la sintaxis de la config Lua (la de los tests de
    // Hyprland). `address` llega sin el 0x de adelante.
    function focus(toplevel): void {
        if (!toplevel)
            return;

        if (toplevel.wayland) {
            toplevel.wayland.activate();
            return;
        }

        if (toplevel.address)
            Hyprland.dispatch("hl.dsp.focus({ window = 'address:0x" + toplevel.address + "' })");
    }

    function remember(toplevel) {
        const workspace = toplevel.workspace;
        if (!workspace || toplevel.address === "")
            return;

        const next = Object.assign({}, root.lastActiveByWorkspace);
        next[workspace.id] = toplevel.address;
        root.lastActiveByWorkspace = next;
    }

    Variants {
        model: Hyprland.toplevels.values

        Connections {
            id: tracker

            required property var modelData
            target: tracker.modelData

            function onActivatedChanged() {
                if (tracker.modelData.activated)
                    root.remember(tracker.modelData);
            }

            Component.onCompleted: {
                if (tracker.modelData.activated)
                    root.remember(tracker.modelData);
            }
        }
    }
}