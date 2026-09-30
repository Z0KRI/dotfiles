// ATOM: la silueta de la island. Solo dibuja; no sabe qué lleva dentro.
//
// El cuerpo va pegado al borde superior, con las dos esquinas de abajo
// redondeadas y, a los lados, dos esquinas INVERTIDAS —las "alas"— que lo
// funden con el borde de la pantalla.
//
// El item es más ancho que el cuerpo: `wing` píxeles de más a cada lado.

import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    property real bodyWidth: 200
    property real bodyHeight: 34
    property real wing: 14
    property real cornerRadius: 18
    property color fill: "black"

    implicitWidth: root.bodyWidth + root.wing * 2
    implicitHeight: root.bodyHeight

    width: implicitWidth
    height: implicitHeight

    // El radio no puede pasar de la mitad del cuerpo ni de su alto: si lo pasa,
    // la curva de un extremo empieza antes de que acabe la del otro, el
    // recorrido se cruza y sale un rectángulo.
    readonly property real r: Math.max(0, Math.min(root.cornerRadius,
                                                   root.bodyWidth / 2,
                                                   root.bodyHeight))

    // El renderizador de curvas antialiasea por su cuenta. Si aun así ves
    // escalera en las alas, cámbialo por layer.enabled + layer.samples: 4.
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.fill
        strokeWidth: 0
        strokeColor: "transparent"

        // Arranca en el filo exterior del ala izquierda, pegado arriba.
        startX: 0
        startY: 0

        // Ala izquierda: cuarto de círculo cóncavo, centrado FUERA del cuerpo.
        PathArc {
            x: root.wing
            y: root.wing
            radiusX: root.wing
            radiusY: root.wing
            direction: PathArc.Clockwise
        }

        // Lado izquierdo.
        PathLine {
            x: root.wing
            y: root.bodyHeight - root.r
        }

        // Esquina inferior izquierda.
        PathArc {
            x: root.wing + root.r
            y: root.bodyHeight
            radiusX: root.r
            radiusY: root.r
            direction: PathArc.Counterclockwise
        }

        // Fondo.
        PathLine {
            x: root.wing + root.bodyWidth - root.r
            y: root.bodyHeight
        }

        // Esquina inferior derecha.
        PathArc {
            x: root.wing + root.bodyWidth
            y: root.bodyHeight - root.r
            radiusX: root.r
            radiusY: root.r
            direction: PathArc.Counterclockwise
        }

        // Lado derecho.
        PathLine {
            x: root.wing + root.bodyWidth
            y: root.wing
        }

        // Ala derecha.
        PathArc {
            x: root.wing * 2 + root.bodyWidth
            y: 0
            radiusX: root.wing
            radiusY: root.wing
            direction: PathArc.Clockwise
        }

        // El techo, de vuelta al inicio.
        PathLine {
            x: 0
            y: 0
        }
    }
}