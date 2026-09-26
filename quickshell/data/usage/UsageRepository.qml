pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

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
