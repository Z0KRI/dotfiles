// UTILIDAD: cuánto tiene que medir la isla para un DevicePeek, con el texto
// completo: los márgenes, el ícono, el título, el detalle y las alas de la
// isla. Entre el ancho mínimo de la isla y un tope; más allá, el título se
// corta con "…" en la vista.
//
// Va aparte de la vista porque el ocupante necesita el ancho ANTES de que la
// vista exista: la isla se dimensiona con él y luego carga lo de adentro.
//
// No es un singleton: cada ocupante lleva el suyo, con su propio texto.

import QtQuick
import qs.core.theme

QtObject {
    id: root

    property string title: ""
    property string detailText: ""
    property bool hasDetailIcon: false

    // Mide con la misma fuente que DevicePeek: el título en seminegrita.
    property TextMetrics _title: TextMetrics {
        font.family: Theme.font.ui
        font.pixelSize: Theme.island.peekText
        font.weight: Font.DemiBold
        text: root.title
    }

    property TextMetrics _detail: TextMetrics {
        font.family: Theme.font.ui
        font.pixelSize: Theme.island.peekText
        text: root.detailText
    }

    readonly property int width: {
        const detail = (root.hasDetailIcon ? Theme.island.peekGlyph + Theme.island.peekIconGap : 0)
                       + root._detail.advanceWidth;
        const inner = Theme.island.peekEdge + Theme.island.peekGlyph + Theme.island.peekGap
                      + root._title.advanceWidth + Theme.island.peekSplit
                      + detail + Theme.island.peekEdge;
        const total = Math.ceil(inner) + Theme.island.closedTopRadius * 2;   // las alas

        return Math.max(Theme.island.minWidth, Math.min(Theme.island.peekMaxWidth, total));
    }
}
