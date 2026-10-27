// ORGANISMO: hoja de confirmación modal (el "sheet" de macOS). Oscurece la
// ventana, bloquea los clics de atrás y muestra una tarjeta con título,
// mensaje y dos botones. Enter = aceptar, Escape = rechazar.
//
// El bloqueo es un MouseArea que acepta todo: un clic que llega a él ya no
// baja a la página de atrás.

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules

Item {
    id: root

    property bool shown: false
    property string icon: ""
    property color tint: Theme.colors.accent
    property string title: ""
    property string message: ""
    property string acceptText: "Aceptar"
    property string rejectText: "Cancelar"

    signal accepted()
    signal rejected()

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
        width: 360
        height: column.implicitHeight + 40
        radius: 16
        color: Theme.window.group
        border.width: 1
        border.color: Theme.window.groupBorder

        scale: root.shown ? 1 : 0.94

        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        }

        Column {
            id: column

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 20
            spacing: 10

            SymbolTile {
                visible: root.icon !== ""
                anchors.horizontalCenter: parent.horizontalCenter
                size: 44
                icon: root.icon
                tint: root.tint
            }

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: root.title
                color: Theme.window.text
                font.pixelSize: Theme.window.fontTitle
                font.weight: Font.Bold
            }

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: root.message
                color: Theme.window.textMuted
                font.pixelSize: Theme.window.fontBody - 1
            }

            Item {
                width: 1
                height: 4
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                PushButton {
                    width: 140
                    text: root.rejectText
                    onClicked: root.rejected()
                }

                PushButton {
                    width: 140
                    primary: true
                    text: root.acceptText
                    onClicked: root.accepted()
                }
            }
        }
    }

    Item {
        id: keys

        Keys.onReturnPressed: root.accepted()
        Keys.onEnterPressed: root.accepted()
        Keys.onEscapePressed: root.rejected()
    }
}
