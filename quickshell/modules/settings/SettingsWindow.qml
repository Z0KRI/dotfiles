// La ventana de Ajustes: barra lateral a la izquierda, y a la derecha la
// barra de herramientas (‹ › y el título) sobre la página de la sección.
//
// Cada página es un Component y el Loader carga solo la que se ve. Al cambiar
// de sección la anterior se destruye: por eso una página puede encender algo
// al nacer (buscar redes Wi-Fi) y apagarlo al morir, y no queda nada
// buscando en segundo plano.

import QtQuick
import Quickshell
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.core.components.templates
import qs.domain.settings
import qs.domain.desktop
import qs.modules.settings.pages

AppWindow {
    id: root

    title: "Ajustes"

    onCloseRequested: SettingsControl.close()

    // Cerrada desde Hyprland (SUPER + Q): avisar para que el LazyLoader la
    // descargue. Si no, la próxima vez "abrir" no haría nada.
    onClosed: SettingsControl.close()

    readonly property var current: SettingsCatalog.find(SettingsControl.section)
                                   ?? SettingsCatalog.find("about")

    readonly property var pages: ({
        wifi: wifiPage,
        bluetooth: bluetoothPage,
        iphone: phonePage,
        notifications: notificationsPage,
        sound: soundPage,
        appearance: appearancePage,
        displays: displaysPage,
        menubar: menuBarPage,
        island: islandPage,
        airpods: airPodsPage,
        spotlight: spotlightPage,
        about: aboutPage
    })

    sidebar: SettingsSidebar {
        anchors.fill: parent
    }

    toolbar: Item {
        anchors.fill: parent

        NavButtons {
            id: nav

            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter

            canGoBack: SettingsControl.canGoBack
            canGoForward: SettingsControl.canGoForward
            onBack: SettingsControl.back()
            onForward: SettingsControl.forward()
        }

        Label {
            anchors.left: nav.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter

            text: root.current.title
            color: Theme.window.text
            font.pixelSize: Theme.window.fontTitle
            font.weight: Font.Bold
        }
    }

    Loader {
        anchors.fill: parent
        sourceComponent: root.pages[root.current.id] ?? aboutPage
    }

    // "¿Conservar esta configuración de pantalla?" Vive en la ventana y no en
    // la página: si cambias de sección a media cuenta regresiva, sigue a la
    // vista (y si cierras Ajustes, el dominio igual revierte al llegar a 0).
    overlay: ConfirmSheet {
        anchors.fill: parent

        shown: Displays.confirming
        icon: Theme.systemIcons.monitorCheck
        tint: "#0a84ff"
        title: "¿Conservar esta configuración de pantalla?"
        message: "Si no la conservas, vuelve a la anterior en " + Displays.secondsLeft
                 + (Displays.secondsLeft === 1 ? " segundo." : " segundos.")
        rejectText: "Revertir"
        acceptText: "Conservar"
        onAccepted: Displays.keep()
        onRejected: Displays.revert()
    }

    Component { id: wifiPage; WifiPage {} }
    Component { id: bluetoothPage; BluetoothPage {} }
    Component { id: phonePage; PhonePage {} }
    Component { id: notificationsPage; NotificationsPage {} }
    Component { id: soundPage; SoundPage {} }
    Component { id: appearancePage; AppearancePage {} }
    Component { id: displaysPage; DisplaysPage {} }
    Component { id: menuBarPage; MenuBarPage {} }
    Component { id: islandPage; IslandPage {} }
    Component { id: airPodsPage; AirPodsPage {} }
    Component { id: spotlightPage; SpotlightPage {} }
    Component { id: aboutPage; AboutPage {} }
}
