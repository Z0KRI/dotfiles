// MOLÉCULA: texto que se transforma al cambiar, al estilo iOS.
// El texto viejo sube, se desenfoca y se desvanece; el nuevo entra
// desde abajo enfocándose, con rebote; el ancho sigue al texto nuevo.

import QtQuick
import QtQuick.Effects
import qs.core.theme
import qs.core.components.atoms

Item {
    id: root

    property string text: ""
    property int weight: Font.Normal

    // Color de ambas etiquetas. Si no se define, usa el de tu Label.
    property alias color: next.color

    // Cuántos píxeles viaja el texto al entrar y salir.
    property int travel: 8

    // Desenfoque durante la transición. Se puede apagar por instancia.
    property bool blurred: true
    property int blurRadius: 12

    implicitWidth: next.implicitWidth
    implicitHeight: next.implicitHeight

    // Recorta el texto en movimiento: efecto de "rodillo".
    clip: true

    // El ancho viaja con tu curva de rebote. La cápsula y la píldora
    // dependen de este ancho, así que se estiran solas.
    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme.motion.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.motion.spring
        }
    }

    // El texto que se va. Invisible hasta el primer cambio.
    Label {
        id: prev

        anchors.horizontalCenter: parent.horizontalCenter
        color: next.color
        opacity: 0

        // Capa solo mientras anima: desenfoque sin costo con el texto quieto.
        layer.enabled: root.blurred && transition.running
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: root.blurRadius
            // Mientras más transparente, más borroso.
            blur: 1 - prev.opacity
        }
    }

    // El texto que se muestra (y que llega en cada cambio).
    Label {
        id: next

        anchors.horizontalCenter: parent.horizontalCenter

        layer.enabled: root.blurred && transition.running
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: root.blurRadius
            // Entra borroso y se enfoca conforme aparece.
            blur: 1 - next.opacity
        }
    }

    // Toma la "foto" de lo que se veía, pone lo nuevo y anima.
    function morph(): void {
        if (next.text === root.text && next.font.weight === root.weight)
            return;

        prev.text = next.text;
        prev.font.weight = next.font.weight;

        next.text = root.text;
        next.font.weight = root.weight;

        transition.restart();
    }

    // Texto y peso suelen cambiar juntos; callLater los junta en una sola animación.
    onTextChanged: Qt.callLater(root.morph)
    onWeightChanged: Qt.callLater(root.morph)

    // Al crearse, el primer texto aparece sin animación.
    Component.onCompleted: {
        next.text = root.text;
        next.font.weight = root.weight;
    }

    ParallelAnimation {
        id: transition

        // Sale: sube, se encoge un poco y se desvanece rápido.
        NumberAnimation {
            target: prev; property: "y"
            from: 0; to: -root.travel
            duration: Theme.motion.duration
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: prev; property: "opacity"
            from: 1; to: 0
            duration: Theme.motion.duration * 0.6
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: prev; property: "scale"
            from: 1; to: 0.9
            duration: Theme.motion.duration
            easing.type: Easing.OutCubic
        }

        // Entra: sube desde abajo con rebote y aparece.
        NumberAnimation {
            target: next; property: "y"
            from: root.travel; to: 0
            duration: Theme.motion.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.motion.spring
        }
        NumberAnimation {
            target: next; property: "opacity"
            from: 0; to: 1
            duration: Theme.motion.duration
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: next; property: "scale"
            from: 0.9; to: 1
            duration: Theme.motion.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.motion.spring
        }
    }
}