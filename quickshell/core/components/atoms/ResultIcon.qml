import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.core.theme

Item {
    id: root

    property string iconName: ""

    readonly property string resolvedPath: root.iconName !== "" ? Quickshell.iconPath(root.iconName, true) : ""

    implicitWidth: 28
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight

    IconImage {
        anchors.fill: parent
        source: root.resolvedPath
        visible: root.resolvedPath !== ""
    }

    Rectangle {
        anchors.fill: parent
        visible: root.resolvedPath === ""
        radius: Theme.radius.sm
        color: Theme.colors.neutral

        Icon {
            anchors.centerIn: parent
            icon: ""
            size: parent.height * 0.7
            color: Theme.colors.primary
        }
    }
}