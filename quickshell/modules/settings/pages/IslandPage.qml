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
        description: "La píldora del borde de arriba: el volumen al cambiarlo, lo que "
                     + "suena y lo que te llega."
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
            glyph: Theme.systemIcons.music
            title: "Música"
            subtitle: "Lo que suena, con su carátula. Se queda mientras haya pista."
            checked: IslandOccupants.player
            onToggled: IslandOccupants.setPlayer(!IslandOccupants.player)
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
