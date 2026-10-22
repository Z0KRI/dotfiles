// ÁTOMO: foto de perfil redonda. Si la imagen no existe o no carga, la
// inicial del nombre sobre un círculo gris, como en macOS.
//
// ClippingRectangle recorta la foto al círculo, pero no acepta degradado:
// por eso el fondo es un Rectangle hijo.

import QtQuick
import Quickshell.Widgets
import qs.core.theme

ClippingRectangle {
    id: root

    property string source: ""
    property string name: ""
    property int size: 36

    implicitWidth: root.size
    implicitHeight: root.size
    radius: root.size / 2
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#a1a1a6" }
            GradientStop { position: 1; color: "#7c7c80" }
        }
    }

    Label {
        anchors.centerIn: parent
        visible: photo.status !== Image.Ready
        text: root.name.length > 0 ? root.name.charAt(0).toUpperCase() : ""
        color: "white"
        font.pixelSize: Math.round(root.size * 0.45)
        font.weight: Font.DemiBold
    }

    Image {
        id: photo

        anchors.fill: parent
        source: root.source
        visible: status === Image.Ready
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: root.size * 2
        sourceSize.height: root.size * 2
    }
}
