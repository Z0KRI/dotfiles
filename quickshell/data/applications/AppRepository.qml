import Quickshell
pragma Singleton

Singleton {
    id: root

    readonly property var entries: DesktopEntries.applications.values.filter((entry) => {
        return !entry.noDisplay;
    })

    function launch(entry) {
        if (!entry)
            return ;

        entry.execute();
    }

    function nameFor(appId) {
        if (!appId)
            return "";

        return DesktopEntries.heuristicLookup(appId)?.name ?? "";
    }

    function entryFor(appId) {
        DesktopEntries.applications.values;
        if (!appId)
            return null;

        return DesktopEntries.heuristicLookup(appId);
    }

}
