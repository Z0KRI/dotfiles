// La barra lateral de Ajustes: buscador, tu perfil y las secciones en grupos.
// Mientras buscas, los grupos se cambian por una lista plana de resultados,
// como en macOS. Enter abre el primero; Ctrl+F lleva al buscador.

import QtQuick
import Quickshell
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.domain.settings
import qs.domain.system

Item {
    id: root

    readonly property string query: search.text
    readonly property var results: SettingsCatalog.search(root.query)
    readonly property bool searching: root.query.trim() !== ""

    function choose(id): void {
        SettingsControl.go(id);
    }

    Shortcut {
        sequence: "Ctrl+F"
        onActivated: search.focusInput()
    }

    SidebarSearch {
        id: search

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        onAccepted: {
            if (root.results.length > 0)
                root.choose(root.results[0].id);
        }
    }

    Flickable {
        id: list

        anchors.top: search.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 10
        anchors.rightMargin: 10

        contentHeight: column.implicitHeight + 12
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: column

            width: list.width
            spacing: 12

            // ── Perfil: tu usuario y el equipo. Lleva a "Acerca de". ──
            Rectangle {
                visible: !root.searching
                width: parent.width
                height: 50
                radius: 8
                color: profileHover.hovered ? Theme.window.hover : "transparent"

                Avatar {
                    id: avatar

                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    size: 34
                    name: AboutThisComputer.userName
                    source: "file://" + Quickshell.env("HOME") + "/.face"
                }

                Column {
                    anchors.left: avatar.right
                    anchors.leftMargin: 9
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Label {
                        width: parent.width
                        text: AboutThisComputer.userName
                        color: Theme.window.text
                        font.pixelSize: Theme.window.fontBody
                        font.weight: Font.DemiBold
                    }

                    Label {
                        width: parent.width
                        text: AboutThisComputer.hostName !== "—"
                            ? AboutThisComputer.system + " · " + AboutThisComputer.hostName
                            : AboutThisComputer.system
                        color: Theme.window.textMuted
                        font.pixelSize: Theme.window.fontCaption
                    }
                }

                HoverHandler {
                    id: profileHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.choose("about")
                }
            }

            // ── Secciones, en grupos ──
            Repeater {
                model: root.searching ? [] : SettingsCatalog.groups

                Column {
                    id: group

                    required property var modelData

                    width: column.width
                    spacing: 1

                    Repeater {
                        model: group.modelData

                        SidebarRow {
                            required property var modelData

                            icon: modelData.icon
                            tint: modelData.tint
                            text: modelData.title
                            selected: SettingsControl.section === modelData.id
                            onActivated: root.choose(modelData.id)
                        }
                    }
                }
            }

            // ── Resultados de la búsqueda ──
            Column {
                visible: root.searching
                width: parent.width
                spacing: 1

                Repeater {
                    model: root.results

                    SidebarRow {
                        required property var modelData

                        icon: modelData.icon
                        tint: modelData.tint
                        text: modelData.title
                        selected: SettingsControl.section === modelData.id
                        onActivated: root.choose(modelData.id)
                    }
                }

                Label {
                    visible: root.results.length === 0
                    width: parent.width
                    topPadding: 8
                    horizontalAlignment: Text.AlignHCenter
                    text: "Sin resultados"
                    color: Theme.window.textMuted
                    font.pixelSize: Theme.window.fontBody
                }
            }
        }
    }
}
