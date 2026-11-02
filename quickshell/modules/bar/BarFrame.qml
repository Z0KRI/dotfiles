// El marco de UNA pantalla: qué va en cada pestaña, qué cajón está abierto
// y qué lleva cada uno. La figura, sus animaciones y el ratón los pone el
// template (FrameWindow); aquí se decide el contenido.
//
//   pestaña izquierda   logo de Arch (menú del sistema) · app activa
//   pestaña derecha     Spotlight · Centro de control · reloj · notificaciones
//   cajón derecho       Centro de control o calendario, desde la pestaña
//   cajón izquierdo     menú del sistema, desde el borde, a media pantalla
//   panel lateral       notificaciones: el borde derecho, de arriba abajo

import QtQuick
import Quickshell
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.templates
import qs.domain.launcher
import qs.domain.desktop
import qs.domain.island
import qs.domain.notifications
import qs.domain.time

FrameWindow {
    id: root

    framed: BarVisibility.framed(root.screen)
    autoHide: BarVisibility.autoHide(root.screen)
    aboveFullscreen: BarVisibility.aboveFullscreen(root.screen)
    solid: BarVisibility.solid(root.screen)

    // ── El hueco de la isla ───────────────────────────────────────────
    //
    // La isla cuelga del marco, en su propia ventana. En pantalla completa
    // el marco sube a la capa overlay y le queda en la misma capa; restarle
    // su hueco es lo que hace que el ratón le llegue sin depender de quién
    // quede encima.
    //
    // Solo en la pantalla donde la isla se está dibujando: hay un marco por
    // monitor y un solo rectángulo.
    readonly property bool islandHere: IslandState.open
        && IslandState.screenName === root.screen.name

    cutout: root.islandHere ? IslandState.bodyRect : Qt.rect(0, 0, 0, 0)

    // ── Los cajones ───────────────────────────────────────────────────
    //
    // Uno a la vez: "", "system", "control" o "clock". Abrir otro cierra el
    // que estaba; si los dos son de la derecha, el cajón no se cierra: cambia
    // de forma hacia el nuevo.
    property string drawer: ""

    // El último de la derecha. Mientras el cajón se cierra, se sigue
    // dibujando el que estaba (igual que `drawn` en la isla).
    property string rightShown: ""

    function toggle(name): void {
        root.drawer = root.drawer === name ? "" : name;
    }

    // El Centro de control y el calendario salen del mismo lado que las
    // notificaciones, y la pestaña se disuelve en el panel: uno a la vez.
    onDrawerChanged: {
        if (root.drawer === "control" || root.drawer === "clock") {
            root.rightShown = root.drawer;
            if (NotificationCenter.isOpenOn(root.screen.name))
                NotificationCenter.close();
        }
    }

    notificationsOpen: NotificationCenter.isOpenOn(root.screen.name)

    onNotificationsOpenChanged: {
        if (root.notificationsOpen && (root.drawer === "control" || root.drawer === "clock"))
            root.drawer = "";
    }

    onDismissed: root.drawer = ""

    rightPanelOpen: root.drawer === "control" || root.drawer === "clock"
    sidePanelOpen: root.drawer === "system"

    // Lo que mide cada uno lo dice su contenido.
    rightPanelWidth: rightLoader.item ? rightLoader.item.implicitWidth : 0
    rightPanelHeight: rightLoader.item ? rightLoader.item.implicitHeight : 0
    sidePanelWidth: sideLoader.item ? sideLoader.item.implicitWidth : 0
    sidePanelHeight: sideLoader.item ? sideLoader.item.implicitHeight : 0

    // Íconos y texto sobre el negro: blancos en ambos modos.
    readonly property color iconColor: Theme.glass.content
    readonly property int iconSize: 14

    // ── Pestaña izquierda ─────────────────────────────────────────────
    leftTab: Row {
        spacing: Theme.glass.padding

        BarItem {
            active: root.drawer === "system"
            onClicked: root.toggle("system")

            Icon {
                icon: Theme.systemIcons.arch.icon
                ink: Theme.systemIcons.arch.ink
                color: root.iconColor
                font.family: Theme.systemIcons.arch.family
            }
        }

        // App activa de ESTE monitor, con morphing al cambiar. La pestaña
        // se estira y se encoge con el nombre. Se puede ocultar en Ajustes ›
        // Barra de menús.
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

    // ── Pestaña derecha ───────────────────────────────────────────────
    rightTab: Row {
        spacing: Theme.glass.padding

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

        BarItem {
            active: root.drawer === "control"
            onClicked: root.toggle("control")

            Icon {
                icon: Theme.systemIcons.controlCenter
                size: root.iconSize
                color: root.iconColor
                font.family: Theme.font.icon
            }
        }

        // Reloj: fecha corta y hora. Al hacer clic, calendario.
        BarItem {
            active: root.drawer === "clock"
            onClicked: root.toggle("clock")

            Label {
                text: Clock.label
                color: root.iconColor
            }
        }

        // Notificaciones. El punto azul: llegó algo desde la última vez que
        // abriste el panel.
        BarItem {
            active: root.notificationsOpen
            onClicked: NotificationCenter.toggle(root.screen.name)

            Icon {
                icon: Theme.systemIcons.bell
                size: root.iconSize
                color: root.iconColor
                font.family: Theme.font.icon

                Rectangle {
                    x: parent.width - 3
                    y: -2
                    width: 6
                    height: 6
                    radius: 3
                    color: Theme.colors.accent
                    visible: NotificationCenter.unread
                }
            }
        }
    }

    // ── Los cajones, solo mientras se ven ─────────────────────────────
    //
    // Igual que antes con los menús: existen mientras están abiertos (y lo
    // que dura cerrarse). Hay un marco por monitor; sin esto serían el Centro
    // de control con sus cinco páginas, el calendario y el menú esperando en
    // memoria en cada pantalla, todo el día.
    rightPanel: Loader {
        id: rightLoader

        active: root.rightPanelPresent && root.rightShown !== ""
        sourceComponent: root.rightShown === "clock" ? clockMenu : controlCenter
    }

    sidePanel: Loader {
        id: sideLoader

        active: root.sidePanelPresent
        sourceComponent: systemMenu
    }

    // El panel de notificaciones también existe solo mientras se ve.
    notificationPanel: Loader {
        anchors.fill: parent
        active: root.notificationsPresent

        sourceComponent: NotificationPanel {
            // Tocaste una que abrió su app: el panel se va, como en macOS.
            onOpened: NotificationCenter.close()
        }
    }

    Component {
        id: controlCenter

        ControlCenter {
            open: root.drawer === "control"
            onCloseRequested: root.drawer = ""
        }
    }

    Component {
        id: clockMenu

        ClockMenu {
            open: root.drawer === "clock"
            onCloseRequested: root.drawer = ""
        }
    }

    Component {
        id: systemMenu

        SystemMenu {
            open: root.drawer === "system"
            onCloseRequested: root.drawer = ""
        }
    }
}
