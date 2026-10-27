// CASO DE USO: buscar apps en Spotlight.
// Reglas:
//   - Sin texto: todas, las más usadas primero y luego alfabético.
//   - Con texto: coincidencia difusa en nombre (pesa 3), nombre genérico (2),
//     descripción y palabras clave del .desktop (1), más un extra por uso
//     (logarítmico: abrir una app 100 veces no la deja fija arriba para
//     siempre). Las palabras clave son las que el .desktop declara para
//     buscarlo: "navegador" encuentra Firefox aunque no lo diga su nombre.
//   - Sin coincidencia, no sale aunque la uses mucho.

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
                    + Fuzzy.score(entry.comment, needle) * root.weightComment
                    + root.keywordScore(entry, needle) * root.weightComment;

        if (match === 0)
            return 0;

        return match + root.usageBonus(entry);
    }

    // La mejor coincidencia entre sus palabras clave (Keywords= del .desktop).
    // Solo cuenta si la palabra CONTIENE lo que escribiste (60 o más en
    // Fuzzy): una app trae decenas de palabras clave, y con letras sueltas en
    // orden casi cualquier búsqueda corta encontraría alguna.
    function keywordScore(entry, needle) {
        const keywords = entry.keywords ?? [];
        let best = 0;
        for (const keyword of keywords) {
            const score = Fuzzy.score(keyword, needle);
            if (score >= 60)
                best = Math.max(best, score);
        }
        return best;
    }

    function usageBonus(entry) {
        return Math.log(1 + LaunchHistory.countFor(entry.id)) * root.weightUsage;
    }
}
