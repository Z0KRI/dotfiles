// MOLÉCULA: una red Wi-Fi en una lista de Ajustes, como en macOS:
//
//   ✓  Nombre de la red              [Conectar]  🔒  ᯤ  (⋯)
//
//   - La palomita solo si es la red en uso; las demás dejan el hueco, para
//     que los nombres queden alineados.
//   - El botón de acción (Conectar) aparece al pasar el ratón por la fila.
//     Se esconde con opacidad y no con `visible`: así no se mueve nada de
//     lugar al aparecer.
//   - El "⋯" es opcional (showMore).
//
// Es una SettingsRow: título, subtítulo y divisoria se heredan.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

SettingsRow {
    id: root

    property bool checked: false
    property bool locked: false
    property string signalIcon: ""
    property string actionText: ""
    property bool showMore: false

    signal action()
    signal more()

    indent: true
    glyph: root.checked ? Theme.systemIcons.check : ""

    PushButton {
        visible: root.actionText !== ""
        opacity: root.hovered ? 1 : 0
        enabled: root.hovered
        text: root.actionText
        onClicked: root.action()

        Behavior on opacity {
            NumberAnimation { duration: 100 }
        }
    }

    // Aunque no lleve candado, se deja su lugar: los íconos de señal quedan
    // en columna.
    Item {
        implicitWidth: 14
        implicitHeight: 14

        Icon {
            anchors.centerIn: parent
            visible: root.locked
            icon: Theme.systemIcons.lock
            size: 13
            color: Theme.window.text
        }
    }

    Icon {
        icon: root.signalIcon
        size: 15
        color: Theme.window.text
    }

    CircleButton {
        visible: root.showMore
        icon: Theme.systemIcons.more
        onClicked: root.more()
    }
}
