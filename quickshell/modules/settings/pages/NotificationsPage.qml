// Ajustes › Notificaciones: No molestar, los avisos en la isla, qué apps
// pueden notificarte y el historial.
//
// La lista de apps se llena sola: cada app aparece la primera vez que te
// manda algo, como en macOS. Apagar una no la borra de la lista; "olvidar"
// sí (y vuelve a aparecer si te escribe otra vez).

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.notifications

SettingsPage {
    id: root

    SettingsHero {
        icon: Theme.systemIcons.bell
        tint: "#ff3b30"
        title: "Notificaciones"
        description: "Tu shell es el servidor de notificaciones: todo lo que llega, "
                     + "de la computadora o del iPhone, pasa por aquí."
    }

    SettingsGroup {
        ToggleRow {
            icon: Theme.systemIcons.moon
            tint: "#5e5ce6"
            title: "No molestar"
            subtitle: "No salen en la isla, pero se guardan en el historial."
            checked: DoNotDisturb.active
            onToggled: DoNotDisturb.toggle()
        }

        ToggleRow {
            glyph: Theme.systemIcons.phoneCall
            title: "Permitir llamadas"
            subtitle: "Las llamadas del iPhone suenan aunque esté activo No molestar."
            checked: NotificationSettings.allowCalls
            onToggled: NotificationSettings.setAllowCalls(!NotificationSettings.allowCalls)
        }
    }

    SettingsGroup {
        footer: "Apagado, las notificaciones solo se guardan; las llamadas siguen sonando."

        ToggleRow {
            glyph: Theme.systemIcons.island
            title: "Mostrar avisos en la isla"
            checked: NotificationSettings.banners
            onToggled: NotificationSettings.setBanners(!NotificationSettings.banners)
        }
    }

    SettingsGroup {
        header: "Apps"
        footer: "Una app aparece aquí la primera vez que te notifica. Apagada, lo que "
                + "mande no sale ni se guarda."

        Repeater {
            model: NotificationSettings.apps

            ToggleRow {
                id: app

                required property var modelData

                // La tabla de glifos vive en el tema (AppGlyphs), no en las reglas.
                icon: AppGlyphs.forApp(app.modelData.name)
                iconFamily: Theme.font.mono
                tint: app.modelData.phone ? "#30b94d" : "#8e8e93"
                title: app.modelData.name
                subtitle: app.modelData.phone ? "Desde el iPhone" : ""
                checked: app.modelData.allowed !== false
                onToggled: NotificationSettings.setAllowed(app.modelData.name, !app.checked)

                Icon {
                    icon: Theme.systemIcons.trash
                    size: 13
                    color: forgetHover.hovered ? Theme.colors.error : Theme.window.textMuted

                    HoverHandler {
                        id: forgetHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: NotificationSettings.forget(app.modelData.name)
                    }
                }
            }
        }

        SettingsRow {
            visible: NotificationSettings.apps.length === 0
            title: "Todavía ninguna app te ha notificado."
        }
    }

    SettingsGroup {
        header: "Historial"

        SettingsRow {
            glyph: Theme.systemIcons.history
            title: "Guardadas"
            value: Notifications.count === 1 ? "1 notificación" : Notifications.count + " notificaciones"

            PushButton {
                text: "Borrar todas"
                destructive: true
                enabled: Notifications.count > 0
                onClicked: Notifications.dismissAll()
            }
        }
    }
}
