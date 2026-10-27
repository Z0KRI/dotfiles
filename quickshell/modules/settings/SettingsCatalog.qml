pragma Singleton

// El índice de Ajustes: qué secciones hay, en qué grupo de la barra lateral,
// con qué ícono y color, y con qué palabras las encuentra el buscador.
//
// Vive en el módulo y no en domain porque es pura presentación (íconos,
// colores, títulos). Lo único que el resto de tu shell sabe de Ajustes son los
// `id`: SettingsControl.open("wifi").
//
// Agregar una sección es una entrada aquí más una página en pages/.
//
// AirPods es la única que va y viene, como en macOS: sale arriba de todo
// mientras están conectados. Aun sin ellos, `find` y el buscador la
// encuentran (su página explica cómo conectarlas).

import QtQuick
import Quickshell
import qs.core.theme
import qs.domain.airpods

Singleton {
    id: root

    readonly property var airpods: ({
        id: "airpods", title: AirPods.name, tint: "#636366",
        icon: Theme.systemIcons.device.headphones,
        keywords: "airpods beats audifonos cancelacion ruido transparencia adaptativo "
                  + "conversacion bateria estuche librepods"
    })

    readonly property var groups: AirPods.connected ? [[root.airpods]].concat(root.fixed) : root.fixed

    readonly property var fixed: [
        [
            {
                id: "wifi", title: "Wi-Fi", tint: "#0a84ff",
                icon: Theme.systemIcons.wifi.high,
                keywords: "red internet inalambrica conexion contraseña"
            },
            {
                id: "bluetooth", title: "Bluetooth", tint: "#0a84ff",
                icon: Theme.systemIcons.bluetooth.on,
                keywords: "audifonos dispositivos emparejar teclado mouse bocina"
            },
            {
                id: "iphone", title: "iPhone", tint: "#30b94d",
                icon: Theme.systemIcons.device.phone,
                keywords: "telefono celular blueferry mensajes llamadas"
            }
        ],
        [
            {
                id: "notifications", title: "Notificaciones", tint: "#ff3b30",
                icon: Theme.systemIcons.bell,
                keywords: "no molestar foco concentracion avisos apps historial"
            },
            {
                id: "sound", title: "Sonido", tint: "#ff2d55",
                icon: Theme.systemIcons.volume.high,
                keywords: "volumen audio salida entrada microfono bocinas audifonos"
            }
        ],
        [
            {
                id: "appearance", title: "Apariencia", tint: "#1c1c1e",
                icon: Theme.systemIcons.darkMode,
                keywords: "oscuro claro modo acento color liquid glass vidrio transparencia"
            },
            {
                id: "displays", title: "Pantallas", tint: "#0a84ff",
                icon: Theme.systemIcons.sun,
                keywords: "brillo luz nocturna monitor monitores resolucion escala tamaño frecuencia hz "
                          + "rotacion girar vrr duplicar espejo organizar acomodar temperatura calida"
            }
        ],
        [
            {
                id: "menubar", title: "Barra de menús", tint: "#5e5ce6",
                icon: Theme.systemIcons.panelTop,
                keywords: "barra ocultar reloj fecha hora escritorio app activa"
            },
            {
                id: "island", title: "Isla dinámica", tint: "#1c1c1e",
                icon: Theme.systemIcons.island,
                keywords: "isla notch musica volumen reproductor airpods"
            },
            {
                id: "spotlight", title: "Spotlight", tint: "#8e8e93",
                icon: Theme.systemIcons.search,
                keywords: "buscar launcher apps historial atajo archivos plocate portapapeles cliphist pegar web buscador google duckduckgo"
            }
        ],
        [
            {
                id: "about", title: "Acerca de", tint: "#8e8e93",
                icon: Theme.systemIcons.info,
                keywords: "sistema equipo procesador memoria kernel version hyprland quickshell"
            }
        ]
    ]

    readonly property var all: root.fixed.reduce((list, group) => list.concat(group), [root.airpods])

    function find(id) {
        return root.all.find(section => section.id === id) ?? null;
    }

    // Minúsculas y sin acentos: "pantalla" encuentra "Pantallas" y "menus"
    // encuentra "Barra de menús".
    function fold(text) {
        return String(text || "").toLowerCase()
            .replace(/[áàä]/g, "a")
            .replace(/[éèë]/g, "e")
            .replace(/[íìï]/g, "i")
            .replace(/[óòö]/g, "o")
            .replace(/[úùü]/g, "u")
            .replace(/ñ/g, "n");
    }

    // Cada palabra que escribes tiene que aparecer en el título o en las
    // palabras clave, en cualquier orden.
    function search(query) {
        const words = root.fold(query).split(/\s+/).filter(word => word.length > 0);
        if (words.length === 0)
            return [];

        return root.all.filter(section => {
            const haystack = root.fold(section.title + " " + section.keywords);
            return words.every(word => haystack.indexOf(word) >= 0);
        });
    }
}
