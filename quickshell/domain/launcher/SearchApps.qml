pragma Singleton

import Quickshell
import qs.core.utils
import qs.data.applications

Singleton {
    id: root

    readonly property int weightName: 3
    readonly property int weightGeneric: 2
    readonly property int weightComment: 1
    readonly property int weightUsage: 5

    // El uso sale de LaunchHistory, no del repositorio: si apagas el
    // historial en Ajustes, cuenta 0 y el orden queda alfabético.
    function execute(query) {
        const needle = (query ?? "").trim().toLowerCase();
        const entries = AppRepository.entries;

        if (needle === "")
            return entries.slice().sort((a, b) =>
                LaunchHistory.countFor(b.id) - LaunchHistory.countFor(a.id)
                || a.name.localeCompare(b.name));

        return entries
            .map(entry => ({ entry: entry, score: root.rank(entry, needle) }))
            .filter(row => row.score > 0)
            .sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name))
            .map(row => row.entry);
    }

    function rank(entry, needle) {
        const match = Fuzzy.score(entry.name, needle) * root.weightName
                    + Fuzzy.score(entry.genericName, needle) * root.weightGeneric
                    + Fuzzy.score(entry.comment, needle) * root.weightComment;

        if (match === 0)
            return 0;

        return match + root.usageBonus(entry);
    }

    function usageBonus(entry) {
        return Math.log(1 + LaunchHistory.countFor(entry.id)) * root.weightUsage;
    }
}
