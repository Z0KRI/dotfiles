// ORGANISMO: calendario mensual al estilo macOS.
// Hoy lleva un círculo de acento; los días de otros meses se ven apagados.

import QtQuick
import QtQuick.Layouts
import qs.core.theme
import qs.core.utils
import qs.core.components.atoms
import qs.core.components.molecules

Item {
    id: root

    property var locale: Qt.locale()
    property date today: new Date()

    // Mes que se está viendo (month: 0 a 11).
    property int year: root.today.getFullYear()
    property int month: root.today.getMonth()

    readonly property int cellSize: 28

    readonly property var cells: CalendarMath.monthGrid(
        root.year, root.month, root.locale.firstDayOfWeek, root.today
    )

    readonly property string title: {
        const name = root.locale.standaloneMonthName(root.month, Locale.LongFormat);
        return name.charAt(0).toUpperCase() + name.slice(1) + " " + root.year;
    }

    // Vuelve al mes actual.
    function showToday(): void {
        root.year = root.today.getFullYear();
        root.month = root.today.getMonth();
    }

    // Avanza o retrocede meses (delta: +1 / -1).
    function shift(delta): void {
        const target = new Date(root.year, root.month + delta, 1);
        root.year = target.getFullYear();
        root.month = target.getMonth();
    }

    implicitWidth: root.cellSize * 7
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        width: parent.width
        spacing: Theme.spacing.sm

        // Encabezado: mes y año, y flechas.
        RowLayout {
            Layout.fillWidth: true

            Label {
                Layout.fillWidth: true
                text: root.title
                font.weight: Font.Bold
            }

            BarItem {
                onClicked: root.shift(-1)
                Label { text: "‹" }
            }

            BarItem {
                onClicked: root.shift(1)
                Label { text: "›" }
            }
        }

        // Iniciales de los días: L M X J V S D.
        Row {
            Repeater {
                model: 7

                Label {
                    required property int index

                    width: root.cellSize
                    horizontalAlignment: Text.AlignHCenter
                    text: root.locale.dayName((root.locale.firstDayOfWeek + index) % 7, Locale.NarrowFormat)
                    opacity: 0.6
                    font.pixelSize: 11
                }
            }
        }

        // Los 42 días.
        Grid {
            columns: 7

            Repeater {
                model: root.cells

                Item {
                    id: cell

                    required property var modelData

                    width: root.cellSize
                    height: root.cellSize

                    // Círculo de "hoy".
                    Rectangle {
                        anchors.centerIn: parent
                        width: root.cellSize - 4
                        height: width
                        radius: width / 2
                        color: Theme.colors.accent
                        visible: cell.modelData.isToday
                    }

                    Label {
                        id: dayLabel

                        anchors.centerIn: parent
                        text: cell.modelData.day
                        opacity: cell.modelData.inMonth ? 1 : 0.35
                        font.weight: cell.modelData.isToday ? Font.Bold : Font.Normal
                    }

                    // Solo hoy cambia de color (para verse sobre el acento).
                    // Al dejar de ser hoy, se restaura el color del tema.
                    Binding {
                        target: dayLabel
                        property: "color"
                        value: Theme.colors.base100
                        when: cell.modelData.isToday
                    }
                }
            }
        }
    }
}