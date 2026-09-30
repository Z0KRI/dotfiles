// CASO DE USO: cómo se muestran la fecha y la hora.
// Reglas:
//   - La barra habla español de México, sin importar el idioma del sistema.
//   - Hora de 12 horas con a.m./p.m., como macOS (o 24 horas si se cambia).
//   - El reloj abre la app de calendario del sistema, si existe.

pragma Singleton

import Quickshell
import qs.data.time
import qs.data.applications
import qs.domain.launcher

Singleton {
    id: root

    readonly property var locale: Qt.locale("es_MX")

    // true: "10:30 p.m." · false: "22:30"
    readonly property bool twelveHour: true

    readonly property date now: ClockRepository.now

    // Barra: "lun 28 sept  10:30 p.m."
    readonly property string label: {
        const time = root.twelveHour ? "h:mm ap" : "HH:mm";
        return root.now.toLocaleString(root.locale, "ddd d MMM  " + time);
    }

    // Encabezado del desplegable: "Lunes, 28 de septiembre de 2026"
    readonly property string longDate: root.capitalize(
        root.now.toLocaleDateString(root.locale, "dddd, d 'de' MMMM 'de' yyyy")
    )

    readonly property var calendarApp: AppRepository.entryFor("org.gnome.Calendar")
    readonly property bool hasCalendarApp: root.calendarApp !== null

    function openCalendarApp(): void {
        if (root.calendarApp)
            LaunchApp.execute(root.calendarApp);
    }

    function capitalize(text) {
        return text.charAt(0).toUpperCase() + text.slice(1);
    }
}