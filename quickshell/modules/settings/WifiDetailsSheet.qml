// La hoja de detalles de una red Wi-Fi (el "Detalles…" de macOS):
// conectarse sola, dirección Wi-Fi privada, datos reducidos, y la IP, el
// router y los DNS si es la red en uso. Abajo: Olvidar esta red…, Cancelar
// y Aceptar.
//
// Patrón BORRADOR: los interruptores no tocan nada todavía. Al abrir se
// copian los valores reales a `draft`; cada control cambia el borrador, y
// solo Aceptar se lo entrega al dominio (que manda a NetworkManager lo que
// de verdad cambió). Cancelar es simplemente cerrar: el borrador se tira.

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.network

Sheet {
    id: root

    shown: WifiControl.details !== null
    cardWidth: 480
    cardColor: Theme.window.background

    // Lo último que se enseñó: mientras la hoja se desvanece, `details` ya es
    // null y los textos no deben quedarse en blanco.
    property var info: ({
        name: "", connected: false, status: "", level: "none", security: "", saved: false,
        address: "", ip: "", router: "", dns: ""
    })

    property bool autoJoin: true
    property string privateAddress: "off"
    property bool lowData: false

    readonly property var addressModes: [
        { value: "off", label: "No" },
        { value: "fixed", label: "Fija" },
        { value: "rotating", label: "Rotativa" }
    ]

    readonly property var addressHelp: ({
        off: "Usa la dirección real de tu tarjeta. La red siempre te reconoce.",
        fixed: "Una dirección inventada, siempre la misma en esta red: te reconoce aquí, "
               + "pero no te pueden seguir de una red a otra.",
        rotating: "Una dirección nueva cada vez que te conectas. Algunas redes te pedirán "
                  + "iniciar sesión de nuevo."
    })

    function load(): void {
        const details = WifiControl.details;
        root.info = details;
        root.autoJoin = details.autoJoin;
        root.privateAddress = details.privateAddress;
        root.lowData = details.lowData;
    }

    function accept(): void {
        WifiControl.saveDetails({
            autoJoin: root.autoJoin,
            privateAddress: root.privateAddress,
            lowData: root.lowData
        });
    }

    onShownChanged: {
        if (root.shown)
            root.load();
    }

    // Con la hoja abierta siguen llegando datos (la IP, o el perfil recién
    // leído). Se refresca lo que solo se lee; el borrador no, salvo que el
    // perfil apenas aparezca.
    Connections {
        target: WifiControl

        function onDetailsChanged() {
            const details = WifiControl.details;
            if (!details)
                return;

            const firstProfile = !root.info.saved && details.saved;
            root.info = details;
            if (firstProfile)
                root.load();
        }
    }

    Component.onDestruction: WifiControl.closeDetails()

    onReturnPressed: root.accept()
    onEscapePressed: WifiControl.closeDetails()

    // ── La red ───────────────────────────────────────────────
    Row {
        width: parent.width
        spacing: 12

        SymbolTile {
            id: tile

            size: 36
            icon: Theme.systemIcons.wifi[root.info.level] ?? Theme.systemIcons.wifi.high
            tint: "#0a84ff"
        }

        Column {
            width: parent.width - tile.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Label {
                width: parent.width
                text: root.info.name
                color: Theme.window.text
                font.pixelSize: Theme.window.fontTitle
                font.weight: Font.Bold
            }

            Row {
                spacing: 5

                Rectangle {
                    visible: root.info.connected
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8
                    height: 8
                    radius: 4
                    color: Theme.colors.success
                }

                Label {
                    text: root.info.connected ? root.info.status
                                              : (root.info.saved ? "Conocida · no conectada" : "No conectada")
                    color: Theme.window.textMuted
                    font.pixelSize: Theme.window.fontCaption + 1
                }
            }
        }
    }

    // ── Ajustes del perfil ───────────────────────────────────
    SettingsGroup {
        visible: root.info.saved

        ToggleRow {
            title: "Conectarse automáticamente a esta red"
            checked: root.autoJoin
            onToggled: root.autoJoin = !root.autoJoin
        }

        SettingsRow {
            title: "Dirección Wi-Fi privada"
            subtitle: root.addressHelp[root.privateAddress] ?? ""

            SegmentedControl {
                options: root.addressModes
                current: root.privateAddress
                onSelected: value => root.privateAddress = value
            }
        }

        SettingsRow {
            visible: root.info.address !== ""
            title: "Dirección Wi-Fi"
            value: root.info.address
        }

        ToggleRow {
            title: "Modo de datos reducidos"
            subtitle: "Marca la red como de datos limitados: las apps que lo respetan "
                      + "evitan descargas grandes."
            checked: root.lowData
            onToggled: root.lowData = !root.lowData
        }
    }

    // ── La conexión ──────────────────────────────────────────
    SettingsGroup {
        SettingsRow {
            title: "Seguridad"
            value: root.info.security
        }

        SettingsRow {
            visible: root.info.ip !== ""
            title: "Dirección IP"
            value: root.info.ip
        }

        SettingsRow {
            visible: root.info.router !== ""
            title: "Router"
            value: root.info.router
        }

        SettingsRow {
            visible: root.info.dns !== ""
            title: "DNS"
            value: root.info.dns
        }
    }

    Item {
        width: 1
        height: 2
    }

    Item {
        width: parent.width
        height: buttons.height

        PushButton {
            visible: root.info.saved
            anchors.left: parent.left
            text: "Olvidar esta red…"
            onClicked: WifiControl.askForget(root.info.name)
        }

        Row {
            id: buttons

            anchors.right: parent.right
            spacing: 10

            PushButton {
                width: 90
                text: "Cancelar"
                onClicked: WifiControl.closeDetails()
            }

            PushButton {
                width: 90
                primary: true
                text: "Aceptar"
                onClicked: root.accept()
            }
        }
    }
}
