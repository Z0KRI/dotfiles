// MOLÉCULA: control segmentado de macOS: una cápsula con opciones y la
// elegida resaltada. El resaltado se desliza con tu rebote al cambiar.
//
// `options` es una lista de { value, label }. Cada segmento mide lo que su
// texto más un margen. Para saber cuánto mide un texto sin crear un Label
// por cada uno se usa FontMetrics.advanceWidth(); con eso salen los anchos y
// dónde empieza cada segmento, y el resaltado solo tiene que ir ahí.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Rectangle {
    id: root

    property var options: []
    property var current

    signal selected(var value)

    readonly property int currentIndex: root.options.findIndex(option => option.value === root.current)

    readonly property var widths: root.options.map(option =>
        Math.ceil(metrics.advanceWidth(option.label)) + 24)

    // offsets[i] = dónde empieza el segmento i.
    readonly property var offsets: root.widths.reduce((list, width) =>
        list.concat([list[list.length - 1] + width]), [0])

    implicitWidth: root.offsets[root.offsets.length - 1] + 4
    implicitHeight: 26
    radius: 7
    color: Theme.window.control

    FontMetrics {
        id: metrics
        font.family: Theme.font.ui
        font.pixelSize: Theme.window.fontBody - 1
        font.weight: Font.Medium
    }

    Rectangle {
        visible: root.currentIndex >= 0
        x: 2 + (root.offsets[root.currentIndex] ?? 0)
        y: 2
        width: root.widths[root.currentIndex] ?? 0
        height: root.height - 4
        radius: 5
        color: Theme.window.controlRaised
        border.width: 1
        border.color: Theme.window.controlBorder

        Behavior on x {
            NumberAnimation {
                duration: Theme.motion.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.motion.spring
            }
        }

        Behavior on width {
            NumberAnimation { duration: Theme.motion.duration; easing.type: Easing.OutCubic }
        }
    }

    Row {
        x: 2
        y: 2

        Repeater {
            model: root.options

            Item {
                id: segment

                required property var modelData
                required property int index

                width: root.widths[segment.index] ?? 0
                height: root.height - 4

                Label {
                    anchors.centerIn: parent
                    text: segment.modelData.label
                    color: Theme.window.text
                    font.pixelSize: Theme.window.fontBody - 1
                    font.weight: segment.index === root.currentIndex ? Font.Medium : Font.Normal
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.selected(segment.modelData.value)
                }
            }
        }
    }
}
