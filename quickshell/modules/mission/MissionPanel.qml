// Lo que va dentro de Mission Control: una tarjeta vertical por escritorio
// del monitor enfocado, con el fondo de pantalla de fondo y sus ventanas
// encima (una por app: su ícono y su nombre). Debajo, las apps unidas con
// « + » (MissionControl arma el texto).
//
// La selección empieza en el escritorio donde estás.
//
// Teclas:
//   ← →     moverse
//   Enter   ir a ese escritorio
//   Esc     cerrar
//
// Un clic en una tarjeta te lleva a ese escritorio.

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.domain.desktop

Item {
    id: root

    signal dismissed()

    property int selected: MissionControl.activeIndex

    function move(delta): void {
        const count = MissionControl.desks.length;
        if (count === 0)
            return;
        root.selected = Math.max(0, Math.min(count - 1, root.selected + delta));
        cards.positionViewAtIndex(root.selected, ListView.Contain);
    }

    Component.onCompleted: {
        // La selección deja de seguir al escritorio activo: desde aquí la
        // mueven las flechas.
        root.selected = MissionControl.activeIndex;
        cards.positionViewAtIndex(root.selected, ListView.Contain);
        root.forceActiveFocus();
    }

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Left:
            root.move(-1);
            event.accepted = true;
            break;
        case Qt.Key_Right:
            root.move(1);
            event.accepted = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter: {
            const desk = MissionControl.desks[root.selected];
            if (desk)
                MissionControl.go(desk.id);
            event.accepted = true;
            break;
        }
        case Qt.Key_Escape:
            root.dismissed();
            event.accepted = true;
            break;
        }
    }

    ListView {
        id: cards

        x: Theme.frame.deckSide - 4
        y: Theme.frame.deckEnd - 4
        width: parent.width - (Theme.frame.deckSide - 4) * 2
        height: Theme.frame.cardHeight + 10 + Theme.frame.cardLabel + 8

        orientation: ListView.Horizontal
        spacing: Theme.frame.cardGap
        leftMargin: 4
        rightMargin: 4
        topMargin: 4
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: -1

        model: MissionControl.desks

        delegate: DeckCard {
            id: card

            required property var modelData
            required property int index

            source: Wallpapers.source
            label: card.modelData.label
            chosen: card.index === root.selected

            onClicked: MissionControl.go(card.modelData.id)

            // Las ventanas, apiladas al centro. Altas como en el lienzo si
            // caben; con muchas, se encogen para no salirse.
            Column {
                id: windows

                readonly property int count: card.modelData.windows.length
                readonly property real each: windows.count > 0
                    ? Math.min(74, (Theme.frame.cardHeight - 20 - (windows.count - 1) * 8) / windows.count)
                    : 0

                anchors.centerIn: parent
                width: parent.width - 20
                spacing: 8

                Repeater {
                    model: card.modelData.windows

                    Rectangle {
                        id: mini

                        required property var modelData

                        width: windows.width
                        height: windows.each
                        radius: 6
                        color: Qt.rgba(0.05, 0.06, 0.08, 0.94)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        readonly property string iconPath: mini.modelData.icon !== ""
                            ? Quickshell.iconPath(mini.modelData.icon, true)
                            : ""

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            IconImage {
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: mini.iconPath !== ""
                                source: mini.iconPath
                                implicitSize: Math.min(24, mini.height - 22)
                                asynchronous: true
                            }

                            // Sin ícono en el tema: la inicial, en un círculo.
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: mini.iconPath === ""
                                width: Math.min(24, mini.height - 22)
                                height: width
                                radius: width / 2
                                color: Qt.rgba(1, 1, 1, 0.16)

                                Label {
                                    anchors.centerIn: parent
                                    text: mini.modelData.name.charAt(0).toUpperCase()
                                    color: Theme.glass.content
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                }
                            }

                            Label {
                                id: appName

                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: mini.height >= 40
                                width: Math.min(appName.implicitWidth, windows.width - 12)
                                text: mini.modelData.name
                                color: Theme.glass.contentMuted
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
