pragma ComponentBehavior: Bound

// (Bound: los delegados de los Repeater pueden leer los id de afuera,
// como `root`, y qmllint lo sabe. A cambio, lo de cada delegado se pide
// con su id: `fila.modelData`, no `modelData` a secas desde un hijo.)

// ORGANISMO: tus monitores dibujados a escala, en su posición real, como en
// Pantallas de macOS. Se tocan para elegirlos y se arrastran para
// acomodarlos.
//
// No sabe de Hyprland: recibe rectángulos en píxeles lógicos y avisa dónde
// soltaste uno (dropped). Quién decide a dónde se pega es el dominio; cuando
// llegan las posiciones nuevas, el rectángulo se desliza a su lugar.
//
// Dos detalles de QML que hacen que el arrastre se vea bien:
//   - El modelo del Repeater es un NÚMERO (cuántos hay), no la lista. Si
//     fuera la lista, cada cambio de posición recrearía los rectángulos y se
//     perdería la animación (y el arrastre a medias).
//   - `dragging` es una propiedad propia y no `drag.active`. Así se apaga
//     DESPUÉS de avisar dónde lo soltaste: el rectángulo sale de donde lo
//     dejaste hacia su lugar nuevo, en vez de regresar de golpe al viejo.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Item {
    id: root

    // [{ name, title, x, y, width, height }]
    property var monitors: []
    property string selected: ""
    property bool movable: true

    signal picked(string name)
    signal dropped(string name, real x, real y)

    implicitWidth: 520
    implicitHeight: 190

    readonly property var bounds: {
        if (root.monitors.length === 0)
            return { x: 0, y: 0, width: 1, height: 1 };

        const left = Math.min(...root.monitors.map(m => m.x));
        const top = Math.min(...root.monitors.map(m => m.y));
        const right = Math.max(...root.monitors.map(m => m.x + m.width));
        const bottom = Math.max(...root.monitors.map(m => m.y + m.height));
        return { x: left, y: top, width: Math.max(1, right - left), height: Math.max(1, bottom - top) };
    }

    // Cuánto mide un píxel lógico en el dibujo. Con un solo monitor no se
    // deja que ocupe todo: se vería como un botón gigante.
    readonly property real factor: Math.min((root.width - 48) / root.bounds.width,
                                            (root.height - 40) / root.bounds.height,
                                            0.12)

    readonly property real originX: (root.width - root.bounds.width * root.factor) / 2 - root.bounds.x * root.factor
    readonly property real originY: (root.height - root.bounds.height * root.factor) / 2 - root.bounds.y * root.factor

    Repeater {
        model: root.monitors.length

        Rectangle {
            id: screen

            required property int index
            readonly property var monitor: root.monitors[screen.index] ?? ({ name: "", x: 0, y: 0, width: 0, height: 0 })
            readonly property bool isSelected: screen.monitor.name === root.selected

            property bool dragging: false
            property real dx: 0
            property real dy: 0

            readonly property real homeX: root.originX + screen.monitor.x * root.factor
            readonly property real homeY: root.originY + screen.monitor.y * root.factor

            x: screen.dragging ? screen.homeX + screen.dx : screen.homeX
            y: screen.dragging ? screen.homeY + screen.dy : screen.homeY
            z: screen.dragging ? 2 : (screen.isSelected ? 1 : 0)
            width: screen.monitor.width * root.factor
            height: screen.monitor.height * root.factor
            radius: 5

            Behavior on x {
                enabled: !screen.dragging
                NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
            }

            Behavior on y {
                enabled: !screen.dragging
                NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
            }

            // Un "fondo de pantalla" en cada uno, como los de macOS.
            gradient: Gradient {
                GradientStop { position: 0; color: "#5b8cff" }
                GradientStop { position: 1; color: "#2c4fb8" }
            }

            border.width: screen.isSelected ? 3 : 1
            border.color: screen.isSelected ? Theme.colors.accent : Qt.rgba(0, 0, 0, 0.25)

            opacity: screen.dragging ? 0.85 : 1

            Label {
                anchors.centerIn: parent
                width: parent.width - 12
                horizontalAlignment: Text.AlignHCenter
                text: screen.monitor.name
                color: "white"
                font.pixelSize: Theme.window.fontCaption
                font.weight: Font.DemiBold
            }

            HoverHandler {
                cursorShape: root.movable ? Qt.OpenHandCursor : Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: root.picked(screen.monitor.name)
            }

            DragHandler {
                id: drag

                target: null
                enabled: root.movable

                onActiveTranslationChanged: {
                    if (drag.active) {
                        screen.dx = drag.activeTranslation.x;
                        screen.dy = drag.activeTranslation.y;
                    }
                }

                onActiveChanged: {
                    if (drag.active) {
                        screen.dx = 0;
                        screen.dy = 0;
                        screen.dragging = true;
                        root.picked(screen.monitor.name);
                        return;
                    }

                    // De vuelta a píxeles lógicos: dónde quedó su esquina.
                    root.dropped(screen.monitor.name,
                                 (screen.homeX + screen.dx - root.originX) / root.factor,
                                 (screen.homeY + screen.dy - root.originY) / root.factor);
                    screen.dragging = false;
                }
            }
        }
    }
}
