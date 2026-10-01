// ATOM: el símbolo de una notificación, con sus tres niveles de respaldo.
//
//   1. la imagen de ESTA notificación (la foto de quien escribe)
//   2. el icono de la aplicación, ya resuelto a una ruta que existe
//   3. un glifo de la fuente
//
// El glifo no es un adorno: es el único de los tres que no puede fallar. Un
// icono que no está en el tema hace que Qt pinte su cuadriculado magenta, y de
// ahí venían los recuadros rosas.
//
// No importa Theme a propósito, igual que IslandShape: la familia de la fuente
// entra desde fuera. Un atom que no sabe de tema se puede reutilizar en un
// sitio con otro tema.

import QtQuick
import Quickshell.Widgets

Item {
    id: root

    property string image: ""
    property string icon: ""
    property string glyph: ""
    property string fontFamily: ""
    property color color: "white"
    property real size: 24

    implicitWidth: root.size
    implicitHeight: root.size

    // El primero de los dos que tenga algo. Vacío significa "no hay imagen
    // que pintar", y entonces manda el glifo.
    readonly property string resolved: root.image.length > 0 ? root.image : root.icon

    IconImage {
        anchors.fill: parent
        source: root.resolved
        visible: root.resolved.length > 0
        asynchronous: true
    }

    Label {
        anchors.centerIn: parent
        visible: root.resolved.length === 0

        text: root.glyph
        color: root.color
        font.family: root.fontFamily
        font.pixelSize: Math.round(root.size * 0.82)
    }
}