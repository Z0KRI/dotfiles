// MOLÉCULA: fila de Ajustes con un campo de texto a la derecha, alineado a
// la derecha como en macOS ("Dirección IP      192.168.1.10").
//   - `editable: false` lo deja como un valor en gris que no se puede tocar.
//   - Avisa con edited(text) en cada tecla; quién la usa guarda el texto y
//     se lo devuelve por `text`.
//
// Es una SettingsRow: título, subtítulo y divisoria se heredan.

import QtQuick
import QtQuick.Layouts
import qs.core.theme
import qs.core.components.atoms

SettingsRow {
    id: root

    property string text: ""
    property string placeholder: ""
    property bool editable: true
    property int fieldWidth: 200

    signal edited(string text)

    TextField {
        id: field

        // Va dentro del RowLayout de la fila: el tamaño se pide así.
        Layout.preferredWidth: root.fieldWidth
        Layout.preferredHeight: 24

        text: root.text
        placeholder: root.editable ? root.placeholder : ""
        readOnly: !root.editable
        color: root.editable ? Theme.window.text : Theme.window.textMuted
        font.pixelSize: Theme.window.fontBody
        horizontalAlignment: TextInput.AlignRight
        inputMethodHints: Qt.ImhNoPredictiveText

        onTextEdited: root.edited(field.text)
    }
}
