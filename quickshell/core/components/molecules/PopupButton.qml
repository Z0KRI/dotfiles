pragma ComponentBehavior: Bound

// (Bound: los delegados de los Repeater pueden leer los id de afuera,
// como `root`, y qmllint lo sabe.)

// MOLÉCULA: el botón desplegable de macOS ("Fija ⌃⌄"): enseña la opción
// elegida y, al tocarlo, abre un menú con todas.
//
//   options: [{ value, label }]      current: el value elegido
//
// El menú NO vive dentro del botón: si viviera ahí, lo recortaría la tarjeta
// o el área con scroll donde esté. Al abrirse se muda al elemento de más
// arriba de la ventana (se sube por los `parent` hasta que ya no hay) y se
// coloca donde está el botón con mapToItem(), que traduce coordenadas de un
// elemento a otro. Una capa del tamaño de la ventana detrás del menú atrapa
// el clic de "afuera" para cerrarlo.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Rectangle {
    id: root

    property var options: []
    property var current

    signal selected(var value)

    readonly property string currentLabel:
        root.options.find(option => option.value === root.current)?.label ?? ""

    property bool open: false

    // El ancho de un renglón del menú: el texto más largo, más la palomita
    // y el aire. Se mide con FontMetrics porque los renglones aún no existen.
    readonly property real entryWidth: Math.max(root.width - 12,
        ...root.options.map(option => Math.ceil(metrics.advanceWidth(option.label)) + 44))

    FontMetrics {
        id: metrics
        font.family: Theme.font.ui
        font.pixelSize: Theme.window.fontBody
    }

    function show(): void {
        let top = root;
        while (top.parent)
            top = top.parent;

        const corner = root.mapToItem(top, 0, 0);
        layer.parent = top;
        menu.x = Math.max(8, Math.min(top.width - menu.width - 8, corner.x + root.width - menu.width));
        menu.y = Math.max(8, Math.min(top.height - menu.height - 8, corner.y + root.height + 4));
        root.open = true;
    }

    implicitWidth: label.implicitWidth + 34
    implicitHeight: 22
    radius: 6
    opacity: root.enabled ? 1 : 0.45
    color: root.open || hover.hovered ? Theme.window.control : "transparent"

    Label {
        id: label

        anchors.right: arrows.left
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        text: root.currentLabel
        color: Theme.window.textMuted
        font.pixelSize: Theme.window.fontBody
    }

    Rectangle {
        id: arrows

        anchors.right: parent.right
        anchors.rightMargin: 3
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        radius: 5
        color: Theme.window.control

        Icon {
            anchors.centerIn: parent
            icon: Theme.systemIcons.upDown
            size: 11
            color: Theme.window.text
        }
    }

    HoverHandler {
        id: hover
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        enabled: root.enabled
        onTapped: root.show()
    }

    Item {
        id: layer

        anchors.fill: parent
        visible: root.open
        z: 1000

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: root.open = false
            onWheel: wheel => wheel.accepted = true
        }

        Rectangle {
            id: menu

            width: root.entryWidth + 12
            height: list.implicitHeight + 12
            radius: 10
            color: Theme.window.group
            border.width: 1
            border.color: Theme.window.controlBorder

            // Para que un clic en el borde del menú no lo cierre.
            MouseArea {
                anchors.fill: parent
            }

            Column {
                id: list

                x: 6
                y: 6

                Repeater {
                    model: root.options

                    Rectangle {
                        id: entry

                        required property var modelData

                        readonly property bool isCurrent: entry.modelData.value === root.current

                        width: root.entryWidth
                        height: 24
                        radius: 6
                        color: entryHover.hovered ? Theme.colors.accent : "transparent"

                        Icon {
                            x: 6
                            anchors.verticalCenter: parent.verticalCenter
                            visible: entry.isCurrent
                            icon: Theme.systemIcons.check
                            size: 12
                            color: entryHover.hovered ? "white" : Theme.window.text
                        }

                        Label {
                            id: text

                            x: 24
                            anchors.verticalCenter: parent.verticalCenter
                            text: entry.modelData.label
                            color: entryHover.hovered ? "white" : Theme.window.text
                            font.pixelSize: Theme.window.fontBody
                        }

                        HoverHandler {
                            id: entryHover
                        }

                        TapHandler {
                            onTapped: {
                                root.open = false;
                                if (!entry.isCurrent)
                                    root.selected(entry.modelData.value);
                            }
                        }
                    }
                }
            }
        }
    }
}
