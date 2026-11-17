pragma ComponentBehavior: Bound

// (Bound: los delegados de los Repeater pueden leer los id de afuera,
// como `root`, y qmllint lo sabe. A cambio, lo de cada delegado se pide
// con su id: `fila.modelData`, no `modelData` a secas desde un hijo.)

// Ajustes › Red: tu conexión por cable, como el servicio Ethernet de macOS:
//   - arriba, el servicio con su estado y "Detalles…";
//   - el resumen de lo que tiene ahora (IPv4, IP, máscara, router, DNS);
//   - abajo, "Eliminar servicio…", "Desactivar" y la ayuda.
//
// Con más de una tarjeta de cable sale una fila para elegir cuál ver.
//
// La página solo pinta y avisa. Qué perfil le toca a cada tarjeta y qué se
// enseña lo decide EthernetControl; las hojas (detalles y "¿Eliminar?") las
// pone la ventana de Ajustes.

import QtQuick
import Quickshell
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.network

SettingsPage {
    id: root

    readonly property var service: EthernetControl.current

    // El color del punto de estado es presentación; el estado, del dominio.
    readonly property color statusColor: ({
        connected: Theme.colors.success,
        connecting: Theme.colors.warning,
        disconnected: Theme.window.textMuted,
        unavailable: Theme.window.destructive
    })[root.service?.state ?? "unavailable"]

    readonly property var methods: ({
        auto: "Usando DHCP",
        manual: "Manualmente",
        disabled: "Desactivado"
    })

    Component.onCompleted: EthernetControl.startWatching()
    Component.onDestruction: EthernetControl.stopWatching()

    // ── Sin tarjeta de cable ─────────────────────────────────
    SettingsGroup {
        visible: root.service === null

        SettingsRow {
            icon: Theme.systemIcons.ethernet
            tint: "#8e8e93"
            title: "Ethernet"
            subtitle: EthernetControl.loaded ? "Este equipo no tiene una tarjeta de red por cable."
                                             : "Buscando tarjetas de red…"
        }
    }

    // ── Cuál servicio (solo si hay varios) ───────────────────
    SettingsGroup {
        visible: EthernetControl.services.length > 1

        SettingsRow {
            title: "Servicio"

            Row {
                spacing: 4

                Repeater {
                    model: EthernetControl.services

                    ToggleChip {
                        id: chip

                        required property var modelData

                        text: chip.modelData.name
                        checked: chip.modelData.device === root.service?.device
                        onToggled: EthernetControl.select(chip.modelData.device)
                    }
                }
            }
        }
    }

    // ── El servicio ──────────────────────────────────────────
    SettingsGroup {
        visible: root.service !== null

        SettingsRow {
            icon: Theme.systemIcons.ethernet
            tint: "#8e8e93"
            title: root.service?.name ?? ""
            subtitle: root.service?.status ?? ""
            dot: root.statusColor

            PushButton {
                text: "Detalles…"
                onClicked: EthernetControl.openDetails(root.service.device)
            }
        }
    }

    // ── Lo que tiene ahora ───────────────────────────────────
    //
    // Un campo vacío enseña su propio nombre en gris, como en macOS.
    SettingsGroup {
        visible: root.service !== null

        Repeater {
            model: [
                { title: "IPv4 configurado", value: root.methods[root.service?.ipv4Method ?? "auto"] ?? "", hint: "" },
                { title: "Dirección IP", value: root.service?.ip ?? "", hint: "Dirección IP" },
                { title: "Máscara de subred", value: root.service?.mask ?? "", hint: "Máscara de subred" },
                { title: "Router", value: root.service?.router ?? "", hint: "Router" },
                { title: "Servidores DNS", value: root.service?.dns ?? "", hint: "Servidores DNS" },
                { title: "Dominios de búsqueda", value: root.service?.domains ?? "", hint: "Dominios de búsqueda" }
            ]

            SettingsRow {
                id: field

                required property var modelData

                title: field.modelData.title

                Label {
                    text: field.modelData.value !== "" ? field.modelData.value : field.modelData.hint
                    color: Theme.window.textMuted
                    opacity: field.modelData.value !== "" ? 1 : 0.55
                    font.pixelSize: Theme.window.fontBody
                }
            }
        }
    }

    // ── Eliminar, desactivar y ayuda ─────────────────────────
    Item {
        visible: root.service !== null
        width: parent.width
        height: actions.height

        Row {
            id: actions

            spacing: 8

            PushButton {
                text: "Eliminar servicio…"
                enabled: root.service?.saved ?? false
                onClicked: EthernetControl.askDelete(root.service.device)
            }

            // Sin cable no hay nada que activar ni desactivar.
            PushButton {
                text: (root.service?.active ?? false) ? "Desactivar" : "Activar"
                enabled: (root.service?.state ?? "unavailable") !== "unavailable"
                onClicked: EthernetControl.setActive(root.service.device, !root.service.active)
            }
        }

        CircleButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "?"
            onClicked: Quickshell.execDetached(["xdg-open", "https://wiki.archlinux.org/title/NetworkManager"])
        }
    }
}
