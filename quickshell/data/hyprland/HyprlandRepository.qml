pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property var lastActiveByWorkspace: ({})

    // Los monitores, como datos planos. La frecuencia no es propiedad del
    // monitor en Quickshell: viene en `lastIpcObject`, la respuesta cruda de
    // `hyprctl monitors -j`.
    readonly property var monitors: Hyprland.monitors.values.map(monitor => ({
        name: monitor.name,
        description: monitor.description,
        width: monitor.width,
        height: monitor.height,
        scale: monitor.scale,
        focused: monitor.focused,
        refreshRate: monitor.lastIpcObject?.refreshRate ?? 0
    }))

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