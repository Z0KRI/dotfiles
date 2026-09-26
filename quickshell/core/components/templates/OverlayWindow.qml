import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core.theme

PanelWindow {
    id: root

    default property alias content: contentHolder.data

    property string namespace: "z0-overlay"

    signal dismissed()

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: root.namespace

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismissed()
        }
    }

    Item {
        id: contentHolder

        anchors.fill: parent

        opacity: 0
        scale: 0.96
        transformOrigin: Item.Top

        Component.onCompleted: appear.start()

        ParallelAnimation {
            id: appear

            NumberAnimation {
                target: contentHolder
                property: "opacity"
                to: 1
                duration: 180
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                target: contentHolder
                property: "scale"
                to: 1
                duration: 320
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            }
        }
    }
}