import QtQuick
import Quickshell.Widgets
import qs.core.theme
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.launcher

ClippingRectangle {
    id: root

    property string query: ""
    readonly property var results: SearchApps.execute(root.query)
    readonly property bool showResults: root.query !== "" && root.results.length > 0

    property var shownResults: []

    signal dismissed()
    signal launched()

    implicitWidth: 500
    implicitHeight: content.implicitHeight + Theme.spacing.sm

    color: Qt.alpha(Theme.colors.base100, 0.85)
    radius: Theme.radius.lg

    onResultsChanged: {
        if (root.query !== "" && root.results.length > 0)
            root.shownResults = root.results;
    }

    // Absorbe los clics para que no lleguen al fondo del overlay.
    MouseArea {
        anchors.fill: parent
    }

    Column {
        id: content

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacing.xs 
        spacing: Theme.spacing.sm

        SearchField {
            id: search

            width: parent.width
            placeholder: "Buscar en Spotlight"

            onSearched: value => root.query = value
            onNavigated: delta => list.move(delta)
            onAccepted: list.activateCurrent()
            onDismissed: root.dismissed()
        }

        ResultList {
            id: list

            width: parent.width
            height: root.showResults ? Math.min(contentHeight, 360) : 0
            opacity: root.showResults ? 1 : 0
            visible: opacity > 0
            model: root.shownResults

            Behavior on height {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutExpo
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }

            onActivated: entry => {
                LaunchApp.execute(entry);
                root.launched();
            }
        }
    }

    Component.onCompleted: search.focusInput()
}