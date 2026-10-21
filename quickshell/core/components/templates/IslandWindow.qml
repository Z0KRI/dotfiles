import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    // El item cuya forma recibe el ratón. null = la ventana no existe para el
    // escritorio y los clics la atraviesan.
    property Item maskItem: null

    default property alias content: contentHolder.data

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    color: "transparent"

    // No empuja ventanas. Es una isla flotante, no una barra.
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "z0-island"

    // `overlay` es la capa que se dibuja por encima de las ventanas en pantalla
    // completa. Por eso una notificación aparece encima de un vídeo o un juego
    // sin reglas especiales. (Si aun así no se ve: Hyprland puede estar usando
    // direct scanout, que se salta el compositor entero —
    // `hyprctl getoption render:direct_scanout`.)
    WlrLayershell.layer: WlrLayer.Overlay

    // Teclado bajo demanda, y solo en la ventana que enseña la island.
    //
    // Las superficies de layer-shell no reciben teclas salvo que lo pidan, así
    // que sin esto un campo de texto dentro de la island no escribe nada: ves
    // el cursor parpadear y no entra ni una letra.
    //
    // `OnDemand` y no `Exclusive`: el compositor solo le da el teclado si haces
    // clic dentro. Mientras no toques nada, las teclas siguen yendo a tu
    // ventana. El precio es que al hacer clic en la island tu aplicación pierde
    // el foco un momento; lo recupera cuando la island se va.
    WlrLayershell.keyboardFocus: root.maskItem !== null
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    mask: Region {
        item: root.maskItem
    }

    Item {
        id: contentHolder
        anchors.fill: parent
    }
}