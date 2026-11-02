// Menú del reloj: fecha completa, calendario del mes
// y acceso directo a la app de calendario.
//
// Crece desde la pestaña derecha, como el Centro de control (BarFrame lo pone
// en el cajón `rightPanel`). Es más angosto que la pestaña: el cajón toma el
// ancho de la pestaña y el calendario va centrado.

import QtQuick
import Quickshell
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.core.components.templates
import qs.domain.time

FrameDrawer {
    id: root

    padding: 12
    topPadding: 6
    panelWidth: calendar.implicitWidth + root.padding * 2

    // Cada vez que se abre, vuelve al mes actual.
    onOpened: calendar.showToday()

    Label {
        width: parent.width
        text: Clock.longDate
        color: Theme.glass.content
        font.weight: Font.Bold
        elide: Text.ElideRight
        bottomPadding: 8
    }

    CalendarView {
        id: calendar
        locale: Clock.locale
        today: Clock.now
        contentColor: Theme.glass.content
    }

    Separator {
        visible: Clock.hasCalendarApp
    }

    MenuItem {
        visible: Clock.hasCalendarApp
        icon: Theme.systemIcons.calendar
        text: "Abrir Calendario"
        contentColor: Theme.glass.content
        onTriggered: root.run(() => Clock.openCalendarApp())
    }
}
