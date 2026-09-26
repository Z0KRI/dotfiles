import QtQuick
import qs.core.theme

TextInput {
    id: root

    property string placeholder: ""

    color: Theme.colors.baseContent
    selectionColor: Theme.colors.accent
    selectedTextColor: Theme.colors.base100
    // Tipografía
    font.family: Theme.font.family
    font.pixelSize: Theme.font.large
    verticalAlignment: TextInput.AlignVCenter
    clip: true

    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.text === ""
        text: root.placeholder
        color: Qt.alpha(Theme.colors.baseContent, 0.5)
        font: root.font
        elide: Text.ElideRight
    }

}
