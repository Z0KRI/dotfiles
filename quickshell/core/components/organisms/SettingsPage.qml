// ORGANISMO: el cuerpo de una sección de Ajustes. Se desplaza con la rueda,
// centra el contenido con un ancho máximo y aparece con un fundido corto.
//
// Es un Item que ENVUELVE al Flickable, no un Flickable directo: lo que se
// declara dentro de un Flickable va a su contenido y se desplaza con él. La
// barra de desplazamiento tiene que quedarse quieta, así que vive afuera.

import QtQuick
import qs.core.theme

Item {
    id: root

    default property alias content: column.data
    property alias spacing: column.spacing

    Flickable {
        id: flick

        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight + 48
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: column

            width: Math.min(flick.width - 48, Theme.window.contentWidth)
            x: Math.round((flick.width - width) / 2)
            y: 16
            spacing: 18
        }
    }

    // Barra fina como las de macOS: solo se ve mientras te desplazas.
    Rectangle {
        visible: flick.contentHeight > flick.height
        x: root.width - width - 3
        y: flick.visibleArea.yPosition * flick.height
        width: 6
        height: Math.max(24, flick.visibleArea.heightRatio * flick.height)
        radius: 3
        color: Theme.window.textMuted
        opacity: flick.moving ? 0.55 : 0

        Behavior on opacity {
            NumberAnimation { duration: flick.moving ? 80 : 600 }
        }
    }

    opacity: 0
    Component.onCompleted: appear.start()

    NumberAnimation {
        id: appear
        target: root
        property: "opacity"
        to: 1
        duration: 160
        easing.type: Easing.OutCubic
    }
}
