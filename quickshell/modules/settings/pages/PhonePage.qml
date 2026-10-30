// Ajustes › iPhone: el puente de BlueFerry. Encenderlo o apagarlo, ver si
// tu iPhone está conectado, y si la isla puede responder mensajes.
//
// Dos piezas distintas, y por eso dos dominios:
//   PhoneService  el servicio de systemd (blueferry.service): ¿corre?
//   Phone         el puente de mensajes (blueferry-quickshell-bridge):
//                 ¿puedo responder desde la isla?

import QtQuick
import qs.core.theme
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.phone

SettingsPage {
    id: root

    // El estado del servicio se consulta a systemd cada 5 s solo mientras
    // alguien mira: el mismo contador que usa el Centro de control. Lo de las
    // llamadas se le pregunta a BlueFerry una vez, al abrir.
    Component.onCompleted: {
        PhoneService.watch();
        if (Phone.available && PhoneService.active)
            Phone.refreshStatus();
    }
    Component.onDestruction: PhoneService.unwatch()

    readonly property var callStates: ({
        disabled: "Apagadas",
        unavailable: "oFono no está corriendo",
        searching: "Buscando el iPhone",
        connecting: "Conectando",
        ready: "Listas",
        bluez_conflict: "Bluetooth tiene el canal (falta -P hfp)"
    })

    // Qué hacer en cada estado que no es "Listas".
    readonly property var callFixes: ({
        disabled: "Para contestar aquí las llamadas normales: ./install.sh --calls",
        unavailable: "Arráncalo con ./install.sh --calls.",
        searching: "Reinicia oFono después de WirePlumber: sudo systemctl restart ofono",
        connecting: "Espera unos segundos con el iPhone conectado.",
        ready: "Las llamadas normales se contestan desde la isla; hablas por la PC.",
        bluez_conflict: "Actualiza BlueFerry: ./install.sh --blueferry --calls"
    })

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
            glyph: Theme.batteryIcon(PhoneService.battery, false)
            title: "Batería del iPhone"
            value: Math.round(PhoneService.battery * 100) + " %"
        }

        SettingsRow {
            glyph: Theme.systemIcons.phoneCall
            title: "Responder mensajes desde la isla"
            subtitle: Phone.available
                ? "Escribe la respuesta en la notificación desplegada."
                : "Necesita blueferry-quickshell-bridge (viene en el paquete blueferry-backend)."
            value: Phone.available ? "Disponible" : "No disponible"
        }
    }

    SettingsGroup {
        visible: Phone.available && PhoneService.active
        header: "Llamadas"
        footer: {
            if (Phone.settingsError !== "")
                return "BlueFerry no respondió: " + Phone.settingsError;
            return "Con los botones del iPhone contestas EN el iPhone: hablas por él o por "
                 + "tus AirPods. Las llamadas normales (app Teléfono) llegan sin esos "
                 + "botones: esas se contestan aquí con el audio de las llamadas en la PC "
                 + "(./install.sh --calls, experimental).";
        }

        ToggleRow {
            glyph: Theme.systemIcons.phoneCall
            title: "Contestar desde la isla"
            subtitle: {
                if (!Phone.callButtons)
                    return "Las llamadas de apps (WhatsApp y otras) llegan con Contestar y Rechazar.";
                if (Phone.notificationPolicy !== "all")
                    return "Inactivo: las llamadas solo llegan con todas las notificaciones del iPhone.";
                if (!Phone.contentShown)
                    return "Inactivo: BlueFerry oculta el contenido de las notificaciones.";
                return "Las llamadas de apps (WhatsApp y otras) llegan con Contestar y Rechazar.";
            }
            checked: Phone.callButtons
            onToggled: Phone.setCallButtons(!Phone.callButtons)
        }

        // La llamada es una notificación más del iPhone: con "solo mensajes"
        // no llega, y sin ella no hay botones.
        SettingsRow {
            visible: Phone.callButtons && Phone.statusKnown && Phone.notificationPolicy !== "all"
            glyph: Theme.systemIcons.bell
            title: "Notificaciones del iPhone"
            subtitle: "Ahora llegan solo algunas: la de la llamada no."

            PushButton {
                text: "Mostrar todas"
                onClicked: Phone.showAllNotifications()
            }
        }

        SettingsRow {
            glyph: Theme.systemIcons.audioOutput
            title: "Audio de las llamadas en la PC"
            subtitle: Phone.statusKnown
                ? (root.callFixes[Phone.pcCalls ? Phone.pcCallsState : "disabled"] ?? "")
                : ""
            value: Phone.statusKnown
                ? (Phone.pcCalls ? (root.callStates[Phone.pcCallsState] ?? Phone.pcCallsState) : "Apagado")
                : "…"
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
