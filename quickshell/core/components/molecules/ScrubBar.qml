// MOLÉCULA: la línea de tiempo de lo que suena, como en macOS: una pista
// delgada, lo reproducido en blanco y una perilla. Si el reproductor deja
// (`seekable`), se arrastra o se hace clic para adelantar o regresar.
//
// Mientras arrastras, la perilla sigue al ratón y el valor real no la mueve;
// al soltar se avisa con `seeked` y la perilla se queda donde la dejaste
// hasta que llega la posición nueva. Si no, regresaría un instante al punto
// viejo antes de saltar.
//
// Un MouseArea y no un DragHandler: hay que saber dónde se apretó, no solo
// cuánto se movió. Sin `hoverEnabled`, como pide la isla.

import QtQuick
import qs.core.theme

Item {
    id: root

    property real value: 0          // de 0 a 1
    property bool seekable: false

    property color trackColor: Theme.island.track
    property color fillColor: Theme.island.fg

    signal seeked(real value)

    // Lo que se dibuja: el ratón mientras arrastras; lo que soltaste, hasta
    // que el reproductor lo confirme; si no, el valor de verdad.
    property real held: -1
    readonly property bool scrubbing: area.pressed
    readonly property real shown: Math.max(0, Math.min(1,
        root.scrubbing ? area.at : (root.held >= 0 ? root.held : root.value)))

    onValueChanged: root.held = -1

    implicitHeight: 12

    Rectangle {
        id: track

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        height: 3
        radius: height / 2
        color: root.trackColor

        Rectangle {
            width: track.width * root.shown
            height: parent.height
            radius: parent.radius
            color: root.fillColor

            // El reloj late una vez por segundo; la animación rellena el
            // hueco para que no avance a saltos. Arrastrando, va directo.
            Behavior on width {
                enabled: !root.scrubbing && root.held < 0
                NumberAnimation { duration: 1000; easing.type: Easing.Linear }
            }
        }
    }

    Rectangle {
        id: knob

        readonly property int size: root.scrubbing ? 12 : 9

        anchors.verticalCenter: parent.verticalCenter
        x: Math.round(track.width * root.shown - width / 2)

        width: knob.size
        height: knob.size
        radius: width / 2
        color: root.fillColor

        Behavior on x {
            enabled: !root.scrubbing && root.held < 0
            NumberAnimation { duration: 1000; easing.type: Easing.Linear }
        }

        Behavior on width {
            NumberAnimation { duration: 120 }
        }
    }

    MouseArea {
        id: area

        property real at: 0

        // Un poco más alto que la pista: atinarle a 3 px es difícil.
        anchors.fill: parent
        anchors.topMargin: -6
        anchors.bottomMargin: -6

        enabled: root.seekable
        cursorShape: root.seekable ? Qt.PointingHandCursor : Qt.ArrowCursor

        function place(x): void {
            area.at = Math.max(0, Math.min(1, x / Math.max(1, area.width)));
        }

        onPressed: mouse => area.place(mouse.x)
        onPositionChanged: mouse => area.place(mouse.x)
        onReleased: {
            root.held = area.at;
            root.seeked(area.at);
        }
    }
}
