pragma Singleton

// Las REGLAS de qué se hace con una notificación que llega, según Ajustes.
// Hay tres destinos, y `decide()` devuelve uno:
//
//   "show"  sale en la isla (y, si es de las que se guardan, al historial)
//   "keep"  no sale en la isla, pero se queda en el historial
//   "drop"  ni sale ni se guarda: se expira
//
// En orden:
//   1. Si la app tiene las notificaciones apagadas → drop.
//   2. Una llamada suena, salvo con No molestar sin "permitir llamadas".
//      Las llamadas no se guardan (BlueFerry las cierra al colgar).
//   3. Con No molestar o con los avisos apagados → keep (o drop si es de
//      las que no se guardan, como las transitorias del escritorio).
//   4. Todo lo demás → show.
//
// La lista de apps se arma sola: cada app que te notifica por primera vez se
// apunta, como en macOS. Se apunta con su nombre ya tipado (el de
// NotificationTypes), así "WhatsApp" del iPhone es la misma entrada siempre.

import QtQuick
import Quickshell
import qs.data.system

Singleton {
    id: root

    readonly property bool banners: PreferencesRepository.notificationBanners
    readonly property bool allowCalls: DoNotDisturb.allowCalls

    // [{ name, phone, allowed }], en orden alfabético.
    readonly property var apps: (PreferencesRepository.notificationApps ?? [])
        .slice()
        .sort((a, b) => String(a.name).localeCompare(String(b.name)))

    function entryFor(name) {
        return root.apps.find(app => app.name === name) ?? null;
    }

    function isAllowed(name): bool {
        const entry = root.entryFor(name);
        return entry ? entry.allowed !== false : true;
    }

    function decide(typed): string {
        if (!typed || typed.kind === "none")
            return "drop";

        if (typed.appName && !root.isAllowed(typed.appName))
            return "drop";

        if (typed.kind === "call")
            return DoNotDisturb.active && !root.allowCalls ? "drop" : "show";

        if (DoNotDisturb.active || !root.banners)
            return typed.keep ? "keep" : "drop";

        return "show";
    }

    // Apunta la app la primera vez que notifica. Si ya estaba, no escribe
    // nada: así no se reescribe el archivo de preferencias con cada mensaje.
    function remember(name, phone): void {
        if (!name || root.entryFor(name))
            return;

        PreferencesRepository.notificationApps = (PreferencesRepository.notificationApps ?? [])
            .concat([{ name: name, phone: !!phone, allowed: true }]);
    }

    function setAllowed(name, on): void {
        PreferencesRepository.notificationApps = (PreferencesRepository.notificationApps ?? [])
            .map(app => app.name === name ? Object.assign({}, app, { allowed: on }) : app);
    }

    // La quita de la lista. Si vuelve a notificar, se apunta de nuevo.
    function forget(name): void {
        PreferencesRepository.notificationApps = (PreferencesRepository.notificationApps ?? [])
            .filter(app => app.name !== name);
    }

    function setBanners(on): void {
        PreferencesRepository.notificationBanners = on;
    }

    function setAllowCalls(on): void {
        DoNotDisturb.setAllowCalls(on);
    }
}
