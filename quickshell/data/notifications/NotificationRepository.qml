pragma Singleton

// El único que habla con el bus de notificaciones.
//
// Dos cosas que hay que saber antes de tocar este archivo:
//
// 1. `notification.tracked = true` es LA línea. Sin ella el servidor descarta
//    la notificación en cuanto acaba el manejador: no falla, no avisa, deja de
//    existir. Todo el historial cuelga de ahí.
// 2. Las capacidades hay que anunciarlas o las aplicaciones ni las mandan.
//    Sin `actionsSupported` no llega un solo botón.
//
// Y un aviso: un singleton de QML se crea cuando alguien lo toca por primera
// vez. Si nadie referencia este, el servidor no se registra y se pierde todo lo
// que llegue. Hoy lo despierta el ocupante de la island al arrancar.

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    // Todo lo que el servidor mantiene vivo. Se poda solo: lo que se descarta
    // desaparece de aquí sin que nadie tenga que acordarse.
    readonly property var all: server.trackedNotifications
        ? server.trackedNotifications.values
        : []

    // Recién llegada, de esta sesión: merece un toast.
    signal arrived(var notification)

    // Reemitida tras recargar: al historial, pero sin toast.
    signal restored(var notification)

    NotificationServer {
        id: server

        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        bodySupported: true

        // En false a propósito. Si se anuncia, las aplicaciones mandan marcado
        // tipo Pango, y un Text que no entienda una etiqueta la pinta en crudo
        // en medio del mensaje. Se sube cuando la vista sepa renderizarlo.
        bodyMarkupSupported: false

        // Por defecto ya es true y así se queda: al recargar `qs` no se pierden
        // las que estén vivas. El precio es que las reemite todas, y por eso se
        // separan aquí abajo — si no, cada recarga te desfilan los toasts.
        keepOnReload: true

        onNotification: function (notification) {
            // TEMPORAL — quítalo cuando sepamos qué pasa con Zen.
            console.log("[island]",
                        "app:", JSON.stringify(notification.appName),
                        "entry:", JSON.stringify(notification.desktopEntry),
                        "summary:", JSON.stringify(notification.summary),
                        "lastGeneration:", notification.lastGeneration,
                        "transient:", notification.transient,
                        "acciones:", notification.actions.length);

            notification.tracked = true;

            if (notification.lastGeneration) {
                root.restored(notification);
                return;
            }

            root.arrived(notification);
        }
    }
}