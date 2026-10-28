// ÁTOMO: una superficie de Liquid Glass (macOS 27). Es a Spotlight lo que
// Surface es al resto: el fondo, sin saber qué lleva dentro.
//
// De abajo hacia arriba (el orden en el archivo es el orden de pintado):
//
//   tinte    el color translúcido. El desenfoque NO está aquí: lo pinta
//            Hyprland detrás de la capa (ver Theme.liquid).
//   brillo   luz suave arriba, como el reflejo del techo en un vidrio.
//   contenido   lo que pongas entre las llaves, recortado a las esquinas.
//   borde    una línea oscura de 1 px: separa el vidrio de un fondo claro.
//   reflejo  un anillo de luz con degradado en diagonal: brillante arriba a
//            la izquierda y abajo a la derecha, casi nada en medio.
//
// El reflejo va ENCIMA del contenido a propósito: la fila elegida de una
// lista no debe tapar la luz del borde.
//
// ¿Por qué un Shape para el reflejo? El borde de un Rectangle es de un solo
// color; no acepta degradados. Un Shape sí se puede rellenar con un
// LinearGradient en cualquier dirección. Se dibujan dos rectángulos
// redondeados, uno dentro del otro, y con fillRule OddEvenFill se rellena
// solo lo que queda entre los dos: un anillo. Es la misma regla con la que
// una "O" tiene hueco en medio.

import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets
import qs.core.theme

Item {
    id: root

    default property alias content: holder.data

    property real radius: Theme.liquid.radius
    property color tint: Theme.liquid.panel
    property real rimWidth: 1
    property real edgeWidth: 1

    // El radio real nunca pasa de la mitad del lado corto: con radius
    // enorme, la barra queda como cápsula y no como algo roto.
    readonly property real shapeRadius: Math.min(root.radius, root.width / 2, root.height / 2)

    // Un rectángulo redondeado como trazo SVG: M (mover), H/V (línea
    // horizontal/vertical) y A (arco). Así el anillo cabe en una sola línea
    // en vez de dieciocho elementos PathLine y PathArc.
    function roundedRect(x, y, w, h, r): string {
        r = Math.max(0, Math.min(r, w / 2, h / 2));
        const arc = (ex, ey) => " A " + r + " " + r + " 0 0 1 " + ex + " " + ey;
        return "M " + (x + r) + " " + y
             + " H " + (x + w - r) + arc(x + w, y + r)
             + " V " + (y + h - r) + arc(x + w - r, y + h)
             + " H " + (x + r) + arc(x, y + h - r)
             + " V " + (y + r) + arc(x + r, y)
             + " Z ";
    }

    // 1. Tinte.
    Rectangle {
        anchors.fill: parent
        radius: root.shapeRadius
        color: root.tint
    }

    // 2. Brillo de arriba.
    Rectangle {
        anchors.fill: parent
        radius: root.shapeRadius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.liquid.sheen }
            GradientStop { position: 0.45; color: "transparent" }
        }
    }

    // 3. Contenido, recortado a las esquinas redondeadas. Un Item con
    // clip: true recortaría en cuadrado y la lista se saldría por las curvas.
    ClippingRectangle {
        id: holder

        anchors.fill: parent
        radius: root.shapeRadius
        color: "transparent"
    }

    // 4. Borde oscuro.
    Rectangle {
        anchors.fill: parent
        radius: root.shapeRadius
        color: "transparent"
        border.width: root.edgeWidth
        border.color: Theme.liquid.edge
    }

    // 5. Reflejo: el anillo, justo por dentro del borde oscuro.
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillRule: ShapePath.OddEvenFill
            strokeWidth: 0
            strokeColor: "transparent"

            fillGradient: LinearGradient {
                x1: 0
                y1: 0
                x2: root.width
                y2: root.height

                GradientStop { position: 0.0; color: Theme.liquid.highlight }
                GradientStop { position: 0.2; color: Qt.rgba(1, 1, 1, 0.14) }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.03) }
                GradientStop { position: 0.8; color: Qt.rgba(1, 1, 1, 0.10) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.32) }
            }

            PathSvg {
                readonly property real outer: root.edgeWidth
                readonly property real inner: root.edgeWidth + root.rimWidth

                path: root.roundedRect(outer, outer, root.width - outer * 2, root.height - outer * 2,
                                       root.shapeRadius - outer)
                    + root.roundedRect(inner, inner, root.width - inner * 2, root.height - inner * 2,
                                       root.shapeRadius - inner)
            }
        }
    }
}
