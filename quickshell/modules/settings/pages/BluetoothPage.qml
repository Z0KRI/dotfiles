// Ajustes › Bluetooth: encender y apagar, tus dispositivos y los cercanos.
// Mientras la página está a la vista se buscan dispositivos nuevos.
//
// "Conectar" en un cercano lo empareja. Si pide un código (un teclado, un
// teléfono), sale la hoja de emparejamiento encima de la ventana
// (modules/settings/PairingSheet.qml) con el código a escribir o a comparar.
//
// La (i) de una fila lleva a su página, como en macOS: tus AirPods a
// Ajustes › AirPods y un teclado conectado (de cualquier marca) a
// Ajustes › Teclado.

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

                // ¿Tiene página propia? Tus AirPods y los teclados, conectados.
                readonly property string page: AirPods.owns(device.modelData) ? "airpods"
                    : device.modelData.connected && device.modelData.kind === "keyboard" ? "keyboard" : ""

                glyph: Theme.systemIcons.device[device.modelData.kind]
                title: device.modelData.name
                subtitle: device.modelData.detail !== "" ? device.modelData.detail : "No conectado"

                Icon {
                    visible: device.page !== ""
                    icon: Theme.systemIcons.info
                    size: 15
                    color: infoHover.hovered ? Theme.colors.accent : Theme.window.textMuted

                    HoverHandler {
                        id: infoHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: SettingsControl.go(device.page)
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
        footer: "Para que aparezca, ponlo en modo de emparejamiento: un teclado Apple se "
                + "enciende y ya; otros, con su tecla o combinación de Bluetooth. Si está "
                + "emparejado con otro equipo, apaga ahí el Bluetooth."

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
