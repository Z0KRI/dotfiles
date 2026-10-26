// Ajustes › Bluetooth: encender y apagar, tus dispositivos y los cercanos.
// Mientras la página está a la vista se buscan dispositivos nuevos.
//
// Emparejar desde aquí funciona con lo que empareja sin preguntar nada
// (audífonos, bocinas, la mayoría de mouses y controles). Lo que pide
// confirmar un código (teclados, teléfonos) necesita un "agente de
// emparejamiento" que muestre ese código, y Quickshell no trae uno: para
// esos, blueman-applet o bluetoothctl. La nota al pie lo dice.

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.airpods
import qs.domain.bluetooth
import qs.domain.settings

SettingsPage {
    id: root

    Component.onCompleted: BluetoothControl.startDiscovery()
    Component.onDestruction: BluetoothControl.stopDiscovery()

    SettingsHero {
        icon: Theme.systemIcons.bluetooth.on
        tint: "#0a84ff"
        title: "Bluetooth"
        description: {
            if (!BluetoothControl.available)
                return "Este equipo no tiene adaptador Bluetooth.";
            if (BluetoothControl.powered && BluetoothControl.adapterName !== "")
                return "Visible como «" + BluetoothControl.adapterName + "».";
            return "Conecta audífonos, bocinas, teclados y más.";
        }
        showSwitch: BluetoothControl.available
        checked: BluetoothControl.powered
        onToggled: BluetoothControl.toggle()
    }

    SettingsGroup {
        visible: BluetoothControl.powered
        header: "Mis dispositivos"

        Repeater {
            model: BluetoothControl.devices

            SettingsRow {
                id: device

                required property var modelData

                glyph: Theme.systemIcons.device[device.modelData.kind]
                title: device.modelData.name
                subtitle: device.modelData.detail !== "" ? device.modelData.detail : "No conectado"

                // Tus AirPods conectados: la (i) lleva a su página, como en macOS.
                Icon {
                    visible: AirPods.owns(device.modelData)
                    icon: Theme.systemIcons.info
                    size: 15
                    color: infoHover.hovered ? Theme.colors.accent : Theme.window.textMuted

                    HoverHandler {
                        id: infoHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: SettingsControl.go("airpods")
                    }
                }

                PushButton {
                    text: device.modelData.connected ? "Desconectar" : "Conectar"
                    onClicked: BluetoothControl.toggleDevice(device.modelData.address)
                }

                Icon {
                    icon: Theme.systemIcons.trash
                    size: 14
                    color: forgetHover.hovered ? Theme.colors.error : Theme.window.textMuted

                    HoverHandler {
                        id: forgetHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: BluetoothControl.forget(device.modelData.address)
                    }
                }
            }
        }

        SettingsRow {
            visible: BluetoothControl.devices.length === 0
            title: "Todavía no emparejas ningún dispositivo."
        }
    }

    SettingsGroup {
        visible: BluetoothControl.powered
        header: "Dispositivos cercanos"
        footer: "Los que piden confirmar un código (teclados, teléfonos) se emparejan "
                + "desde la configuración avanzada o con bluetoothctl."

        Repeater {
            model: BluetoothControl.nearby

            SettingsRow {
                id: candidate

                required property var modelData

                glyph: Theme.systemIcons.device[candidate.modelData.kind]
                title: candidate.modelData.name
                subtitle: candidate.modelData.detail

                PushButton {
                    text: candidate.modelData.pairing ? "Cancelar" : "Conectar"
                    primary: !candidate.modelData.pairing
                    onClicked: {
                        if (candidate.modelData.pairing)
                            BluetoothControl.cancelPair(candidate.modelData.address);
                        else
                            BluetoothControl.pair(candidate.modelData.address);
                    }
                }
            }
        }

        SettingsRow {
            visible: BluetoothControl.nearby.length === 0
            glyph: Theme.systemIcons.scanning
            title: BluetoothControl.discovering ? "Buscando…" : "No hay dispositivos cercanos."
        }
    }

    Item {
        visible: BluetoothControl.hasSettingsApp
        width: parent.width
        height: advanced.height

        PushButton {
            id: advanced

            anchors.right: parent.right
            text: "Configuración avanzada…"
            onClicked: BluetoothControl.openSettings()
        }
    }
}
