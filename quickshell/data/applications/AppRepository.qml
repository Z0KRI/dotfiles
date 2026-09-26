pragma Singleton

import Quickshell

Singleton {
    id: root

    readonly property var entries: DesktopEntries.applications.values
        .filter(entry => !entry.noDisplay)

    function launch(entry) {
        if (!entry) return;
        entry.execute();
    }
}