// MOLÉCULA: botón de la barra. Círculo si solo lleva un ícono,
// cápsula si lleva texto. Estados: normal, hover y activo.
// Usa handlers (no MouseArea) para convivir con el detector de la barra.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Surface {
    id: root

    default property alias content: row.data

    // Los elementos que solo informan pueden apagarlo.
    property bool interactive: true

    // Seleccionado. Ej.: la lupa mientras el launcher está abierto.
    property bool active: false

    // Hacia afuera, por si algo lo necesita (tooltips más adelante).
    readonly property bool hovered: hover.hovered

    signal clicked()

    // Rueda del mouse: +1 hacia arriba, -1 hacia abajo.
    signal scrolled(int steps)

    implicitHeight: Theme.glass.itemSize
    // Nunca más angosto que alto: con un ícono es círculo; con texto, cápsula.
    implicitWidth: Math.max(implicitHeight, row.implicitWidth + Theme.spacing.md * 2)
    radius: height / 2

    // Prioridad: activo gana a hover. "Apagado" es alfa 0 del mismo color.
    color: {
        if (root.active)
            return Theme.glass.active;

        if (root.interactive && hover.hovered)
            return Theme.glass.hover;

        return Qt.alpha(Theme.glass.hover, 0);
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.motion.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.motion.spring
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacing.sm
    }

    HoverHandler {
        id: hover
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        enabled: root.interactive
        onTapped: root.clicked()
    }

    WheelHandler {
        // No modifica nada por su cuenta: solo avisa.
        target: null
        enabled: root.interactive

        onWheel: event => {
            const delta = event.angleDelta.y;
            if (delta !== 0)
                root.scrolled(delta > 0 ? 1 : -1);
        }
    }
}