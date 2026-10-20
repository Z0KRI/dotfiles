// Centro de control, estilo macOS Tahoe.
// Cuadrícula de dos columnas; el texto de Wi-Fi y Bluetooth y el botón
// redondo de Sonido abren su detalle.

import QtQuick
import Quickshell
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.core.components.templates
import qs.domain.network
import qs.domain.bluetooth
import qs.domain.audio
import qs.domain.media
import qs.domain.desktop
import qs.domain.session
import qs.domain.notifications

DropdownWindow {
    id: root

    required property Item anchorItem
    anchor.item: root.anchorItem

    alignRight: true
    padding: 14
    menuWidth: 340
    panelColor: Theme.glass.panel
    panelBorder: Theme.glass.border
    panelRadius: Theme.glass.panelRadius

    // ── Medidas de la cuadrícula ────────────────────────────
    readonly property int cellGap: 10
    readonly property int cellHeight: 60
    readonly property int fullWidth: root.menuWidth - root.padding * 2
    readonly property int halfWidth: (root.fullWidth - root.cellGap) / 2
    readonly property int tallHeight: root.cellHeight * 2 + root.cellGap

    // Página visible: "home", "wifi", "bluetooth" o "sound".
    property string page: "home"

    // Buscar redes solo mientras ves la lista de Wi-Fi.
    readonly property bool wantsScan: root.visible && root.page === "wifi"
    onWantsScanChanged: WifiControl.setScanning(root.wantsScan)

    onVisibleChanged: {
        if (root.visible) {
            root.page = "home";
            PhoneBridge.watch();
        } else {
            PhoneBridge.unwatch();
        }
    }

    component SectionLabel: Label {
        color: Theme.glass.contentMuted
        font.pixelSize: Theme.font.small
        font.weight: Font.DemiBold
        topPadding: 4
        bottomPadding: 4
    }

    component TileTitle: Label {
        color: Theme.glass.content
        font.pixelSize: Theme.font.small + 1
        font.weight: Font.DemiBold
    }

    // ── Inicio ──────────────────────────────────────────────
    PanelPage {
        visible: root.page === "home"
        bodySpacing: root.cellGap

        // Filas 1–2: Wi-Fi y Bluetooth · Reproduciendo
        Row {
            spacing: root.cellGap

            Column {
                spacing: root.cellGap

                ControlPill {
                    width: root.halfWidth
                    height: root.cellHeight
                    enabled: WifiControl.available
                    icon: Theme.systemIcons.wifi[WifiControl.level]
                    title: "Wi-Fi"
                    subtitle: WifiControl.status
                    active: WifiControl.powered
                    onToggled: WifiControl.toggle()
                    onOpened: root.page = "wifi"
                }

                ControlPill {
                    width: root.halfWidth
                    height: root.cellHeight
                    enabled: BluetoothControl.available
                    icon: Theme.systemIcons.bluetooth[BluetoothControl.powered ? "on" : "off"]
                    title: "Bluetooth"
                    subtitle: BluetoothControl.status
                    active: BluetoothControl.powered
                    onToggled: BluetoothControl.toggle()
                    onOpened: root.page = "bluetooth"
                }
            }

            NowPlayingTile {
                width: root.halfWidth
                height: root.tallHeight
                title: Player.hasTrack ? Player.title : "No se reproduce nada"
                subtitle: Player.hasTrack ? Player.artist : ""
                artUrl: Player.hasTrack ? Player.artUrl : ""
                playing: Player.isPlaying
                canControl: Player.canControl
                canGoPrevious: Player.canGoPrevious
                canGoNext: Player.canGoNext
                onPrevious: Player.previous()
                onToggle: Player.togglePlaying()
                onNext: Player.next()
            }
        }

        // Fila 3: iPhone · Micrófono
        Row {
            spacing: root.cellGap

            ControlPill {
                width: root.halfWidth
                height: root.cellHeight
                icon: Theme.systemIcons.device.phone
                title: "iPhone"
                subtitle: PhoneBridge.status
                active: PhoneBridge.active
                onToggled: PhoneBridge.toggle()
                onOpened: root.run(() => PhoneBridge.openApp())
            }

            ControlTile {
                width: root.halfWidth
                height: root.cellHeight
                enabled: Microphone.available
                opacity: enabled ? 1 : 0.45

                TileTitle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    text: "Micrófono"
                }

                LineSlider {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 18
                    value: Microphone.shownVolume
                    leadingIcon: Microphone.silent ? Theme.systemIcons.micOff : Theme.systemIcons.mic
                    onMoved: value => Microphone.setVolume(value)
                }
            }
        }

        // Filas 4–5: accesos rápidos · No molestar
        Row {
            spacing: root.cellGap

            Item {
                width: root.halfWidth
                height: root.tallHeight

                Grid {
                    anchors.centerIn: parent
                    columns: 2
                    spacing: root.cellGap

                    ControlButton {
                        icon: Theme.systemIcons.darkMode
                        active: Appearance.dark
                        onClicked: Appearance.toggle()
                    }

                    ControlButton {
                        icon: Theme.systemIcons.stayAwake
                        active: StayAwake.active
                        onClicked: StayAwake.toggle()
                    }

                    ControlButton {
                        icon: Theme.systemIcons.screenshot
                        onClicked: root.run(() => QuickActions.screenshot())
                    }

                    ControlButton {
                        icon: Theme.systemIcons.colorPicker
                        onClicked: root.run(() => QuickActions.pickColor())
                    }
                }
            }

            ControlCard {
                width: root.halfWidth
                height: root.tallHeight
                icon: Theme.systemIcons.moon
                title: "No molestar"
                subtitle: DoNotDisturb.status
                active: DoNotDisturb.active
                onToggled: DoNotDisturb.toggle()
            }
        }

        // Pantalla
        ControlTile {
            width: root.fullWidth
            height: 68

            TileTitle {
                anchors.top: parent.top
                anchors.left: parent.left
                text: "Pantalla"
            }

            LineSlider {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 22
                value: Brightness.value
                leadingIcon: Theme.systemIcons.sunDim
                trailingIcon: Theme.systemIcons.sun
                onMoved: value => Brightness.setValue(value)
            }
        }

        // Sonido
        ControlTile {
            width: root.fullWidth
            height: 72

            TileTitle {
                anchors.top: parent.top
                anchors.left: parent.left
                text: "Sonido"
            }

            LineSlider {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 26
                value: Audio.muted ? 0 : Audio.volume
                leadingIcon: Theme.systemIcons.volume.low
                trailingIcon: Theme.systemIcons.volume.high
                actionIcon: Theme.systemIcons.audioOutput
                onMoved: value => Audio.setVolume(value)
                onActionClicked: root.page = "sound"
            }
        }
    }

    // ── Wi-Fi ───────────────────────────────────────────────
    PanelPage {
        visible: root.page === "wifi"
        title: "Wi-Fi"
        showSwitch: WifiControl.available
        switchOn: WifiControl.powered
        onBack: root.page = "home"
        onSwitchToggled: WifiControl.toggle()

        SectionLabel {
            visible: WifiControl.powered
            text: "Redes"
        }

        Repeater {
            model: WifiControl.powered ? WifiControl.networks : []

            ChoiceRow {
                required property var modelData

                contentColor: Theme.glass.content
                icon: Theme.systemIcons.wifi[modelData.level]
                text: modelData.name
                subtitle: modelData.detail
                trailingIcon: modelData.open ? "" : Theme.systemIcons.lock
                selected: modelData.connected
                onTriggered: WifiControl.choose(modelData.name)
            }
        }

        SectionLabel {
            visible: WifiControl.powered && WifiControl.networks.length === 0
            text: "Buscando redes…"
        }

        Label {
            visible: WifiControl.passwordNeededFor !== ""
            width: parent.width
            wrapMode: Text.WordWrap
            color: Theme.glass.content
            font.pixelSize: Theme.font.small
            topPadding: 6
            text: "«" + WifiControl.passwordNeededFor + "» pide contraseña. "
                  + "Conéctate una vez desde la configuración de red; "
                  + "después podrás hacerlo desde aquí."
        }

        Item { width: 1; height: 6 }

        PillButton {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: WifiControl.hasSettingsApp
            text: "Configuración de red…"
            onClicked: root.run(() => WifiControl.openSettings())
        }
    }

    // ── Bluetooth ───────────────────────────────────────────
    PanelPage {
        visible: root.page === "bluetooth"
        title: "Bluetooth"
        showSwitch: BluetoothControl.available
        switchOn: BluetoothControl.powered
        onBack: root.page = "home"
        onSwitchToggled: BluetoothControl.toggle()

        SectionLabel {
            visible: BluetoothControl.powered
            text: "Dispositivos"
        }

        Repeater {
            model: BluetoothControl.powered ? BluetoothControl.devices : []

            ChoiceRow {
                required property var modelData

                contentColor: Theme.glass.content
                icon: Theme.systemIcons.device[modelData.kind]
                text: modelData.name
                subtitle: modelData.detail
                selected: modelData.connected
                onTriggered: BluetoothControl.toggleDevice(modelData.address)
            }
        }

        SectionLabel {
            visible: BluetoothControl.powered && BluetoothControl.devices.length === 0
            text: "No hay dispositivos emparejados."
        }

        Item { width: 1; height: 6 }

        PillButton {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: BluetoothControl.hasSettingsApp
            text: "Configuración de Bluetooth…"
            onClicked: root.run(() => BluetoothControl.openSettings())
        }
    }

    // ── Sonido ──────────────────────────────────────────────
    PanelPage {
        visible: root.page === "sound"
        title: "Sonido"
        onBack: root.page = "home"

        SectionLabel {
            text: "Salida"
        }

        Repeater {
            model: Audio.outputs

            ChoiceRow {
                required property var modelData

                contentColor: Theme.glass.content
                icon: Theme.systemIcons.device[modelData.kind]
                text: modelData.label
                selected: modelData.selected
                onTriggered: Audio.selectOutput(modelData.id)
            }
        }

        Item { width: 1; height: 6 }

        PillButton {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Audio.hasSettingsApp
            text: "Configuración de sonido…"
            onClicked: root.run(() => Audio.openSettings())
        }
    }
}