// ÁTOMO: el campo de texto de la shell, con placeholder.
//
// TextInput de QtQuick no trae placeholder; se lo agregamos aquí una sola
// vez. Los colores son de fábrica para fondos claros u oscuros según el tema;
// sobre vidrio, quien lo usa los cambia (color y placeholderColor), igual que
// cualquier propiedad: la instancia gana.

import QtQuick
import qs.core.theme

TextInput {
    id: root

    property string placeholder: ""
    property color placeholderColor: Qt.alpha(root.color, 0.5)

    color: Theme.colors.baseContent
    selectionColor: Theme.colors.accent
    selectedTextColor: "#ffffff"
    // Tipografía: la misma que Label (Theme.font no tiene "family").
    font.family: Theme.font.ui
    font.pixelSize: Theme.font.large
    verticalAlignment: TextInput.AlignVCenter
    clip: true

    Text {
        anchors.verticalCenter: parent.verticalCenter
        // Con ancho, el elide tiene contra qué medir.
        width: parent.width
        visible: root.text === ""
        text: root.placeholder
        color: root.placeholderColor
        font: root.font
        elide: Text.ElideRight
    }
}
