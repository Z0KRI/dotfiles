// Ajustes › Isla dinámica: qué sale en la isla y cómo se abre.
// Las notificaciones tienen su propia sección (tienen más reglas: No
// molestar, llamadas, apps); aquí solo se enlaza a ella.

import QtQuick
import qs.core.theme
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.island
import qs.domain.notifications
import qs.domain.settings

SettingsPage {
    id: root

    SettingsHero {
        icon: Theme.systemIcons.island
        tint: "#1c1c1e"
        title: "Isla dinámica"
        description: "La píldora del borde de arriba: el volumen y el brillo al cambiarlos, "
                     + "tus AirPods y tu teclado, lo que suena y lo que te llega."
    }

    SettingsGroup {
        header: "Mostrar en la isla"

        ToggleRow {
            glyph: Theme.systemIcons.volume.high
            title: "Volumen"
            subtitle: "Al subir o bajar el volumen, por unos segundos."
            checked: IslandOccupants.volume
            onToggled: IslandOccupants.setVolume(!IslandOccupants.volume)
        }

        ToggleRow {
            glyph: Theme.systemIcons.sun
            title: "Brillo"
            subtitle: "Al usar las teclas de brillo (en el teclado Apple, F1 y F2)."
            checked: IslandOccupants.brightness
            onToggled: IslandOccupants.setBrightness(!IslandOccupants.brightness)
        }

        ToggleRow {
            glyph: Theme.systemIcons.music
            title: "Música"
            subtitle: "Lo que suena, con su carátula. Se queda mientras haya pista."
            checked: IslandOccupants.player
            onToggled: IslandOccupants.setPlayer(!IslandOccupants.player)
        }

        ToggleRow {
            glyph: Theme.systemIcons.device.headphones
            title: "AirPods"
            subtitle: "Al conectarlas, con su batería, y al cambiar el control de ruido."
            checked: IslandOccupants.airpods
            onToggled: IslandOccupants.setAirPods(!IslandOccupants.airpods)
        }

        ToggleRow {
            glyph: Theme.systemIcons.device.keyboard
            title: "Teclado"
            subtitle: "Al conectar un teclado Bluetooth, con su batería, y cuando le queda poca."
            checked: IslandOccupants.keyboard
            onToggled: IslandOccupants.setKeyboard(!IslandOccupants.keyboard)
        }

        SettingsRow {
            glyph: Theme.systemIcons.bell
            title: "Notificaciones"
            value: NotificationSettings.banners ? "Activadas" : "Desactivadas"
            navigates: true
            onActivated: SettingsControl.go("notifications")
        }
    }

    SettingsGroup {
        header: "Comportamiento"

        ToggleRow {
            title: "Abrir al pasar el mouse"
            subtitle: "Despliega la tarjeta tras un momento encima. Apagado, se abre con un clic."
            checked: IslandOccupants.expandOnHover
            onToggled: IslandOccupants.setExpandOnHover(!IslandOccupants.expandOnHover)
        }
    }
}
