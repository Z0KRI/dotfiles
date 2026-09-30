// Menú del reloj: fecha completa, calendario del mes
// y acceso directo a la app de calendario.

import QtQuick
import Quickshell
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.core.components.templates
import qs.domain.time

DropdownWindow {
    id: root

    required property Item anchorItem
    anchor.item: root.anchorItem

    // El reloj está a la derecha: el menú crece hacia la izquierda.
    alignRight: true
    padding: 10
    menuWidth: calendar.implicitWidth + root.padding * 2

    // Cada vez que se abre, vuelve al mes actual.
    onVisibleChanged: {
        if (root.visible)
            calendar.showToday();
    }

    Label {
        width: parent.width
        text: Clock.longDate
        font.weight: Font.Bold
        elide: Text.ElideRight
        bottomPadding: 8
    }

    CalendarView {
        id: calendar
        locale: Clock.locale
        today: Clock.now
    }

    Separator {
        visible: Clock.hasCalendarApp
    }

    MenuItem {
        visible: Clock.hasCalendarApp
        icon: ""   // Lucide: calendar
        text: "Abrir Calendario"
        onTriggered: root.run(() => Clock.openCalendarApp())
    }
}