// CASO DE USO: buscar archivos en Spotlight.
// Reglas:
//   - Desde 2 letras. Con una sola, plocate devolvería media carpeta.
//   - Cada palabra que escribes tiene que estar en la ruta, en cualquier
//     orden y sin importar mayúsculas: "informe 2025" encuentra
//     ~/Trabajo/2025/Informe final.pdf.
//   - Primero lo que coincide en el NOMBRE (con la puntuación de Fuzzy, igual
//     que las apps); lo que solo coincide en la carpeta va al final. Empates:
//     lo más reciente primero.
//   - Sin ocultos (~/.config, ~/.cache…) ni node_modules: lo mismo que
//     excluía tu files.sh de rofi.
//   - Sin texto: los recientes.
//
// Mientras plocate responde, se muestran los resultados de la búsqueda
// anterior filtrados con lo que llevas escrito. Es correcto, no un parche:
// plocate trajo las rutas que contienen todas las palabras viejas, y el
// filtro de aquí exige las nuevas, así que lo que queda también coincide.
// Al escribir una letra más la lista nunca se vacía ni parpadea.

pragma Singleton

import Quickshell
import qs.core.utils
import qs.data.files
import qs.data.system

Singleton {
    id: root

    readonly property int minLength: 2
    readonly property int fetchLimit: 300

    readonly property bool available: FileRepository.available
    readonly property bool busy: FileRepository.busy

    // ¿Salen archivos en la búsqueda general (Super + Espacio)?
    readonly property bool inGeneral: PreferencesRepository.launcherFiles

    function setInGeneral(on): void {
        PreferencesRepository.launcherFiles = on;
    }

    function words(query) {
        return String(query ?? "").trim().toLowerCase().split(/\s+/).filter(word => word.length > 0);
    }

    function searchable(query) {
        return root.words(query).join(" ").length >= root.minLength;
    }

    // Lanza la búsqueda (el resultado llega después, por FileRepository).
    function request(query): void {
        if (root.searchable(query))
            FileRepository.search(root.words(query), false, root.fetchLimit);
        else
            FileRepository.clear();
    }

    // Lo que hay ahora para `query`, ya ordenado.
    function find(query, limit) {
        if (!root.searchable(query))
            return [];

        const words = root.words(query);

        return FileRepository.results
            .filter(file => {
                const path = file.path.toLowerCase();
                return words.every(word => path.indexOf(word) >= 0);
            })
            .map(file => ({ file: file, score: root.rank(file, words) }))
            .sort((a, b) => b.score - a.score || b.file.modified - a.file.modified)
            .slice(0, limit)
            .map(row => row.file);
    }

    function rank(file, words) {
        const name = file.path.slice(file.path.lastIndexOf("/") + 1);
        const score = words.reduce((sum, word) => sum + Fuzzy.score(name, word), 0);

        // 1 y no 0: sí coincide (en la carpeta), solo que va al final.
        return score > 0 ? score : 1;
    }

    // ── recientes ────────────────────────────────────────────────
    function loadRecent(): void {
        FileRepository.refreshRecent(40);
    }

    function recent(limit) {
        return FileRepository.recent
            .filter(file => file.path.indexOf("/.") < 0)
            .slice(0, limit);
    }
}
