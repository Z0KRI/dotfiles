// ORGANISMO: mosaico del Centro de control: vidrio redondeado.
// Su tamaño lo pone quien lo usa (la cuadrícula); el contenido también.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Surface {
    id: root

    default property alias content: holder.data
    property int padding: 12

    radius: Theme.glass.tileRadius
    color: Theme.glass.tile
    border.width: 1
    border.color: Theme.glass.border

    Item {
        id: holder
        anchors.fill: parent
        anchors.margins: root.padding
    }
}