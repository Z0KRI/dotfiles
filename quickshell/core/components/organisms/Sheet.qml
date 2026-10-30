// ORGANISMO: hoja modal (el "sheet" de macOS). Oscurece la ventana, bloquea
// los clics de atrás y muestra una tarjeta con lo que le pongas dentro, en
// columna. Es la base de ConfirmSheet y de la hoja de emparejamiento.
//
// El bloqueo es un MouseArea que acepta todo: un clic que llega a él ya no
// baja a la página de atrás.
//
// Teclado: al aparecer toma el foco y avisa de Enter y de Escape. Si lo de
// adentro necesita el foco (un campo de texto), que lo pida después.

import QtQuick
import qs.core.theme

Item {
    id: root

    default property alias content: column.data

    property bool shown: false
    property int cardWidth: 360

    signal returnPressed()
    signal escapePressed()

    // Para devolverle el foco a la hoja (por ejemplo, al quitar un campo).
    function focusSheet(): void {
        keys.forceActiveFocus();
    }

    visible: opacity > 0
    opacity: root.shown ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    onShownChanged: {
        if (root.shown)
            keys.forceActiveFocus();
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, Theme.isDark ? 0.4 : 0.22)

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            onWheel: wheel => wheel.accepted = true
        }
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: root.cardWidth
        height: column.implicitHeight + 40
        radius: 16
        color: Theme.window.group
        border.width: 1
        border.color: Theme.window.groupBorder

        scale: root.shown ? 1 : 0.94

        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        }

        Behavior on height {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        Column {
            id: column

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 20
            spacing: 10
        }
    }

    Item {
        id: keys

        Keys.onReturnPressed: root.returnPressed()
        Keys.onEnterPressed: root.returnPressed()
        Keys.onEscapePressed: root.escapePressed()
    }
}
