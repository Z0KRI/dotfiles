// CASO DE USO: la web desde Spotlight, lo que hacía tu rofi_web.sh.
// Reglas:
//   - Si lo que escribes parece una dirección (github.com, https://…,
//     localhost:4200), sale arriba "Abrir en el navegador".
//   - Siempre hay un último resultado "Buscar en <buscador>", así Spotlight
//     nunca se queda sin nada que hacer con lo que escribiste.
//   - Se abre en tu navegador predeterminado (el de xdg-settings), no en uno
//     fijo: cambiar de navegador no obliga a tocar la shell.
//
// ¿Por qué una lista de dominios conocidos? Sin ella "informe.pdf" o
// "notas.md" parecerían direcciones (texto, punto, texto). Con la lista, solo
// es dirección lo que termina en un dominio real, lo que empieza con www. o
// trae su https:// por delante. Por eso tampoco están .sh, .so ni .ai: son
// dominios de verdad, pero también extensiones de archivo (deploy.sh).

pragma Singleton

import Quickshell
import qs.data.system

Singleton {
    id: root

    readonly property var engines: [
        { id: "google", label: "Google", url: "https://www.google.com/search?q=" },
        { id: "duckduckgo", label: "DuckDuckGo", url: "https://duckduckgo.com/?q=" },
        { id: "bing", label: "Bing", url: "https://www.bing.com/search?q=" }
    ]

    readonly property var engine: root.engines.find(e => e.id === PreferencesRepository.launcherSearchEngine)
                                  ?? root.engines[0]

    function setEngine(id): void {
        if (root.engines.some(e => e.id === id))
            PreferencesRepository.launcherSearchEngine = id;
    }

    readonly property var domains: [
        "com", "net", "org", "io", "dev", "app", "co", "me", "tv", "info", "edu", "gov",
        "mx", "es", "ar", "cl", "pe", "us", "uk", "de", "fr", "it", "br", "ca", "jp",
        "gob", "xyz", "tech", "site", "online", "cloud", "page", "gg", "ly"
    ]

    function looksLikeUrl(text) {
        const t = String(text ?? "").trim();
        if (t === "" || /\s/.test(t))
            return false;

        if (/^[a-z][a-z0-9+.-]*:\/\//i.test(t))
            return true;

        // localhost:4200, 127.0.0.1:8000/admin, 192.168.1.10
        if (/^(localhost|\d{1,3}(\.\d{1,3}){3})(:\d+)?(\/\S*)?$/i.test(t))
            return true;

        const host = /^([a-z0-9-]+(\.[a-z0-9-]+)+)(:\d+)?(\/\S*)?$/i.exec(t);
        if (!host)
            return false;

        const labels = host[1].toLowerCase().split(".");
        return labels[0] === "www" || root.domains.indexOf(labels[labels.length - 1]) >= 0;
    }

    // github.com → https://github.com. Lo que ya trae esquema queda igual.
    function toUrl(text) {
        const t = String(text ?? "").trim();
        if (/^[a-z][a-z0-9+.-]*:\/\//i.test(t))
            return t;
        if (/^(localhost|\d{1,3}(\.\d{1,3}){3})/i.test(t))
            return "http://" + t;
        return "https://" + t;
    }

    function searchUrl(query) {
        return root.engine.url + encodeURIComponent(String(query ?? "").trim());
    }

    function open(address): void {
        OpenerRepository.openUri(address);
    }
}
