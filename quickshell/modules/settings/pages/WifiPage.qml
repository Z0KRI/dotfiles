// Ajustes › Wi-Fi: encender y apagar, la red actual y las demás.
// Mientras la página está a la vista se buscan redes; al salir, se deja de
// buscar (el Loader la destruye y corre onDestruction).

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.network

SettingsPage {
    id: root

    readonly property var others: WifiControl.networks.filter(network => !network.connected)

    Component.onCompleted: WifiControl.startScan()
    Component.onDestruction: WifiControl.stopScan()

    SettingsHero {
        icon: Theme.systemIcons.wifi.high
        tint: "#0a84ff"
        title: "Wi-Fi"
        description: WifiControl.available
            ? "Las redes que ya usaste se conectan solas."
            : "Este equipo no tiene adaptador Wi-Fi."
        showSwitch: WifiControl.available
        checked: WifiControl.powered
        onToggled: WifiControl.toggle()
    }

    SettingsGroup {
        visible: WifiControl.wired && (!WifiControl.available || !WifiControl.current)

        SettingsRow {
            glyph: Theme.systemIcons.device.display
            title: "Ethernet"
            subtitle: "Conectado por cable"
        }
    }

    SettingsGroup {
        visible: WifiControl.powered && WifiControl.current !== null

        SettingsRow {
            glyph: Theme.systemIcons.wifi[WifiControl.current?.level ?? "none"]
            title: WifiControl.current?.name ?? ""
            subtitle: WifiControl.current?.detail ?? ""

            Icon {
                visible: !(WifiControl.current?.open ?? true)
                icon: Theme.systemIcons.lock
                size: 13
                color: Theme.window.textMuted
            }

            PushButton {
                text: "Desconectar"
                onClicked: WifiControl.disconnect(WifiControl.current.name)
            }
        }
    }

    SettingsGroup {
        visible: WifiControl.powered
        header: "Otras redes"
        footer: WifiControl.passwordNeededFor !== ""
            ? "«" + WifiControl.passwordNeededFor + "» pide contraseña. Conéctate una vez "
              + "desde la configuración avanzada; después podrás hacerlo desde aquí."
            : ""

        Repeater {
            model: root.others

            SettingsRow {
                id: network

                required property var modelData

                glyph: Theme.systemIcons.wifi[network.modelData.level]
                title: network.modelData.name
                subtitle: network.modelData.detail
                clickable: true
                onActivated: WifiControl.choose(network.modelData.name)

                Icon {
                    visible: !network.modelData.open
                    icon: Theme.systemIcons.lock
                    size: 13
                    color: Theme.window.textMuted
                }
            }
        }

        SettingsRow {
            visible: root.others.length === 0
            title: "Buscando redes…"
        }
    }

    Item {
        visible: WifiControl.hasSettingsApp
        width: parent.width
        height: advanced.height

        PushButton {
            id: advanced

            anchors.right: parent.right
            text: "Configuración avanzada…"
            onClicked: WifiControl.openSettings()
        }
    }
}
