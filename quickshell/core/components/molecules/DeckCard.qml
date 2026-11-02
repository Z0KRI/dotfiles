// MOLÉCULA: una tarjeta vertical con su nombre debajo. Es la de Mission
// Control (un escritorio) y la del selector de fondos (un fondo).
//
//   la tarjeta   una imagen que la llena (recortada, no estirada) y, encima,
//                lo que pongas entre las llaves (las ventanas de un escritorio)
//   el nombre    una pastilla debajo
//
// Elegida (`chosen`): borde azul con un halo, y la pastilla en blanco con
// texto negro. No sabe qué es: solo avisa con `clicked`.
//
// (En este comentario no van llaves de verdad: el escáner de Quickshell deja
// de leer los import en la primera línea que tenga una.)

import QtQuick
import Quickshell.Widgets
import qs.core.theme
import qs.core.components.atoms

Item {
    id: root

    default property alias content: overlay.data

    property string source: ""
    property string label: ""
    property bool chosen: false

    signal clicked()

    readonly property bool hovered: hover.hovered

    implicitWidth: Theme.frame.cardWidth
    implicitHeight: Theme.frame.cardHeight + 10 + Theme.frame.cardLabel

    // El halo de la elegida: un borde azul tenue, 4 px por fuera.
    Rectangle {
        x: -4
        y: -4
        width: card.width + 8
        height: card.height + 8
        radius: Theme.frame.cardRadius + 4
        color: "transparent"
        border.width: 4
        border.color: Theme.frame.cardGlow
        visible: root.chosen
    }

    ClippingRectangle {
        id: card

        width: Theme.frame.cardWidth
        height: Theme.frame.cardHeight
        radius: Theme.frame.cardRadius
        color: "#0b1122"

        scale: tap.pressed ? 0.97 : 1

        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        Image {
            anchors.fill: parent
            source: root.source
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true

            // Solo lo que se ve, al doble de densidad: no el fondo entero de
            // 4K en memoria por cada tarjeta.
            sourceSize.width: Theme.frame.cardWidth * 2
            sourceSize.height: Theme.frame.cardHeight * 2
        }

        Item {
            id: overlay
            anchors.fill: parent
        }

        // El borde, encima de todo para que la imagen no lo tape.
        Rectangle {
            anchors.fill: parent
            radius: Theme.frame.cardRadius
            color: "transparent"
            border.width: root.chosen ? 2 : 1
            border.color: root.chosen ? Theme.frame.cardChosen
                        : hover.hovered ? Qt.rgba(1, 1, 1, 0.34)
                        : Qt.rgba(1, 1, 1, 0.14)
        }

        HoverHandler {
            id: hover
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            id: tap
            onTapped: root.clicked()
        }
    }

    // El nombre.
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: card.height + 10
        width: Math.min(Theme.frame.cardWidth, name.implicitWidth + 24)
        height: Theme.frame.cardLabel
        radius: height / 2
        color: root.chosen ? "#ffffff" : Qt.rgba(1, 1, 1, 0.10)

        Label {
            id: name

            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.label
            color: root.chosen ? "#000000" : Theme.glass.content
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }
}
