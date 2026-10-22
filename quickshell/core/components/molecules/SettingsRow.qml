// MOLÉCULA: una fila de un grupo de Ajustes.
//   - Izquierda: cuadrito de color (icon + tint) o un ícono simple (glyph),
//     título y, opcional, subtítulo.
//   - Derecha: un valor en gris (value) y lo que le pongas dentro: un
//     interruptor, un botón, un deslizador...
//   - Con `navigates` lleva la flecha › y toda la fila es clicable.
//
// La línea divisoria la dibuja la propia fila, arriba, solo si NO es la
// primera de su grupo. "¿Soy la primera?" se responde con y > 0: en una Column
// la primera fila visible siempre queda en y = 0, aunque haya filas ocultas
// antes. Así el grupo no tiene que llevar la cuenta de nada.

import QtQuick
import QtQuick.Layouts
import qs.core.theme
import qs.core.components.atoms

Item {
    id: root

    default property alias accessory: trailing.data

    property string icon: ""
    property color tint: Theme.colors.accent
    property string iconFamily: Theme.font.icon
    property string glyph: ""
    property string glyphFamily: Theme.font.icon

    property string title: ""
    property string subtitle: ""
    property string value: ""

    property bool navigates: false
    property bool clickable: root.navigates

    signal activated()

    width: parent ? parent.width : implicitWidth
    implicitWidth: 400
    implicitHeight: Math.max(Theme.window.rowHeight, texts.implicitHeight + 18)
    opacity: root.enabled ? 1 : 0.45

    readonly property bool hasLeading: root.icon !== "" || root.glyph !== ""
    readonly property real textLeft: root.hasLeading ? leading.x + leading.width + 10 : 12

    Rectangle {
        anchors.fill: parent
        color: root.clickable && hover.hovered ? Theme.window.hover : "transparent"
    }

    Rectangle {
        visible: root.y > 0
        x: root.textLeft
        width: root.width - x
        height: 1
        color: Theme.window.separator
    }

    Item {
        id: leading

        visible: root.hasLeading
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 24

        SymbolTile {
            anchors.centerIn: parent
            visible: root.icon !== ""
            size: 24
            icon: root.icon
            tint: root.tint
            fontFamily: root.iconFamily
        }

        Icon {
            anchors.centerIn: parent
            visible: root.icon === "" && root.glyph !== ""
            icon: root.glyph
            size: 16
            color: Theme.window.textMuted
            font.family: root.glyphFamily
        }
    }

    Column {
        id: texts

        anchors.left: parent.left
        anchors.leftMargin: root.textLeft
        anchors.right: trailing.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Label {
            width: parent.width
            text: root.title
            color: Theme.window.text
            font.pixelSize: Theme.window.fontBody
        }

        Label {
            width: parent.width
            visible: root.subtitle !== ""
            text: root.subtitle
            color: Theme.window.textMuted
            font.pixelSize: Theme.window.fontCaption
            wrapMode: Text.WordWrap
            maximumLineCount: 3
        }
    }

    // Lo de la derecha. Un RowLayout centra en vertical a cada hijo por su
    // cuenta, así no importa si es un interruptor de 20 px o un botón de 26.
    RowLayout {
        id: trailing

        anchors.right: chevron.visible ? chevron.left : parent.right
        anchors.rightMargin: chevron.visible ? 6 : 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Label {
            visible: root.value !== ""
            text: root.value
            color: Theme.window.textMuted
            font.pixelSize: Theme.window.fontBody
            elide: Text.ElideNone
        }
    }

    Icon {
        id: chevron

        visible: root.navigates
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        icon: Theme.systemIcons.chevronRight
        size: 13
        color: Theme.window.textMuted
    }

    HoverHandler {
        id: hover
        enabled: root.clickable
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        enabled: root.clickable
        onTapped: root.activated()
    }
}
