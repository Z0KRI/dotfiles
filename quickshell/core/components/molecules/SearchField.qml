// MOLÉCULA: la barra de búsqueda: lupa + campo de texto + teclado.
//
// No sabe qué se busca. Traduce teclas a señales con significado, y quien la
// usa decide qué hace cada una:
//
//   searched(query)       el texto, con un pequeño debounce
//   navigated(delta)      ↑ / ↓
//   accepted()            Enter
//   alternateAccepted()   Ctrl + Enter (la acción "alternativa")
//   tabbed(delta)         Tab / Shift + Tab
//   shortcut(number)      Ctrl o Super + 1…9
//   removeRequested()     Shift + Supr
//   backspacedEmpty()     Retroceso con el campo ya vacío
//   dismissed()           Esc
//
// `rightInset` deja libre un espacio a la derecha para lo que quien la usa
// quiera poner encima (en Spotlight, los chips de modo).
//
// Apariencia, para ponerla sobre cualquier fondo (en Spotlight, vidrio):
//   glyph          el glifo de la izquierda (la lupa, o el ícono del modo)
//   contentColor   texto, glifo y placeholder (este último a media opacidad)
//   fontSize       el tamaño del texto; el glifo crece con él
//   padding        el margen de los lados (en una cápsula, más que en un cuadro:
//                  la curva se come las esquinas)

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Surface {
    id: root

    property alias text: input.text
    property alias placeholder: input.placeholder
    property int debounceDelay: 10
    property int rightInset: 0
    property alias glyph: searchIcon.icon
    property color contentColor: Theme.colors.baseContent
    property alias fontSize: input.font.pixelSize
    property int padding: Theme.spacing.md

    signal accepted()
    signal alternateAccepted()
    signal dismissed()
    signal navigated(int delta)
    signal searched(string query)
    signal tabbed(int delta)
    signal shortcut(int number)
    signal removeRequested()
    signal backspacedEmpty()

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

        icon: Theme.systemIcons.search
        color: root.contentColor

        // Un poco más grande que el texto, como la lupa de macOS.
        size: Math.round(input.font.pixelSize * 1.15)
        anchors.left: parent.left
        anchors.leftMargin: root.padding
        anchors.verticalCenter: parent.verticalCenter
    }

    TextField {
        id: input

        // Toda la altura de la barra: así un clic arriba o abajo del texto
        // también le da el foco al campo.
        anchors.left: searchIcon.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.spacing.md
        anchors.rightMargin: root.padding + root.rightInset

        color: root.contentColor
        placeholderColor: Qt.alpha(root.contentColor, 0.5)

        onTextEdited: debounceTimer.restart()

        Keys.onPressed: event => {
            const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
            const meta = (event.modifiers & Qt.MetaModifier) !== 0;
            const shift = (event.modifiers & Qt.ShiftModifier) !== 0;

            // Ctrl o Super + un número.
            if ((ctrl || meta) && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                root.shortcut(event.key - Qt.Key_0);
                event.accepted = true;
                return;
            }

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
                if (ctrl)
                    root.alternateAccepted();
                else
                    root.accepted();
                event.accepted = true;
                break;
            // Qt manda Shift + Tab como su propia tecla, Backtab.
            case Qt.Key_Tab:
                root.tabbed(1);
                event.accepted = true;
                break;
            case Qt.Key_Backtab:
                root.tabbed(-1);
                event.accepted = true;
                break;
            case Qt.Key_Delete:
                if (shift) {
                    root.removeRequested();
                    event.accepted = true;
                }
                break;
            case Qt.Key_Backspace:
                // Solo con el campo vacío: si hay texto, el retroceso borra
                // letras como siempre (event.accepted se queda en false).
                if (input.text === "") {
                    root.backspacedEmpty();
                    event.accepted = true;
                }
                break;
            }
        }
    }
}
