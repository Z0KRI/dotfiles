// MOLÉCULA: fila de Ajustes con interruptor a la derecha. Es una SettingsRow
// con un ToggleSwitch dentro: lo que no cambia (título, subtítulo, ícono,
// divisoria) se hereda tal cual.

import QtQuick
import qs.core.components.atoms

SettingsRow {
    id: root

    property bool checked: false

    signal toggled()

    ToggleSwitch {
        implicitWidth: 34
        implicitHeight: 20
        checked: root.checked
        onToggled: root.toggled()
    }
}
