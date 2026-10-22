pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Cuántas apps distintas tiene el historial.
    readonly property int appCount: Object.keys(store.counts).length

    function record(appId: string): void {
        if (!appId)
            return;

        const next = Object.assign({}, store.counts);
        next[appId] = (next[appId] ?? 0) + 1;
        store.counts = next;
    }

    function countFor(appId: string): int {
        return store.counts[appId] ?? 0;
    }

    // Borra todo el historial. Se reasigna un objeto nuevo (no se vacía el
    // viejo) para que el adaptador se entere del cambio y lo guarde.
    function clear(): void {
        store.counts = ({});
    }

    FileView {
        path: Quickshell.statePath("usage.json")

        watchChanges: true
        onFileChanged: reload()

        onAdapterUpdated: writeAdapter()

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        adapter: JsonAdapter {
            id: store

            property var counts: ({})
        }
    }
}
