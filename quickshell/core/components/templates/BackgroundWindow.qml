// TEMPLATE: el fondo de pantalla de un monitor.
//
// Una ventana de capa en la capa de más abajo (Background), debajo de todas
// las ventanas, que pinta una imagen llenando la pantalla (recortada, no
// estirada). No recibe el ratón ni el teclado.
//
// Al cambiar de imagen, la nueva entra con un fundido encima de la vieja,
// como en el lienzo. Por eso hay DOS imágenes: la que se ve y la que se está
// cargando. Cuando la nueva ya cargó, se desvanece hacia adentro, y al
// terminar la vieja se suelta para no tener dos fondos en memoria.
//
// Sin imagen (`source` vacío), la ventana no existe y se ve el fondo de
// Hyprland.

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property string source: ""

    property int fadeDuration: 500

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    visible: root.source !== ""
    exclusionMode: ExclusionMode.Ignore
    color: "black"

    WlrLayershell.namespace: "z0-wallpaper"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Una región vacía: los clics la atraviesan.
    mask: Region {}

    // Decodificar al tamaño de la pantalla y no al de la imagen: un fondo de
    // 6000 px ocupa en memoria lo que mide la pantalla, no lo que mide él.
    readonly property size decodeSize: root.screen
        ? Qt.size(root.screen.width * (root.screen.devicePixelRatio || 1),
                  root.screen.height * (root.screen.devicePixelRatio || 1))
        : Qt.size(0, 0)

    // Cuál de las dos se ve (0 o 1) y cuál se está cargando (-1: ninguna).
    property int shown: -1
    property int pending: -1

    readonly property var layers: [first, second]

    onSourceChanged: root.load()
    Component.onCompleted: root.load()

    function load(): void {
        if (root.source === "")
            return;

        const current = root.shown >= 0 ? root.layers[root.shown] : null;
        if (current && String(current.source) === root.source && root.pending < 0)
            return;

        // La que no se ve recibe la nueva, encima y transparente.
        const next = root.shown === 0 ? 1 : 0;
        const image = root.layers[next];

        fade.stop();
        image.opacity = 0;
        image.z = 1;
        if (current)
            current.z = 0;

        root.pending = next;
        image.source = root.source;

        if (image.status === Image.Ready)
            root.reveal();
    }

    function reveal(): void {
        if (root.pending < 0)
            return;

        fade.target = root.layers[root.pending];
        root.shown = root.pending;
        root.pending = -1;
        fade.restart();
    }

    function settle(): void {
        // La que quedó atrás ya no se ve: se suelta.
        const other = root.layers[root.shown === 0 ? 1 : 0];
        other.source = "";
    }

    NumberAnimation {
        id: fade

        property: "opacity"
        from: 0
        to: 1
        duration: root.fadeDuration
        easing.type: Easing.InOutQuad

        onFinished: root.settle()
    }

    Image {
        id: first

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        sourceSize: root.decodeSize
        opacity: 0

        onStatusChanged: {
            if (root.pending === 0 && status === Image.Ready)
                root.reveal();
        }
    }

    Image {
        id: second

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        sourceSize: root.decodeSize
        opacity: 0

        onStatusChanged: {
            if (root.pending === 1 && status === Image.Ready)
                root.reveal();
        }
    }
}
