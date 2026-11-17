pragma ComponentBehavior: Bound

// (Bound: los delegados de los Repeater pueden leer los id de afuera,
// como `root`, y qmllint lo sabe.)

// ORGANISMO: una lista de textos que se puede editar, como las de
// "Servidores DNS" de macOS: un renglón por valor y, abajo, los botones
// + y −. Con + aparece un renglón vacío listo para escribir; − quita el
// renglón en el que estás (o el último).
//
//   values:   ["1.1.1.1", "8.8.8.8"]      edited(values) con la lista nueva
//   fallback: lo que se enseña en gris cuando la lista está vacía (los DNS
//             que dio el router): se ve qué se usa, pero no es tuyo.
//
// Detalle de QML: el modelo del Repeater es un NÚMERO (cuántos hay), no la
// lista. Con la lista, cada tecla la cambiaría, el Repeater volvería a crear
// los renglones y el campo perdería el foco a media palabra.

import QtQuick
import Quickshell.Widgets
import qs.core.theme
import qs.core.components.atoms

Column {
    id: root

    property string header: ""
    property var values: []
    property var fallback: []
    property string placeholder: ""

    signal edited(var values)

    // El renglón con el cursor; −1 si ninguno.
    property int focused: -1

    function add(): void {
        root.edited(root.values.concat([""]));
        Qt.callLater(() => {
            const row = rows.itemAt(rows.count - 1);
            if (row)
                row.focusField();
        });
    }

    function remove(): void {
        if (root.values.length === 0)
            return;

        const index = root.focused >= 0 && root.focused < root.values.length
            ? root.focused : root.values.length - 1;
        root.edited(root.values.filter((value, i) => i !== index));
        root.focused = -1;
    }

    width: parent ? parent.width : implicitWidth
    spacing: 7

    Label {
        visible: root.header !== ""
        leftPadding: 4
        text: root.header
        color: Theme.window.text
        font.pixelSize: Theme.window.fontBody
        font.weight: Font.DemiBold
    }

    ClippingRectangle {
        width: parent.width
        height: body.implicitHeight
        radius: Theme.window.radius
        color: Theme.window.group
        border.width: 1
        border.color: Theme.window.groupBorder
        contentUnderBorder: true

        Column {
            id: body

            width: parent.width

            Repeater {
                id: rows

                model: root.values.length

                Rectangle {
                    id: row

                    required property int index

                    function focusField(): void {
                        field.forceActiveFocus();
                    }

                    width: body.width
                    height: 28
                    color: field.activeFocus ? Theme.window.hover : "transparent"

                    TextField {
                        id: field

                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12

                        placeholder: root.placeholder
                        color: Theme.window.text
                        font.pixelSize: Theme.window.fontBody

                        // El texto se pone a mano y no con un enlace: al
                        // escribir, el enlace se rompería. Se vuelve a poner
                        // si la lista cambia desde afuera (quitar un renglón).
                        function sync(): void {
                            const value = root.values[row.index] ?? "";
                            if (field.text !== value)
                                field.text = value;
                        }

                        Component.onCompleted: field.sync()

                        Connections {
                            target: root

                            function onValuesChanged() {
                                field.sync();
                            }
                        }

                        onTextEdited: {
                            const next = root.values.slice();
                            next[row.index] = field.text;
                            root.edited(next);
                        }

                        onActiveFocusChanged: {
                            if (field.activeFocus)
                                root.focused = row.index;
                        }
                    }
                }
            }

            Repeater {
                model: root.values.length === 0 ? root.fallback : []

                Item {
                    id: ghost

                    required property var modelData

                    width: body.width
                    height: 28

                    Label {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: ghost.modelData
                        color: Theme.window.textMuted
                        font.pixelSize: Theme.window.fontBody
                    }
                }
            }

            // Sin nada que enseñar, la lista conserva algo de alto.
            Item {
                visible: root.values.length === 0 && root.fallback.length === 0
                width: 1
                height: 28
            }

            Rectangle {
                width: body.width
                height: 1
                color: Theme.window.separator
            }

            Row {
                x: 8
                height: 26

                Repeater {
                    model: [
                        { icon: Theme.systemIcons.plus, add: true },
                        { icon: Theme.systemIcons.minus, add: false }
                    ]

                    Item {
                        id: button

                        required property var modelData

                        readonly property bool usable: button.modelData.add || root.values.length > 0

                        width: 26
                        height: 26
                        opacity: button.usable ? 1 : 0.35

                        Rectangle {
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            radius: 5
                            color: buttonHover.hovered && button.usable ? Theme.window.control : "transparent"
                        }

                        Icon {
                            anchors.centerIn: parent
                            icon: button.modelData.icon
                            size: 13
                            color: Theme.window.text
                        }

                        HoverHandler {
                            id: buttonHover
                        }

                        TapHandler {
                            enabled: button.usable
                            onTapped: button.modelData.add ? root.add() : root.remove()
                        }
                    }
                }
            }
        }
    }
}
