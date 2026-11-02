// Lo que va dentro del selector de fondos: una tarjeta vertical por imagen de
// ~/Pictures/Wallpapers, con su nombre (el del archivo, sin extensión).
//
// Elegir una la pone de fondo en ese momento (con fundido) y el selector se
// queda abierto, para que compares. Se cierra con un clic afuera, Enter o Esc.
//
// Teclas:
//   ← →          el fondo anterior / siguiente (se aplica al momento)
//   Enter, Esc   cerrar
//
// Con la carpeta vacía, dice dónde poner las imágenes y ofrece abrirla.

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.domain.desktop

Item {
    id: root

    signal dismissed()

    // Cuál es el de ahora en la lista.
    readonly property int currentAt: Wallpapers.current
        ? Wallpapers.list.findIndex(entry => entry.path === Wallpapers.current.path)
        : -1

    // Que se vea la tarjeta del elegido: al abrir, con las flechas, o cuando
    // la carpeta cambia. En ese último caso la lista entera es nueva y el
    // ListView vuelve al principio DESPUÉS de este aviso; por eso va con
    // callLater, para que mueva la vista cuando ya terminó de rearmarse.
    function reveal(): void {
        if (root.currentAt >= 0)
            cards.positionViewAtIndex(root.currentAt, ListView.Contain);
    }

    onCurrentAtChanged: Qt.callLater(root.reveal)

    // El teclado: el cajón se lo queda entero mientras está abierto, pero
    // hay que dárselo a este item en particular.
    Component.onCompleted: root.forceActiveFocus()

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Left:
            Wallpapers.step(-1);
            event.accepted = true;
            break;
        case Qt.Key_Right:
            Wallpapers.step(1);
            event.accepted = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Escape:
            root.dismissed();
            event.accepted = true;
            break;
        }
    }

    // Las tarjetas. La lista es 4 px más grande por cada lado que el hueco,
    // con ese mismo margen adentro: así el halo de la elegida no se corta
    // en las orillas.
    ListView {
        id: cards

        x: Theme.frame.deckSide - 4
        y: Theme.frame.deckEnd - 4
        width: parent.width - (Theme.frame.deckSide - 4) * 2
        height: Theme.frame.cardHeight + 10 + Theme.frame.cardLabel + 8

        visible: !Wallpapers.empty
        orientation: ListView.Horizontal
        spacing: Theme.frame.cardGap
        leftMargin: 4
        rightMargin: 4
        topMargin: 4
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: -1

        model: Wallpapers.list

        delegate: DeckCard {
            id: card

            required property var modelData
            required property int index

            source: card.modelData.url
            label: card.modelData.name
            chosen: card.index === root.currentAt

            onClicked: Wallpapers.choose(card.modelData)
        }

        onCountChanged: Qt.callLater(root.reveal)
        Component.onCompleted: root.reveal()
    }

    // ── Sin fondos ──
    Column {
        anchors.centerIn: parent
        width: parent.width - 80
        visible: Wallpapers.loaded && Wallpapers.empty
        spacing: 10

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            icon: Theme.systemIcons.launcher.image
            size: 28
            color: Theme.glass.contentMuted
        }

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "Todavía no hay fondos"
            color: Theme.glass.content
            font.pixelSize: Theme.font.large
            font.weight: Font.Bold
        }

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: "Pon imágenes en " + Wallpapers.folder + " y aparecen aquí solas."
            color: Theme.glass.contentMuted
            font.pixelSize: 13
        }

        Item { width: 1; height: 4 }

        ChipButton {
            anchors.horizontalCenter: parent.horizontalCenter
            height: 30
            icon: Theme.systemIcons.launcher.files
            text: "Abrir la carpeta"
            onClicked: {
                Wallpapers.openFolder();
                root.dismissed();
            }
        }
    }
}
