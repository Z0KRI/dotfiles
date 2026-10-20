// ORGANISMO: mosaico "Reproduciendo" del Centro de control.
// Carátula, título, artista y controles. No sabe de MPRIS: recibe datos.

import QtQuick
import Quickshell.Widgets
import qs.core.theme
import qs.core.components.atoms

ControlTile {
    id: root

    property string title: ""
    property string subtitle: ""
    property string artUrl: ""
    property bool playing: false
    property bool canControl: false
    property bool canGoPrevious: false
    property bool canGoNext: false

    signal previous()
    signal toggle()
    signal next()

    padding: 14

    // Carátula, o una nota si no hay.
    ClippingRectangle {
        id: art

        anchors.top: parent.top
        anchors.left: parent.left
        width: 38
        height: 38
        radius: 10
        color: Theme.glass.control

        Icon {
            anchors.centerIn: parent
            visible: cover.status !== Image.Ready
            icon: Theme.systemIcons.music
            size: 16
            color: Theme.glass.contentMuted
        }

        Image {
            id: cover
            anchors.fill: parent
            source: root.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
        }
    }

    Column {
        anchors.top: art.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right

        Label {
            width: parent.width
            text: root.title
            color: Theme.glass.content
            font.pixelSize: Theme.font.small + 1
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Label {
            width: parent.width
            visible: root.subtitle !== ""
            text: root.subtitle
            color: Theme.glass.contentMuted
            font.pixelSize: Theme.font.small
            elide: Text.ElideRight
        }
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 14

        MediaButton {
            icon: Theme.systemIcons.media.previous
            size: 15
            enabled: root.canGoPrevious
            onClicked: root.previous()
        }

        MediaButton {
            icon: root.playing ? Theme.systemIcons.media.pause : Theme.systemIcons.media.play
            size: 20
            enabled: root.canControl
            onClicked: root.toggle()
        }

        MediaButton {
            icon: Theme.systemIcons.media.next
            size: 15
            enabled: root.canGoNext
            onClicked: root.next()
        }
    }

    // Botón de los controles: solo ícono, con rebote al presionarlo.
    component MediaButton: Item {
        id: button

        property string icon: ""
        property int size: 16

        signal clicked()

        width: button.size + 8
        height: button.size + 8
        opacity: button.enabled ? 1 : 0.35
        scale: tap.pressed ? 0.85 : 1

        Behavior on scale {
            NumberAnimation {
                duration: Theme.motion.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.motion.spring
            }
        }

        Icon {
            anchors.centerIn: parent
            icon: button.icon
            size: button.size
            color: Theme.glass.content
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            id: tap
            onTapped: button.clicked()
        }
    }
}