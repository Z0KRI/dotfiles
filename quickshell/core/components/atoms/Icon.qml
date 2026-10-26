// ÁTOMO: un ícono de fuente (un glifo).
//
// Dos formas de darle tamaño:
//   size  el tamaño de la FUENTE (font.pixelSize). Sirve para Lucide, que es
//         una sola fuente que viene en tus dotfiles: mide igual en todos lados.
//   ink   el tamaño del DIBUJO, en píxeles. Para glifos de Nerd Font, como el
//         logo de Arch: el mismo glifo mide 15, 21 o 25 px a pixelSize 25
//         según qué variante lo pinte (Mono, normal/Propo o Symbols Mono), y
//         cuál le toca depende de las fuentes instaladas en cada máquina. Con
//         `ink` se mide el glifo que de verdad se va a pintar y se ajusta la
//         fuente para que el dibujo mida eso, sea cual sea la variante.

import QtQuick
import qs.core.theme

Text {
    id: root

    property string icon: ""
    property int size: 32
    property int ink: 0

    text: root.icon
    color: Theme.colors.baseContent

    font.family: Theme.font.icon
    font.pixelSize: root.inkPixelSize > 0 ? root.inkPixelSize : root.size

    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    // Se mide a 100 px con la misma familia. tightBoundingRect sigue el glifo
    // que se usa en realidad, incluido el de una fuente de respaldo.
    FontMetrics {
        id: probe
        font.family: root.font.family
        font.pixelSize: 100
    }

    readonly property real inkPixelSize: {
        if (root.ink <= 0 || root.icon === "")
            return 0;

        const height = probe.tightBoundingRect(root.icon).height;
        return height > 0 ? Math.round(root.ink * 100 / height) : 0;
    }
}
