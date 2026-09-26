import QtQuick
import qs.core.theme
import qs.core.components.atoms

Surface {
    id: root

    property alias text: input.text
    property alias placeholder: input.placeholder
    property int debounceDelay: 10 

    signal accepted()
    signal dismissed()
    signal navigated(int delta)
    signal searched(string query)    

    implicitHeight: 42
    color: "transparent"

    function focusInput(): void {
        input.forceActiveFocus();
    }

    function clear(): void {
        debounceTimer.stop();
        input.text = "";
        root.searched("");           
    }

    function flush(): void {
        if (!debounceTimer.running)
            return;
        debounceTimer.stop();
        root.searched(input.text);
    }

    Timer {
        id: debounceTimer
        interval: root.debounceDelay
        repeat: false
        onTriggered: root.searched(input.text)
    }

    Icon {
        id: searchIcon
        
        icon: ""

        size: parent.height * 0.5
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacing.md
        anchors.verticalCenter: parent.verticalCenter
    }

    TextField {
        id: input

        anchors.left: searchIcon.right
        anchors.right: parent.right
        anchors.leftMargin: Theme.spacing.md 
        anchors.rightMargin: Theme.spacing.md
        anchors.verticalCenter: parent.verticalCenter

        onTextEdited: debounceTimer.restart()

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Escape:
                debounceTimer.stop();
                root.dismissed();
                event.accepted = true;
                break;
            case Qt.Key_Up:
                root.flush();
                root.navigated(-1);
                event.accepted = true;
                break;
            case Qt.Key_Down:
                root.flush();
                root.navigated(1);
                event.accepted = true;
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                root.flush();
                root.accepted();
                event.accepted = true;
                break;
            }
        }
    }
}