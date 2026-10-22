// Lo que va dentro de UNA barra. Declara su propia altura.

import QtQuick
import Quickshell
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.launcher
import qs.domain.desktop
import qs.domain.time

Item {
    id: root

    required property var screen
    property bool solid: false

    // ── Los menús ───────────────────────────────────────────
    //
    // Existen solo mientras están abiertos (LazyLoader), igual que Spotlight y
    // Ajustes. Hay una barra por monitor: sin esto serían tres menús completos
    // por pantalla —el Centro de control con sus cuatro páginas— esperando en
    // memoria todo el día para abrirse de vez en cuando.
    property bool systemMenuOpen: false
    property bool controlCenterOpen: false
    property bool clockMenuOpen: false

    // Hacia afuera: hay un menú abierto, la barra no debe esconderse.
    readonly property bool popupOpen: root.systemMenuOpen
                                      || root.controlCenterOpen
                                      || root.clockMenuOpen

    // Abrir crea el menú; cerrar lo cierra (visible = false) y su
    // onVisibleChanged baja la bandera, que es lo que lo destruye. Cerrar
    // siempre por ahí garantiza que el menú se entere de que se cierra
    // (el Centro de control apaga la búsqueda de Wi-Fi al cerrarse).
    function toggleMenu(loader, isOpen, open): void {
        if (isOpen && loader.item)
            loader.item.close();
        else
            open();
    }

    // Márgenes: flotando, un poco de aire arriba; sólida, lo mínimo.
    readonly property int topGap: root.solid ? 2 : 6
    readonly property int bottomGap: root.solid ? 2 : 1

    // Íconos y texto sobre el vidrio: blancos en ambos modos.
    readonly property color iconColor: Theme.glass.content
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

            active: root.systemMenuOpen
            onClicked: root.toggleMenu(systemMenu, root.systemMenuOpen,
                                       () => root.systemMenuOpen = true)

            Icon {
                icon: Theme.systemIcons.arch.icon
                size: Theme.systemIcons.arch.size
                color: root.iconColor
                font.family: Theme.systemIcons.arch.family
            }
        }

        // App activa de ESTE monitor, con morphing al cambiar.
        // Se puede ocultar en Ajustes › Barra de menús.
        BarItem {
            visible: BarVisibility.showActiveApp
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

        BarItem {
            active: LauncherControl.shown
            onClicked: LauncherControl.toggle()

            Icon {
                icon: Theme.systemIcons.search
                size: root.iconSize
                color: root.iconColor
                font.family: Theme.font.icon
            }
        }

        // Centro de control.
        BarItem {
            id: controlCenterButton

            active: root.controlCenterOpen
            onClicked: root.toggleMenu(controlCenter, root.controlCenterOpen,
                                       () => root.controlCenterOpen = true)

            Icon {
                icon: Theme.systemIcons.controlCenter
                size: root.iconSize
                color: root.iconColor
                font.family: Theme.font.icon
            }
        }

        // Reloj: fecha corta y hora. Al hacer clic, calendario.
        BarItem {
            id: clockButton

            active: root.clockMenuOpen
            onClicked: root.toggleMenu(clockMenu, root.clockMenuOpen,
                                       () => root.clockMenuOpen = true)

            Label {
                text: Clock.label
                color: root.iconColor
            }
        }
    }

    // Se crean cerrados y se abren al terminar de crearse: así la animación
    // de entrada se ve (un Behavior no anima el valor inicial). Al cerrarse,
    // la bandera baja en el siguiente ciclo (callLater): primero el menú
    // termina de reaccionar a su propio cierre y después se destruye.
    LazyLoader {
        id: systemMenu
        active: root.systemMenuOpen

        SystemMenu {
            anchorItem: archButton
            visible: false
            Component.onCompleted: open()
            onVisibleChanged: if (!visible) Qt.callLater(() => root.systemMenuOpen = false)
        }
    }

    LazyLoader {
        id: controlCenter
        active: root.controlCenterOpen

        ControlCenter {
            anchorItem: controlCenterButton
            visible: false
            Component.onCompleted: open()
            onVisibleChanged: if (!visible) Qt.callLater(() => root.controlCenterOpen = false)
        }
    }

    LazyLoader {
        id: clockMenu
        active: root.clockMenuOpen

        ClockMenu {
            anchorItem: clockButton
            visible: false
            Component.onCompleted: open()
            onVisibleChanged: if (!visible) Qt.callLater(() => root.clockMenuOpen = false)
        }
    }
}