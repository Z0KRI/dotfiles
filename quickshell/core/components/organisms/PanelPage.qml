// ORGANISMO: una página del Centro de control.
// Con título muestra encabezado: regresar · título · interruptor opcional.
// Sin título es la página de inicio. Aparece con un desvanecido corto.

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules

Column {
    id: root

    default property alias content: body.data
    property alias bodySpacing: body.spacing

    property string title: ""
    property bool showSwitch: false
    property bool switchOn: false
    property color contentColor: Theme.glass.content

    signal back()
    signal switchToggled()

    width: parent ? parent.width : implicitWidth
    spacing: 10

    onVisibleChanged: {
        if (root.visible)
            fadeIn.restart();
    }

    NumberAnimation {
        id: fadeIn
        target: root
        property: "opacity"
        from: 0
        to: 1
        duration: 180
        easing.type: Easing.OutCubic
    }

    // Encabezado (solo en páginas de detalle).
    Item {
        visible: root.title !== ""
        width: parent.width
        height: 32

        ControlButton {
            id: backButton
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            height: 30
            iconSize: 14
            icon: Theme.systemIcons.chevronLeft
            onClicked: root.back()
        }

        // Títulos largos (el nombre de unos audífonos) se cortan con "…" antes
        // de llegar al interruptor.
        Label {
            anchors.left: backButton.right
            anchors.leftMargin: 10
            anchors.right: root.showSwitch ? headerSwitch.left : parent.right
            anchors.rightMargin: root.showSwitch ? 10 : 0
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: root.title
            color: root.contentColor
            font.pixelSize: Theme.font.large
            font.weight: Font.Bold
        }

        ToggleSwitch {
            id: headerSwitch
            visible: root.showSwitch
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: root.switchOn
            offColor: Theme.glass.control
            onToggled: root.switchToggled()
        }
    }

    Column {
        id: body
        width: parent.width
        spacing: 2
    }
}