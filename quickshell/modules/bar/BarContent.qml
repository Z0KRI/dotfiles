// Lo que va dentro de UNA barra. Declara su propia altura.

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.launcher
import qs.domain.desktop
import qs.domain.time
import qs.domain.audio

Item {
    id: root

    required property var screen
    property bool solid: false

    // Hacia afuera: hay un menú abierto, la barra no debe esconderse.
    readonly property bool popupOpen: systemMenu.visible
                                      || soundMenu.visible
                                      || clockMenu.visible

    // Márgenes: flotando, un poco de aire arriba; sólida, lo mínimo.
    readonly property int topGap: root.solid ? 2 : 6
    readonly property int bottomGap: root.solid ? 2 : 1

    readonly property color iconColor: Theme.colors.base100
    readonly property int iconSize: 14

    implicitHeight: Math.max(leftGroup.implicitHeight, rightGroup.implicitHeight)
                    + root.topGap + root.bottomGap

    BarGroup {
        id: leftGroup

        flat: root.solid
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.top: parent.top
        anchors.topMargin: root.topGap

        BarItem {
            id: archButton

            active: systemMenu.visible
            onClicked: systemMenu.toggle()

            Icon {
                icon: "󰣇"
                size: 20
                color: root.iconColor
                font.family: Theme.font.iconNerd
            }
        }

        // App activa de ESTE monitor, con morphing al cambiar.
        BarItem {
            interactive: false

            MorphLabel {
                text: ActiveWindow.nameFor(root.screen)
                color: root.iconColor
                weight: ActiveWindow.isEmpty(root.screen) ? Font.Normal : Font.ExtraBold
            }
        }
    }

    BarGroup {
        id: rightGroup

        flat: root.solid
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.top: parent.top
        anchors.topMargin: root.topGap

        // Sound
        BarItem {
            id: soundButton

            active: soundMenu.visible
            onClicked: soundMenu.toggle()
            onScrolled: steps => Audio.nudge(steps)

            Icon {
                icon: Theme.systemIcons.volume[Audio.level]
                size: root.iconSize
                color: root.iconColor
                font.family: Theme.font.icon
            }
        }

        // Spotlight
        BarItem {
            active: LauncherControl.shown
            onClicked: LauncherControl.toggle()

            Icon {
                icon: ""
                size: root.iconSize
                color: root.iconColor
                font.family: Theme.font.icon
            }
        }

        // Clock
        BarItem {
            id: clockButton

            active: clockMenu.visible
            onClicked: clockMenu.toggle()

            Label {
                text: Clock.label
                color: root.iconColor
            }
        }
    }

    SystemMenu {
        id: systemMenu
        anchorItem: archButton
    }

    SoundMenu {
        id: soundMenu
        anchorItem: soundButton
    }

    ClockMenu {
        id: clockMenu
        anchorItem: clockButton
    }
}