// MOLÉCULA: una opción de menú. Ícono, texto y, a la derecha,
// un atajo o una insignia (ej. "3 actualizaciones").

import QtQuick
import QtQuick.Layouts
import qs.core.theme
import qs.core.components.atoms

Surface {
    id: root

    property string icon: ""
    property string text: ""
    property string shortcut: ""
    property string badge: ""

    signal triggered()

    // En una lista vertical, ocupa todo el ancho por defecto.
    width: parent ? parent.width : implicitWidth
    implicitHeight: 26
    implicitWidth: layout.implicitWidth + Theme.spacing.sm * 2
    radius: 6

    color: root.enabled && hover.hovered
           ? Theme.colors.accent
           : Qt.alpha(Theme.colors.accent, 0)

    // Deshabilitada: se ve apagada y no reacciona.
    opacity: root.enabled ? 1 : 0.45

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.leftMargin: Theme.spacing.sm
        anchors.rightMargin: Theme.spacing.sm
        spacing: Theme.spacing.sm

        // Columna fija para el ícono: los textos quedan alineados
        // aunque alguna opción no tenga ícono.
        Item {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16

            Icon {
                anchors.centerIn: parent
                icon: root.icon
                size: 14
                visible: root.icon !== ""
            }
        }

        Label {
            Layout.fillWidth: true
            text: root.text
            elide: Text.ElideRight
        }

        // Insignia en forma de cápsula.
        Surface {
            visible: root.badge !== ""
            implicitHeight: 18
            implicitWidth: badgeLabel.implicitWidth + 12
            radius: height / 2
            color: Theme.glass.hover

            Label {
                id: badgeLabel
                anchors.centerIn: parent
                text: root.badge
                font.pixelSize: 11
            }
        }

        Label {
            visible: root.shortcut !== ""
            text: root.shortcut
            opacity: 0.6
        }
    }

    HoverHandler {
        id: hover
    }

    TapHandler {
        onTapped: root.triggered()
    }
}