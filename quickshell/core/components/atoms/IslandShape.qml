// ATOM: la silueta del notch. Solo dibuja; no sabe qué lleva dentro.
//
// Es el trazado de Boring Notch, portado tal cual. Dos radios distintos y dos
// papeles distintos:
//
//  - `topRadius` son las dos esquinas INVERTIDAS de arriba, las que funden la
//    forma con el borde de la pantalla. Van por DENTRO del item.
//  - `bottomRadius` son las dos esquinas normales de abajo.
//
// Y las cuatro son curvas cuadráticas con el punto de control en la esquina,
// no arcos de círculo. Se nota: un arco entra y sale perpendicular al borde y
// deja un quiebre; la cuadrática llega tangente y la unión no se ve.
//
// El item mide el notch ENTERO, alas incluidas. El hueco útil para el
// contenido es `contentWidth`, que descuenta un ala a cada lado.

import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    property real topRadius: 6
    property real bottomRadius: 14
    property color fill: "black"

    readonly property real contentX: root.topRadius
    readonly property real contentWidth: Math.max(0, root.width - root.topRadius * 2)

    // El renderizador de curvas antialiasea por su cuenta. Si ves escalera en
    // las alas, cámbialo por layer.enabled + layer.samples: 4.
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.fill
        strokeColor: "transparent"
        strokeWidth: 0

        startX: 0
        startY: 0

        // Ala izquierda: cóncava, hacia dentro.
        PathQuad {
            x: root.topRadius
            y: root.topRadius
            controlX: root.topRadius
            controlY: 0
        }

        PathLine {
            x: root.topRadius
            y: root.height - root.bottomRadius
        }

        // Esquina inferior izquierda.
        PathQuad {
            x: root.topRadius + root.bottomRadius
            y: root.height
            controlX: root.topRadius
            controlY: root.height
        }

        PathLine {
            x: root.width - root.topRadius - root.bottomRadius
            y: root.height
        }

        // Esquina inferior derecha.
        PathQuad {
            x: root.width - root.topRadius
            y: root.height - root.bottomRadius
            controlX: root.width - root.topRadius
            controlY: root.height
        }

        PathLine {
            x: root.width - root.topRadius
            y: root.topRadius
        }

        // Ala derecha.
        PathQuad {
            x: root.width
            y: 0
            controlX: root.width - root.topRadius
            controlY: 0
        }

        // El techo, de vuelta al inicio.
        PathLine {
            x: 0
            y: 0
        }
    }
}