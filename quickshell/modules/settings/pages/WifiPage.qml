pragma ComponentBehavior: Bound

// (Bound: los delegados de los Repeater pueden leer los id de afuera,
// como `root`, y qmllint lo sabe. A cambio, lo de cada delegado se pide
// con su id: `fila.modelData`, no `modelData` a secas desde un hijo.)

// Ajustes › Wi-Fi, como el de macOS y solo de Wi-Fi:
//   - arriba, el interruptor y la red en uso con "Detalles…";
//   - las redes conocidas que están al alcance;
//   - las otras redes, con "Conectar" al pasar el ratón.
//
// Mientras la página está a la vista se buscan redes; al salir, se deja de
// buscar (el Loader la destruye y corre onDestruction).
//
// La página solo pinta y avisa. Las hojas (contraseña, detalles y "¿Eliminar
// la red?") las pone la ventana de Ajustes, encima de todo; aquí solo se le
// dice al dominio qué pidió la persona.

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.network

SettingsPage {
    id: root

    Component.onCompleted: WifiControl.startScan()
    Component.onDestruction: WifiControl.stopScan()

    // ── Wi-Fi y la red en uso ────────────────────────────────
    SettingsHero {
        icon: Theme.systemIcons.wifi.high
        tint: "#0a84ff"
        title: "Wi-Fi"
        description: WifiControl.available
            ? "Conecta tu equipo a internet sin cables. Activa el Wi-Fi y elige una red para unirte."
            : "Este equipo no tiene adaptador Wi-Fi."
        showSwitch: WifiControl.available
        checked: WifiControl.powered
        onToggled: WifiControl.toggle()

        SettingsRow {
            visible: WifiControl.powered && WifiControl.current !== null

            title: WifiControl.current?.name ?? ""
            subtitle: WifiControl.current?.detail ?? ""
            // Verde conectada; ámbar mientras entra o sale.
            dot: (WifiControl.current?.busy ?? false) ? Theme.colors.warning : Theme.colors.success

            Icon {
                visible: !(WifiControl.current?.open ?? true)
                icon: Theme.systemIcons.lock
                size: 13
                color: Theme.window.text
            }

            Icon {
                icon: Theme.systemIcons.wifi[WifiControl.current?.level ?? "none"]
                size: 15
                color: Theme.window.text
            }

            PushButton {
                text: "Detalles…"
                onClicked: WifiControl.openDetails(WifiControl.current.name)
            }
        }
    }

    // ── Redes conocidas ──────────────────────────────────────
    SettingsGroup {
        visible: WifiControl.powered && WifiControl.known.length > 0
        header: WifiControl.known.length === 1 ? "Red conocida" : "Redes conocidas"

        Repeater {
            model: WifiControl.known

            NetworkRow {
                id: known

                required property var modelData

                title: known.modelData.name
                subtitle: known.modelData.busy ? known.modelData.detail : ""
                checked: known.modelData.connected
                locked: !known.modelData.open
                signalIcon: Theme.systemIcons.wifi[known.modelData.level]
                actionText: known.modelData.connected || known.modelData.busy ? "" : "Conectar"
                showMore: true
                onAction: WifiControl.choose(known.modelData.name)
                onMore: WifiControl.openDetails(known.modelData.name)
            }
        }
    }

    // ── Otras redes ──────────────────────────────────────────
    Column {
        visible: WifiControl.powered
        width: parent.width
        spacing: 7

        Item {
            width: parent.width
            height: othersTitle.implicitHeight

            Label {
                id: othersTitle

                leftPadding: 4
                text: "Otras redes"
                color: Theme.window.text
                font.pixelSize: Theme.window.fontBody
                font.weight: Font.DemiBold
            }

            // La ruedita de macOS: gira mientras se buscan redes.
            Icon {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                visible: WifiControl.scanning
                icon: Theme.systemIcons.spinner
                size: 14
                color: Theme.window.textMuted

                RotationAnimation on rotation {
                    running: WifiControl.scanning
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 1100
                }
            }
        }

        SettingsGroup {
            Repeater {
                model: WifiControl.others

                NetworkRow {
                    id: other

                    required property var modelData

                    title: other.modelData.name
                    subtitle: other.modelData.busy ? other.modelData.detail : ""
                    locked: !other.modelData.open
                    signalIcon: Theme.systemIcons.wifi[other.modelData.level]
                    actionText: other.modelData.busy ? "" : "Conectar"
                    onAction: WifiControl.choose(other.modelData.name)
                }
            }

            SettingsRow {
                visible: WifiControl.others.length === 0
                title: WifiControl.known.length === 0 ? "Buscando redes…" : "No hay más redes al alcance."
            }
        }
    }
}
