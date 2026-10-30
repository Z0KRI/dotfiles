// MOLÉCULA: un botón sobre la isla (que siempre es negra, en modo claro o
// oscuro). Dos formas:
//   - Cápsula con texto: "Descartar", las acciones de una notificación,
//     Contestar y Rechazar (esos dos con `tint` verde y rojo).
//   - Redondo con ícono (sin texto): los de la llamada en curso. Fija `width`
//     y `height` iguales.
//
// `on` es el blanco del iPhone para lo que está encendido (el micrófono
// silenciado): fondo blanco y el contenido en negro. `flat`: sin fondo hasta
// que pasas el ratón (anterior y siguiente del reproductor). `hint` es una
// línea que sale encima al pasar el ratón: la isla no tiene tooltips de
// sistema.
//
// El ícono es de Lucide; `iconFamily` lo cambia (los del reproductor son de
// la Nerd Font).

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property string iconFamily: Theme.font.icon
    property int iconSize: 18
    property real iconRotation: 0
    property string hint: ""

    // Relleno propio; transparente = el gris de la isla.
    property color tint: "transparent"
    property color textColor: Theme.island.fg
    property int fontSize: 12
    property bool bold: false
    property bool on: false
    property bool flat: false

    signal tapped()

    readonly property bool tinted: root.tint.a > 0
    readonly property color ink: root.on ? "#000000" : root.textColor

    implicitWidth: root.text !== "" ? label.implicitWidth + 28 : root.implicitHeight
    implicitHeight: 32
    radius: height / 2
    opacity: root.enabled ? 1 : 0.5

    color: {
        if (root.tinted)
            return hover.hovered && root.enabled ? Qt.lighter(root.tint, 1.12) : root.tint;
        if (root.on)
            return "#ffffff";
        if (root.flat)
            return hover.hovered && root.enabled ? Qt.rgba(1, 1, 1, 0.12) : "transparent";
        return hover.hovered && root.enabled ? Qt.rgba(1, 1, 1, 0.3) : Theme.island.track;
    }

    Behavior on color {
        ColorAnimation { duration: Theme.motion.duration }
    }

    Label {
        id: label

        visible: root.text !== ""
        anchors.centerIn: parent
        text: root.text
        color: root.ink
        font.pixelSize: root.fontSize
        font.bold: root.bold
    }

    Icon {
        visible: root.text === "" && root.icon !== ""
        anchors.centerIn: parent
        icon: root.icon
        font.family: root.iconFamily
        size: root.iconSize
        rotation: root.iconRotation
        color: root.ink
    }

    HoverHandler {
        id: hover
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    TapHandler {
        enabled: root.enabled
        onTapped: root.tapped()
    }

    Label {
        visible: hover.hovered && root.hint !== ""
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 4
        text: root.hint
        color: Theme.island.muted
        font.pixelSize: 10
    }
}
