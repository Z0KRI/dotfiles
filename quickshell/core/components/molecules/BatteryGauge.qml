// MOLÉCULA: la batería de una pieza (un AirPod, el estuche…), como en el
// menú de macOS: el ícono de pila según el nivel, el porcentaje y debajo qué
// pieza es. Cargando, la pila lleva el rayo.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Column {
    id: root

    property string label: ""
    property real level: 0          // 0 a 1
    property bool charging: false

    // Blanco sobre vidrio en el Centro de control; el texto de la ventana en
    // Ajustes.
    property color contentColor: Theme.glass.content
    property color mutedColor: Theme.glass.contentMuted

    readonly property bool low: root.level <= 0.2 && !root.charging

    width: 64
    spacing: 2

    Icon {
        anchors.horizontalCenter: parent.horizontalCenter
        icon: {
            if (root.charging)
                return Theme.systemIcons.airpods.batteryCharging;
            if (root.level > 0.6)
                return Theme.systemIcons.airpods.batteryFull;
            if (root.level > 0.2)
                return Theme.systemIcons.airpods.batteryMedium;
            return Theme.systemIcons.airpods.batteryLow;
        }
        size: 18
        color: root.low ? Theme.colors.error : root.contentColor
    }

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Math.round(root.level * 100) + "%"
        color: root.contentColor
        font.pixelSize: Theme.font.small + 1
        font.weight: Font.DemiBold
    }

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.label
        color: root.mutedColor
        font.pixelSize: Theme.font.small
    }
}
