// Ajustes › iPhone: el puente de BlueFerry. Encenderlo o apagarlo, ver si
// tu iPhone está conectado, y si la isla puede responder mensajes.
//
// Dos piezas distintas, y por eso dos dominios:
//   PhoneService  el servicio de systemd (blueferry.service): ¿corre?
//   Phone         el puente de mensajes (blueferry-quickshell-bridge):
//                 ¿puedo responder desde la isla?

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.phone

SettingsPage {
    id: root

    // El estado del servicio se consulta a systemd cada 5 s solo mientras
    // alguien mira: el mismo contador que usa el Centro de control.
    Component.onCompleted: PhoneService.watch()
    Component.onDestruction: PhoneService.unwatch()

    SettingsHero {
        icon: Theme.systemIcons.device.phone
        tint: "#30b94d"
        title: "iPhone"
        description: "Las notificaciones de tu iPhone llegan a la isla, y desde ahí "
                     + "respondes mensajes. Funciona con BlueFerry, por Bluetooth."
        showSwitch: true
        checked: PhoneService.active
        onToggled: PhoneService.toggle()
    }

    SettingsGroup {
        SettingsRow {
            glyph: Theme.systemIcons.device.phone
            title: "Estado"
            value: PhoneService.status
        }

        SettingsRow {
            visible: PhoneService.battery >= 0
            glyph: Theme.systemIcons.battery
            title: "Batería del iPhone"
            value: Math.round(PhoneService.battery * 100) + " %"
        }

        SettingsRow {
            glyph: Theme.systemIcons.phoneCall
            title: "Responder desde la isla"
            subtitle: Phone.available
                ? "Escribe la respuesta en la notificación desplegada."
                : "Necesita blueferry-quickshell-bridge (paquete blueferry-quickshell)."
            value: Phone.available ? "Disponible" : "No disponible"
        }
    }

    Item {
        width: parent.width
        height: openApp.height

        PushButton {
            id: openApp

            anchors.right: parent.right
            text: "Abrir BlueFerry…"
            onClicked: PhoneService.openApp()
        }
    }
}
