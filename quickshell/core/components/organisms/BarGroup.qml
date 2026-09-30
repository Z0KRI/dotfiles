import QtQuick
import qs.core.theme
import qs.core.components.atoms

Item {
    id: root

    default property alias content: row.data

    property bool flat: false

    implicitWidth: row.implicitWidth + Theme.glass.padding * 2
    implicitHeight: row.implicitHeight + Theme.glass.padding * 2

    Surface {
        anchors.fill: parent
        
        radius: height / 2

        border.width: 1
        border.color: Theme.glass.border

        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.glass.top }
            GradientStop { position: 0.4; color: Theme.glass.middle }
            GradientStop { position: 1.0; color: Theme.glass.bottom }
        }

        opacity: root.flat ? 0 : 1

        Behavior on opacity {
            NumberAnimation { duration: Theme.motion.duration }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.glass.spacing
    }
}