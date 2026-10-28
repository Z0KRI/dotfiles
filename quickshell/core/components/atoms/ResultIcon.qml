// ÁTOMO: el ícono de un resultado de Spotlight. Tres intentos, en orden:
//
//   1. image     una miniatura (las fotos de tu carpeta). Se carga en segundo
//                plano y a tamaño de ícono: la foto de 12 MB no se decodifica
//                entera para dibujar 34 píxeles.
//   2. iconName  un ícono del tema por nombre ("firefox", "folder",
//                "application-pdf"), como el Icon= de un .desktop.
//   3. glyph     si no hubo nada de lo anterior, un glifo de Lucide sobre un
//                cuadrito. Por defecto la ardilla de siempre.
//
// Mide 28 si nadie le dice otra cosa; quien lo usa le da width y height.
// tileColor y glyphColor son los del cuadrito de respaldo: sobre vidrio van
// en blanco translúcido, sobre fondo claro en los colores del tema.

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.core.theme

Item {
    id: root

    property string iconName: ""
    property string image: ""
    property string glyph: Theme.systemIcons.squirrel
    property color tileColor: Theme.colors.neutral
    property color glyphColor: Theme.colors.accent

    readonly property string resolvedPath: root.iconName !== "" ? Quickshell.iconPath(root.iconName, true) : ""
    readonly property bool showsImage: root.image !== "" && thumbnail.status !== Image.Error

    implicitWidth: 28
    implicitHeight: 28

    Image {
        id: thumbnail

        anchors.fill: parent
        visible: root.showsImage
        source: root.image
        asynchronous: true
        // Al doble: se ve nítida en pantallas con escala 2.
        sourceSize.width: root.width * 2
        sourceSize.height: root.height * 2
        fillMode: Image.PreserveAspectFit
    }

    IconImage {
        anchors.fill: parent
        visible: !root.showsImage && root.resolvedPath !== ""
        source: root.showsImage ? "" : root.resolvedPath
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.showsImage && root.resolvedPath === ""
        // Proporcional: a 34 px las esquinas de 8 se ven casi cuadradas.
        radius: Math.round(root.height * 0.26)
        color: root.tileColor

        Icon {
            anchors.centerIn: parent
            icon: root.glyph
            size: Math.round(parent.height * 0.55)
            color: root.glyphColor
        }
    }
}
