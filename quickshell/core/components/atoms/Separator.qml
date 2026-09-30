import QtQuick
import qs.core.theme

Item {
    id: root

    // En una lista vertical, ocupa todo el ancho por defecto.
    width: parent ? parent.width : implicitWidth
    implicitHeight: 9   // 4 de aire + 1 de línea + 4 de aire

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.spacing.sm
        anchors.rightMargin: Theme.spacing.sm
        anchors.verticalCenter: parent.verticalCenter

        height: 1
        color: Theme.glass.border
    }
}