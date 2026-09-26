import QtQuick
import qs.core.theme
import qs.core.components.atoms

Surface {
    id: root

    property var entry: null
    property bool selected: false

    signal activated()
    signal hovered()


    color: root.selected ? Qt.alpha(Theme.colors.baseContent, 0.1) : "transparent"
    radius: Theme.radius.md
    implicitHeight: 45

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered()
        onClicked: root.activated()
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing.md
        anchors.rightMargin: Theme.spacing.md
        spacing: Theme.spacing.lg

        ResultIcon {
            anchors.verticalCenter: parent.verticalCenter
            iconName: root.entry?.icon
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 32 - Theme.spacing.lg
            // spacing: Theme.spacing.xs

            Label {
                width: parent.width
                text: root.entry?.name ?? "Unknown App"
            }

            // Label {
            //     width: parent.width
            //     color: Qt.alpha(Theme.colors.baseContent, 0.5)
            //     visible: text !== ""
            //     text: root.entry?.comment ?? root.entry?.genericName ?? ""
            // }
        }
    }
}
