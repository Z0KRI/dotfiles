// ÁTOMO: la figura del marco. Solo dibuja; no sabe qué lleva cada pestaña.
//
// Recibe la geometría ya calculada (la anima quien la usa) y la pasa a
// FramePath, que la convierte en un trazo SVG. Ver FramePath.qml para la
// idea de "un rectángulo con un hueco".

import QtQuick
import QtQuick.Shapes
import qs.core.utils

Shape {
    id: root

    property color fill: "black"

    property real band: 0
    property real side: 0
    property real topRadius: 0
    property real bottomRadius: 0

    // Pestaña izquierda: su orilla derecha y hasta dónde baja.
    property real leftX: 0
    property real leftDepth: 0
    property real leftWing: 0
    property real leftCorner: 0

    // Pestaña derecha: su orilla izquierda y hasta dónde baja.
    property real rightX: root.width
    property real rightDepth: 0
    property real rightWing: 0
    property real rightCorner: 0

    // Cajón del borde izquierdo: su orilla derecha (con `side` está
    // cerrado) y de dónde a dónde va en vertical.
    property real drawerX: 0
    property real drawerTop: 0
    property real drawerBottom: 0
    property real drawerWing: 0
    property real drawerCorner: 0

    // El panel de notificaciones: cuánto engorda el borde derecho (0 = cerrado).
    property real notificationsWidth: 0

    // El mismo renderizador que la isla: antialiasing propio en las curvas.
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.fill
        fillRule: ShapePath.OddEvenFill
        strokeColor: "transparent"
        strokeWidth: 0

        PathSvg {
            path: FramePath.build({
                width: root.width,
                height: root.height,
                band: root.band,
                side: root.side,
                topRadius: root.topRadius,
                bottomRadius: root.bottomRadius,
                left: {
                    x: root.leftX,
                    depth: root.leftDepth,
                    wing: root.leftWing,
                    corner: root.leftCorner
                },
                right: {
                    x: root.rightX,
                    depth: root.rightDepth,
                    wing: root.rightWing,
                    corner: root.rightCorner
                },
                drawer: {
                    x: Math.max(root.side, root.drawerX),
                    top: root.drawerTop,
                    bottom: root.drawerBottom,
                    wing: root.drawerWing,
                    corner: root.drawerCorner
                },
                notifications: root.notificationsWidth
            })
        }
    }
}
