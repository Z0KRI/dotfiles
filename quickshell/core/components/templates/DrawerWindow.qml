// TEMPLATE: un cajón que sale del borde de abajo del marco y se queda con el
// teclado (Spotlight, el portapapeles).
//
// Es una ventana de capa que cubre la pantalla (un clic afuera avisa con
// `dismissed`) y dibuja el cajón: una figura negra que crece desde el borde
// con el mismo rebote que la isla y los cajones del marco. Lo de adentro lo
// pone quien la usa.
//
// ── ¿Por qué no es parte del marco? ──────────────────────────────────────
//
// Por el teclado. El marco nunca se queda con él más de lo necesario, y
// Spotlight lo necesita entero mientras está abierto. Así que el cajón es su
// propia ventana, encima del marco y del mismo negro, y se mete `overlap` px
// en él para que no quede costura (igual que la isla cuelga de arriba).
//
// ── Vivir mientras se cierra ─────────────────────────────────────────────
//
// La ventana existe siempre, pero solo está mapeada (visible, con búferes)
// mientras está abierta o terminando de cerrarse: `present`. Sin eso, al
// cerrar desaparecería de golpe en vez de volver a meterse en el marco.
// Quien la usa crea su contenido solo mientras `present` (un Loader).
//
// Dos formas (ver DrawerShape):
//   attach: "bottom"   al centro del borde de abajo
//   attach: "corner"   en la esquina de abajo a la derecha
//
// Con `dim`, la pantalla de atrás se oscurece mientras está abierto (Mission
// Control, para que las tarjetas resalten).

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core.theme
import qs.core.components.atoms

PanelWindow {
    id: root

    default property alias content: holder.data

    property string namespace: "z0-drawer"
    property string attach: "bottom"

    property bool open: false

    // El cuerpo abierto, sin alas: lo que mide el contenido.
    property real bodyWidth: 0
    property real bodyHeight: 0

    // "bottom": el ancho del que parte al crecer (un tope, como la isla).
    property real closedWidth: 0

    // Dónde está el borde del marco: su grosor abajo y, a la derecha, lo que
    // haya (el marco y, si está abierto, el panel de notificaciones).
    property real bottomInset: 0
    property real rightInset: 0

    // Cuánto se oscurece lo de atrás con el cajón abierto (0 = nada).
    property real dim: 0

    signal dismissed()

    property real progress: root.open ? 1 : 0

    Behavior on progress {
        NumberAnimation {
            duration: root.open ? Theme.frame.openDuration : Theme.frame.closeDuration
            easing.type: root.open ? Easing.OutBack : Easing.OutCubic
            easing.overshoot: Theme.frame.openOvershoot
        }
    }

    readonly property bool present: root.open || root.progress > 0.002

    // Si el marco cambia de grosor (pantalla completa) o el panel de
    // notificaciones se abre con el cajón abierto, el cajón se recorre.
    property real shownBottom: root.bottomInset
    property real shownRight: root.rightInset

    Behavior on shownBottom {
        NumberAnimation { duration: Theme.frame.slideDuration; easing.type: Easing.OutCubic }
    }

    Behavior on shownRight {
        NumberAnimation {
            duration: Theme.frame.openDuration
            easing.type: Easing.OutBack
            easing.overshoot: Theme.frame.openOvershoot
        }
    }

    // El alto del contenido también cambia con el cajón abierto (llegan
    // resultados): eso se anima aparte, más rápido y sin rebote.
    property real shownHeight: root.bodyHeight

    Behavior on shownHeight {
        enabled: root.progress >= 0.99
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // El cuerpo ahora mismo.
    readonly property real bodyW: root.attach === "corner"
        ? root.bodyWidth * root.progress
        : root.closedWidth + (root.bodyWidth - root.closedWidth) * root.progress
    readonly property real bodyH: Math.max(0, root.shownHeight * root.progress)

    readonly property real bodyX: root.attach === "corner"
        ? root.width - root.shownRight - root.bodyW
        : (root.width - root.bodyW) / 2
    readonly property real bodyY: root.height - root.shownBottom - root.bodyH

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    visible: root.present
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: root.namespace
    WlrLayershell.layer: WlrLayer.Overlay

    // El teclado entero mientras está abierto; cerrándose, ya no: lo que
    // escribas va a tu ventana aunque el cajón todavía se esté metiendo.
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Abierto, toda la pantalla recibe el ratón (un clic afuera cierra);
    // cerrándose, nada: los clics ya pasan a tus ventanas.
    mask: Region {
        width: root.open ? root.width : 0
        height: root.open ? root.height : 0
    }

    Rectangle {
        anchors.fill: parent
        visible: root.dim > 0
        color: "black"
        opacity: root.dim * Math.max(0, Math.min(1, root.progress))
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: root.dismissed()
    }

    DrawerShape {
        id: shape

        attach: root.attach
        bodyWidth: root.bodyW
        bodyHeight: root.bodyH
        wing: Theme.frame.wing
        corner: Theme.frame.bottomCorner
        overlap: Theme.frame.overlap
        fill: Theme.frame.fill

        // El cuerpo cae en (bodyX, bodyY); las alas, a sus lados.
        x: root.bodyX - shape.bodyX
        y: root.bodyY - shape.bodyY
    }

    // El área del cuerpo, tal como va en la animación, y recortada: el
    // contenido está donde va a quedar y el cajón lo va destapando al crecer
    // desde abajo.
    Item {
        x: root.bodyX
        y: root.bodyY
        width: root.bodyW
        height: root.bodyH
        clip: true

        // Un clic dentro del cajón no es un clic afuera.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Item {
            id: holder

            width: root.bodyWidth
            height: root.bodyHeight
            x: root.attach === "corner" ? parent.width - width : (parent.width - width) / 2
            y: parent.height - height + 10 * (1 - opacity)

            opacity: Math.max(0, Math.min(1, (root.progress - 0.55) / 0.4))
        }
    }
}
