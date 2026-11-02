// ÁTOMO: la figura de un cajón que sale del borde de abajo del marco.
// Solo dibuja; no sabe qué lleva dentro (Spotlight, el portapapeles).
//
// Dos formas, según de dónde cuelga:
//   "bottom"   al centro del borde de abajo, con un ala cóncava a cada lado
//              (Spotlight: la isla, pero de abajo hacia arriba).
//   "corner"   en la esquina de abajo a la derecha, pegado a dos bordes, con
//              un ala hacia cada uno (el portapapeles).
//
// `bodyWidth` y `bodyHeight` son el cuerpo, sin alas: lo que el contenido
// tiene para dibujar. El item mide el cuerpo más las alas más `overlap`, los
// píxeles que el cajón se mete en el marco para que no quede costura. Quien
// lo usa lo pega al borde por ese lado (ver los cálculos en FramePath).

import QtQuick
import QtQuick.Shapes
import qs.core.utils

Shape {
    id: root

    property string attach: "bottom"
    property real bodyWidth: 0
    property real bodyHeight: 0
    property real wing: 14
    property real corner: 26
    property real overlap: 2
    property color fill: "black"

    // Dónde empieza el cuerpo dentro del item: las alas van a su izquierda
    // (y arriba, en la esquina).
    readonly property real bodyX: root.wing
    readonly property real bodyY: root.attach === "corner" ? root.wing : 0

    width: root.attach === "corner"
        ? root.wing + root.bodyWidth + root.overlap
        : root.bodyWidth + root.wing * 2
    height: root.attach === "corner"
        ? root.wing + Math.max(0, root.bodyHeight) + root.overlap
        : Math.max(0, root.bodyHeight) + root.overlap

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.fill
        strokeColor: "transparent"
        strokeWidth: 0

        PathSvg {
            path: root.attach === "corner"
                ? FramePath.cornerDrawer(root.bodyWidth, root.bodyHeight, root.wing, root.corner, root.overlap)
                : FramePath.bottomDrawer(root.bodyWidth, root.bodyHeight, root.wing, root.corner, root.overlap)
        }
    }
}
