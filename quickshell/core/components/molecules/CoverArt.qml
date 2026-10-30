// MOLÉCULA: una carátula. La imagen con sus esquinas redondeadas; si no hay
// —el reproductor no la manda, todavía no llega o no se pudo leer—, un
// cuadro gris con un glifo (`glyph`): la nota para música, la tele para un
// video. Cuando la imagen llega, aparece encima con un fundido.
//
// `glow`: detrás, la misma carátula muy difuminada asoma por los bordes con
// sus propios colores, como en Apple Music. Solo cuando de verdad hay imagen;
// el cuadro gris no brilla.
//
// `decodeSize`: a cuántos píxeles se decodifica. Al doble de lo que se ve
// (pantallas HiDPI), no al original: una carátula de 640×640 son 1.6 MB en
// memoria para pintar 20 px. Dos carátulas con la misma imagen y el mismo
// decodeSize comparten la copia de la caché de Qt.
//
// No sabe de MPRIS: recibe la imagen y el glifo.

import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.core.theme
import qs.core.components.atoms

Item {
    id: root

    property string source: ""
    property string glyph: Theme.systemIcons.cover.music
    property real radius: 4
    property int decodeSize: 64
    property int glyphSize: Math.round(root.width * 0.4)

    // El cuadro de cuando no hay imagen. Por defecto, los colores de la isla.
    property color color: Theme.island.track
    property color glyphColor: Theme.island.muted

    property bool glow: false
    property int glowRadius: 28       // cuánto se difumina, en px
    property real glowOpacity: 1

    readonly property bool ready: image.status === Image.Ready

    // ── el halo ───────────────────────────────────────────────────
    //
    // Va antes que la carátula para quedar debajo. Su fuente es una copia
    // escondida de la imagen, fuera del recorte (MultiEffect la quiere así,
    // con `visible: false`): misma imagen y mismo decodeSize, así que es la
    // MISMA copia en memoria, no otra. `autoPaddingEnabled` le da espacio
    // para salirse del cuadro.
    Image {
        id: glowSource

        anchors.fill: frame
        visible: false

        source: root.glow ? root.source : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        sourceSize.width: root.decodeSize
        sourceSize.height: root.decodeSize
    }

    MultiEffect {
        anchors.fill: frame
        visible: root.glow && glowSource.status === Image.Ready

        // Un poco más grande que la carátula: así asoma parejo por los cuatro
        // lados. Del mismo tamaño, el difuminado se queda casi todo debajo.
        scale: 1.05

        source: glowSource
        autoPaddingEnabled: true
        blurEnabled: true
        blur: 1
        blurMax: root.glowRadius
        saturation: 0.3

        // Aparece y se va con la carátula.
        opacity: root.glowOpacity * image.opacity
    }

    ClippingRectangle {
        id: frame

        anchors.fill: parent
        radius: root.radius
        color: root.color

        Icon {
            anchors.centerIn: parent
            visible: image.opacity < 1 && root.glyph !== ""
            icon: root.glyph
            size: root.glyphSize
            color: root.glyphColor
        }

        Image {
            id: image

            anchors.fill: parent
            source: root.source
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            sourceSize.width: root.decodeSize
            sourceSize.height: root.decodeSize

            opacity: root.ready ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
