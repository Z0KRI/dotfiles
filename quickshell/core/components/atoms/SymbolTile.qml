// ÁTOMO: el cuadrito de color con un ícono blanco de Ajustes (el de la barra
// lateral de macOS). Golden Gate les devolvió el color: cada sección se
// reconoce de reojo por su tinte.
//
// El relieve es un degradado de arriba hacia abajo. Se aclara con Qt.tint y no
// con Qt.lighter: lighter multiplica, y un negro multiplicado sigue negro.

import QtQuick
import qs.core.theme

Rectangle {
    id: root

    property string icon: ""
    property color tint: Theme.colors.accent
    property int size: 20
    property string fontFamily: Theme.font.icon
    property real iconScale: 0.6

    implicitWidth: root.size
    implicitHeight: root.size
    radius: Math.round(root.size * 0.24)

    gradient: Gradient {
        GradientStop { position: 0; color: Qt.tint(root.tint, Qt.rgba(1, 1, 1, 0.18)) }
        GradientStop { position: 1; color: root.tint }
    }

    // Un filo claro en modo oscuro: un cuadrito negro sobre la barra lateral
    // oscura (Apariencia, Isla) si no, se perdería.
    border.width: 1
    border.color: Theme.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)

    Icon {
        anchors.centerIn: parent
        icon: root.icon
        size: Math.round(root.size * root.iconScale)
        color: "white"
        font.family: root.fontFamily
    }
}
