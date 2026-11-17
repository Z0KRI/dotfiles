// ORGANISMO: una lista con tope de alto, para dentro de un cajón.
//
// Si las filas caben, mide lo que miden y no pasa nada. Si no caben, se queda
// en `maxHeight` y se desplaza con la rueda (o arrastrando). Así el cajón deja
// de crecer con la lista: 30 redes Wi-Fi ya no lo estiran hasta el piso.
//
// Es un Item que ENVUELVE al Flickable, igual que SettingsPage: lo que se
// declara dentro de un Flickable va a su contenido y se desplaza con él, y la
// barra tiene que quedarse quieta.
//
// Un Flickable tiene dos tamaños, y esa es toda la idea:
//   height         la ventanita por la que miras   (aquí, hasta maxHeight)
//   contentHeight  todo lo que hay detrás          (aquí, la columna entera)

import QtQuick
import qs.core.theme

Item {
    id: root

    default property alias content: column.data
    property alias spacing: column.spacing

    property int maxHeight: Theme.frame.drawerMaxList
    property color contentColor: Theme.glass.content

    width: parent ? parent.width : implicitWidth
    implicitWidth: 240
    implicitHeight: Math.min(column.implicitHeight, root.maxHeight)

    // Al volver a la página, la lista empieza arriba.
    onVisibleChanged: {
        if (root.visible)
            flick.contentY = 0;
    }

    Flickable {
        id: flick

        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        // Lo que no cabe se recorta en vez de dibujarse encima de lo de abajo.
        clip: true

        // Si todo cabe no hay nada que arrastrar.
        interactive: contentHeight > height

        Column {
            id: column

            width: flick.width
            spacing: 2
        }
    }

    // Barra fina, como la de Ajustes: solo se ve mientras te desplazas.
    Rectangle {
        visible: flick.contentHeight > flick.height
        x: root.width - width
        y: flick.visibleArea.yPosition * flick.height
        width: 3
        height: Math.max(24, flick.visibleArea.heightRatio * flick.height)
        radius: width / 2
        color: root.contentColor
        opacity: flick.moving ? 0.45 : 0

        Behavior on opacity {
            NumberAnimation { duration: flick.moving ? 80 : 600 }
        }
    }
}
