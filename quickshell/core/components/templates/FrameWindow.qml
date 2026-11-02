// TEMPLATE: el marco de una pantalla.
//
// Una ventana de capa del tamaño del monitor que dibuja UNA figura negra:
// un marco delgado alrededor de todo, dos pestañas que bajan del borde de
// arriba (una en cada esquina), dos cajones que salen del marco (uno crece
// desde la pestaña derecha y otro sale del borde izquierdo, a media
// pantalla) y un panel lateral: el borde derecho, que engorda de arriba
// abajo (las notificaciones).
//
// No sabe qué lleva cada pestaña, cajón o panel: eso lo pone quien lo usa
// (modules/bar/BarFrame.qml) en cinco huecos. El template los mide, dibuja
// la figura alrededor y la anima. Igual que hacía BarWindow, así core no
// depende de ningún dominio.
//
// ── ¿Por qué una ventana del tamaño de la pantalla? ──────────────────────
//
// Porque la figura es una sola: el ala de una pestaña es parte del mismo
// trazo que el marco. Repartida en varias ventanas, cada una con su pedazo,
// habría que cambiar el tamaño de alguna (una superficie de Wayland) a media
// animación cada vez que se abre un cajón. El precio es un búfer de pantalla
// completa por monitor; casi todo transparente y quieto, así que Hyprland no
// lo vuelve a componer mientras no cambie nada. Lo que NO es pantalla
// completa es lo que recibe el ratón: ver `mask`.
//
// Esta ventana NO aparta ventanas (anclada a los cuatro bordes no puede):
// eso lo hacen cuatro EdgeReserve, una por borde.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core.theme
import qs.core.components.atoms

PanelWindow {
    id: root

    // ── Los cinco huecos ──────────────────────────────────────────────
    property alias leftTab: leftHolder.data
    property alias rightTab: rightHolder.data
    property alias rightPanel: rightPanelHolder.data
    property alias sidePanel: sidePanelHolder.data
    property alias notificationPanel: notificationHolder.data

    // Lo que mide cada cajón ya con su aire. Quien lo usa lo lee de su
    // contenido; 0 = no hay nada que enseñar.
    property real rightPanelWidth: 0
    property real rightPanelHeight: 0
    property real sidePanelWidth: 0
    property real sidePanelHeight: 0

    property bool rightPanelOpen: false
    property bool sidePanelOpen: false

    // El panel lateral. NO es modal: es una barra lateral que convive con
    // tus ventanas (ellas se apartan, ver EdgeReserve en Bar.qml). Un clic
    // afuera no lo cierra; se cierra con su botón.
    property bool notificationsOpen: false
    property real notificationsWidth: Theme.frame.notificationsWidth

    // ── Mecanismos (los de la barra de antes, más el marco) ───────────
    property bool framed: true            // marco visible: no en pantalla completa
    property bool autoHide: false         // las pestañas se esconden en la franja
    property bool aboveFullscreen: false  // capa overlay, encima de la pantalla completa
    property bool solid: false            // destapada, la franja de arriba es de lado a lado

    // Mientras sea true, las pestañas no se esconden.
    property bool keepRevealed: false

    property int hideDelay: 400
    property bool revealed: !root.autoHide

    // Algo que vive en este mismo borde (la isla) puede pedirle al marco que
    // no se quede con el ratón dentro de un rectángulo, en coordenadas de la
    // pantalla. Qt.rect(0, 0, 0, 0) = sin hueco.
    property rect cutout: Qt.rect(0, 0, 0, 0)

    // Hay un cajón abierto: el ratón y el teclado son del marco hasta que se
    // cierre, como un menú de macOS.
    readonly property bool modal: root.rightPanelOpen || root.sidePanelOpen

    // Un clic fuera de los cajones y las pestañas, o Escape. Quien lo usa
    // decide qué cerrar.
    signal dismissed()

    // Un cajón sigue en pantalla mientras se cierra: quien lo usa no debe
    // destruir su contenido hasta que esto sea false.
    readonly property bool rightPanelPresent: root.rightPanelOpen || root.rightProgress > 0.002
    readonly property bool sidePanelPresent: root.sidePanelOpen || root.sideProgress > 0.002
    readonly property bool notificationsPresent: root.notificationsOpen || root.notifProgress > 0.002

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "z0-frame"
    WlrLayershell.layer: root.aboveFullscreen ? WlrLayer.Overlay : WlrLayer.Top

    // Exclusive solo con un cajón abierto: Escape llega aquí y no a tu app.
    // Con el panel de notificaciones, OnDemand: el teclado es del marco solo
    // si haces clic en él (para escribir una respuesta); mientras no, sigue
    // en tu ventana. Cerrado, None: el marco nunca te quita el teclado.
    WlrLayershell.keyboardFocus: root.modal ? WlrKeyboardFocus.Exclusive
                               : root.notificationsOpen ? WlrKeyboardFocus.OnDemand
                               : WlrKeyboardFocus.None

    // ── Lo que se anima ───────────────────────────────────────────────
    //
    // Seis números de 0 a 1, como en el lienzo. La figura se calcula
    // mezclando lo cerrado con lo abierto (lerp) según cada uno, así una sola
    // animación mueve a la vez el ancho, el alto, las alas y las esquinas.
    //
    // Los cajones usan los dos muelles de la isla: abrir con OutBack (rebasa
    // un poco: el número pasa de 1 y la figura se estira un pelo más de la
    // cuenta) y cerrar con OutCubic (no rebasa).
    property real frameProgress: root.framed ? 1 : 0
    property real tabsProgress: root.revealed ? 1 : 0
    property real solidProgress: root.solid ? 1 : 0
    property real rightProgress: root.rightPanelOpen ? 1 : 0
    property real sideProgress: root.sidePanelOpen ? 1 : 0
    property real notifProgress: root.notificationsOpen ? 1 : 0

    Behavior on frameProgress {
        NumberAnimation {
            duration: Theme.frame.slideDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on tabsProgress {
        NumberAnimation {
            duration: Theme.frame.slideDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on solidProgress {
        NumberAnimation {
            duration: Theme.motion.duration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on rightProgress {
        NumberAnimation {
            duration: root.rightPanelOpen ? Theme.frame.openDuration : Theme.frame.closeDuration
            easing.type: root.rightPanelOpen ? Easing.OutBack : Easing.OutCubic
            easing.overshoot: Theme.frame.openOvershoot
        }
    }

    Behavior on sideProgress {
        NumberAnimation {
            duration: root.sidePanelOpen ? Theme.frame.openDuration : Theme.frame.closeDuration
            easing.type: root.sidePanelOpen ? Easing.OutBack : Easing.OutCubic
            easing.overshoot: Theme.frame.openOvershoot
        }
    }

    Behavior on notifProgress {
        NumberAnimation {
            duration: root.notificationsOpen ? Theme.frame.openDuration : Theme.frame.closeDuration
            easing.type: root.notificationsOpen ? Easing.OutBack : Easing.OutCubic
            easing.overshoot: Theme.frame.openOvershoot
        }
    }

    // El tamaño de un cajón ABIERTO también se anima: el Centro de control
    // cambia de alto al pasar a Wi-Fi, y el cajón derecho cambia de ancho al
    // ir del Centro de control al calendario. Mientras se abre, no: ahí el
    // crecimiento ya lo pone el progreso, y dos animaciones encima se notan.
    property real rightWidth: root.rightPanelWidth
    property real rightHeight: root.rightPanelHeight
    property real sideHeight: root.sidePanelHeight

    Behavior on rightWidth {
        enabled: root.rightProgress >= 0.99
        NumberAnimation {
            duration: Theme.frame.openDuration
            easing.type: Easing.OutBack
            easing.overshoot: Theme.frame.openOvershoot
        }
    }

    Behavior on rightHeight {
        enabled: root.rightProgress >= 0.99
        NumberAnimation {
            duration: Theme.frame.openDuration
            easing.type: Easing.OutBack
            easing.overshoot: Theme.frame.openOvershoot
        }
    }

    Behavior on sideHeight {
        enabled: root.sideProgress >= 0.99
        NumberAnimation {
            duration: Theme.frame.openDuration
            easing.type: Easing.OutBack
            easing.overshoot: Theme.frame.openOvershoot
        }
    }

    function lerp(a, b, t): real {
        return a + (b - a) * t;
    }

    // El contenido de un cajón entra cuando el cajón ya casi terminó de
    // abrirse (y se va en cuanto empieza a cerrarse). Sin esto, los botones
    // aparecerían enteros dentro de una figura que todavía está creciendo.
    function contentOpacity(progress): real {
        return Math.max(0, Math.min(1, (progress - 0.55) / 0.4));
    }

    // ── La geometría, animada ─────────────────────────────────────────
    readonly property real pad: Theme.frame.tabPadding
    readonly property real barHeight: Theme.glass.barHeight

    // Grosor del marco: lados, abajo y la franja de arriba.
    readonly property real thickness: Theme.frame.thickness * root.frameProgress

    // Hasta dónde bajan las pestañas: el marco más la barra.
    readonly property real tabDepth: root.thickness + root.barHeight * root.tabsProgress

    // La franja de arriba. Sólida, baja con las pestañas y se vuelve una
    // barra de lado a lado: las alas se encogen solas (FramePath.fit) porque
    // ya no hay escalón entre la franja y la pestaña.
    readonly property real band: root.lerp(root.thickness, root.tabDepth, root.solidProgress)

    readonly property real leftTabWidth: leftHolder.width + root.pad * 2
    readonly property real rightTabWidth: rightHolder.width + root.pad * 2

    // El cajón derecho nunca es más angosto que su pestaña.
    readonly property real rightOpenWidth: Math.max(root.rightTabWidth, root.rightWidth)

    readonly property real leftEdge: root.thickness + root.leftTabWidth
    readonly property real rightEdge: root.width - root.thickness
                                      - root.lerp(root.rightTabWidth, root.rightOpenWidth, root.rightProgress)
    readonly property real rightDepth: root.tabDepth + root.rightHeight * root.rightProgress

    readonly property real sideTop: Math.round((root.height - root.sideHeight) / 2)
    readonly property real sideEdge: root.thickness + root.sidePanelWidth * root.sideProgress

    // Cuánto engorda el borde derecho ahora mismo.
    readonly property real notifWidth: root.notificationsWidth * root.notifProgress

    // ── La geometría de DESTINO, para el ratón ────────────────────────
    //
    // La región de entrada se calcula con dónde van a quedar las cosas y no
    // con la animación: si siguiera cada fotograma, Hyprland recibiría una
    // región nueva sesenta veces por segundo para nada.
    readonly property int sideTarget: root.framed ? Theme.frame.thickness : 0
    readonly property int tabDepthTarget: root.sideTarget + Theme.glass.barHeight
    readonly property int bandTarget: root.revealed && root.solid ? root.tabDepthTarget : root.sideTarget
    readonly property int notifTarget: root.notificationsOpen ? Math.ceil(root.notificationsWidth) : 0

    // ── El ratón ──────────────────────────────────────────────────────
    //
    // Solo estas zonas reciben el ratón; fuera de ellas los clics pasan a
    // las ventanas de abajo. Las regiones hijas se suman (Combine, el modo
    // por defecto) y la última resta el hueco de la isla.
    mask: Region {
        // Con un cajón abierto, la pantalla entera: un clic afuera lo cierra.
        Region {
            width: root.modal ? root.width : 0
            height: root.modal ? root.height : 0
        }

        // La franja de arriba. Escondida, al menos una tira para destaparla.
        Region {
            width: root.width
            height: root.revealed ? root.bandTarget
                                  : Math.max(root.sideTarget, Theme.frame.revealStrip)
        }

        // Las dos pestañas.
        Region {
            width: root.revealed ? root.sideTarget + Math.ceil(root.leftTabWidth) : 0
            height: root.tabDepthTarget
        }

        Region {
            x: root.width - root.sideTarget - Math.ceil(root.rightTabWidth)
            width: root.revealed ? root.sideTarget + Math.ceil(root.rightTabWidth) : 0
            height: root.tabDepthTarget
        }

        // El panel de notificaciones, de arriba abajo.
        Region {
            x: root.width - root.sideTarget - root.notifTarget
            width: root.notifTarget > 0 ? root.sideTarget + root.notifTarget : 0
            height: root.height
        }

        // Los lados y abajo: lo que se ve, se toca.
        Region {
            width: root.sideTarget
            height: root.height
        }

        Region {
            x: root.width - root.sideTarget
            width: root.sideTarget
            height: root.height
        }

        Region {
            y: root.height - root.sideTarget
            width: root.width
            height: root.sideTarget
        }

        // El hueco de la isla: ella se queda con el ratón ahí, aunque las
        // dos ventanas estén en la misma capa (pantalla completa).
        Region {
            x: root.cutout.x
            y: root.cutout.y
            width: root.cutout.width
            height: root.cutout.height
            intersection: Intersection.Subtract
        }
    }

    // ── Esconderse y destaparse ───────────────────────────────────────
    readonly property bool holding: root.keepRevealed || root.modal || root.notificationsOpen

    onAutoHideChanged: {
        hideTimer.stop();
        root.revealed = !root.autoHide || root.holding;
    }

    // Al cerrarse lo que la mantenía visible, si el mouse ya no está
    // encima, empieza la cuenta para esconderse.
    onHoldingChanged: {
        if (root.holding) {
            hideTimer.stop();
            root.revealed = true;
        } else if (root.autoHide && !topHover.hovered) {
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: root.hideDelay
        onTriggered: {
            if (!root.holding)
                root.revealed = false;
        }
    }

    // ── Lo que se ve ──────────────────────────────────────────────────
    Item {
        id: stage

        anchors.fill: parent

        // Para Escape: el foco del teclado cae aquí cuando la ventana lo
        // recibe (solo con un cajón abierto).
        focus: true
        Keys.onEscapePressed: root.dismissed()

        // Lo de más abajo: con un cajón abierto, un clic en cualquier parte
        // que no sea un cajón ni una pestaña lo cierra. Al presionar y no al
        // soltar, como un menú.
        MouseArea {
            anchors.fill: parent
            enabled: root.modal
            acceptedButtons: Qt.AllButtons
            onPressed: root.dismissed()
        }

        FrameShape {
            anchors.fill: parent

            // Sin nada que dibujar (pantalla completa y escondida), ni se
            // intenta: el hueco sería la pantalla entera.
            visible: root.thickness > 0.01 || root.tabsProgress > 0.01
                     || root.rightProgress > 0.01 || root.sideProgress > 0.01

            fill: Theme.frame.fill

            band: root.band
            side: root.thickness
            topRadius: Theme.frame.screenRadius * Math.max(root.frameProgress, root.tabsProgress)
            bottomRadius: Theme.frame.screenRadius * root.frameProgress

            leftX: root.leftEdge
            leftDepth: root.tabDepth
            leftWing: Theme.frame.wing
            leftCorner: Theme.frame.corner

            rightX: root.rightEdge
            rightDepth: root.rightDepth
            rightWing: root.lerp(Theme.frame.wing, Theme.frame.drawerWing, root.rightProgress)
            rightCorner: root.lerp(Theme.frame.corner, Theme.frame.drawerCorner, root.rightProgress)

            drawerX: root.sideEdge
            drawerTop: root.sideTop
            drawerBottom: root.sideTop + root.sideHeight
            drawerWing: Theme.frame.wing
            drawerCorner: Theme.frame.menuCorner

            notificationsWidth: root.notifWidth
        }

        // ── El panel de notificaciones ──
        //
        // Como los cajones: el área es el panel tal como va en la animación
        // y recorta; el contenido está donde va a quedar y el panel lo va
        // destapando al crecer. Empieza debajo de la pestaña: arriba quedan
        // los botones de la pestaña, que ahora viven dentro del panel.
        Item {
            id: notificationArea

            x: root.width - root.thickness - root.notifWidth
            y: root.tabDepth
            width: Math.max(0, root.notifWidth)
            height: Math.max(0, root.height - root.tabDepth - root.thickness)
            clip: true

            visible: root.notificationsPresent

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            Item {
                id: notificationHolder

                x: root.notifWidth - root.notificationsWidth + 14 * (1 - opacity)
                width: root.notificationsWidth
                height: parent.height
                opacity: root.contentOpacity(root.notifProgress)
            }
        }

        // ── El cajón de la pestaña derecha ──
        //
        // El área es el cajón TAL COMO VA en la animación (su orilla y su
        // fondo se mueven), y recorta. El contenido no se mueve: está donde
        // va a quedar, y el cajón lo va destapando al crecer. Sin el
        // recorte, el contenido aparecería entero por fuera de una figura
        // que todavía no termina de abrirse.
        Item {
            id: rightPanelArea

            x: root.rightEdge
            y: root.tabDepth
            width: Math.max(0, root.width - root.thickness - root.rightEdge)
            height: Math.max(0, root.rightDepth - root.tabDepth)
            clip: true

            visible: root.rightPanelPresent

            // Un clic en el fondo del cajón no debe llegar a la capa de
            // abajo, que lo cerraría. Va antes que el contenido: queda debajo
            // y los botones se llevan sus clics primero.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            Item {
                id: rightPanelHolder

                // Centrado en el cajón abierto (el calendario es más angosto
                // que su pestaña), contado desde la orilla animada.
                x: Math.round(root.width - root.thickness - root.rightOpenWidth
                              + (root.rightOpenWidth - root.rightWidth) / 2 - rightPanelArea.x)
                y: -6 * (1 - opacity)
                width: root.rightWidth
                height: root.rightHeight
                opacity: root.contentOpacity(root.rightProgress)
            }
        }

        // ── El cajón del borde izquierdo ──
        Item {
            id: sidePanelArea

            x: root.thickness
            y: root.sideTop
            width: Math.max(0, root.sideEdge - root.thickness)
            height: root.sideHeight
            clip: true

            visible: root.sidePanelPresent

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            Item {
                id: sidePanelHolder

                x: -10 * (1 - opacity)
                width: root.sidePanelWidth
                height: root.sideHeight
                opacity: root.contentOpacity(root.sideProgress)
            }
        }

        // ── Las pestañas ──
        //
        // El detector de hover vive aquí, como ANCESTRO de los botones de las
        // dos pestañas: el hover llega primero a los botones y luego sube
        // hasta aquí. Un detector hermano competiría con ellos por el ratón.
        //
        // Cubre todo el ancho de arriba, pero solo siente al ratón donde la
        // máscara lo deja pasar: la franja y las pestañas, no el hueco de en
        // medio ni los lados.
        Item {
            id: topZone

            width: root.width
            height: root.revealed ? root.tabDepthTarget
                                  : Math.max(root.sideTarget, Theme.frame.revealStrip)

            HoverHandler {
                id: topHover

                onHoveredChanged: {
                    if (!root.autoHide)
                        return;

                    if (hovered) {
                        hideTimer.stop();
                        root.revealed = true;
                    } else if (!root.holding) {
                        hideTimer.restart();
                    }
                }
            }

            // Centrados en lo que baja la pestaña entera (marco incluido: todo
            // es el mismo negro), y al esconderse suben con ella.
            readonly property real itemsY: (root.thickness + root.barHeight) / 2
                                           - (1 - root.tabsProgress) * root.barHeight

            // El fondo de cada pestaña se queda con sus clics. Sin esto, con
            // un cajón abierto, el clic en un botón de la pestaña bajaría
            // también a la capa que cierra: el botón lo abriría y la capa lo
            // cerraría en el mismo clic. Van antes que los botones, así que
            // quedan debajo y los botones reciben primero.
            MouseArea {
                width: root.leftEdge
                height: root.tabDepth
                acceptedButtons: Qt.AllButtons
            }

            MouseArea {
                x: root.width - root.thickness - root.rightTabWidth
                width: root.thickness + root.rightTabWidth
                height: root.tabDepth
                acceptedButtons: Qt.AllButtons
            }

            Item {
                id: leftHolder

                x: root.thickness + root.pad
                y: Math.round(topZone.itemsY - height / 2)
                width: childrenRect.width
                height: childrenRect.height
                opacity: root.tabsProgress
            }

            Item {
                id: rightHolder

                x: root.width - root.thickness - root.pad - width
                y: Math.round(topZone.itemsY - height / 2)
                width: childrenRect.width
                height: childrenRect.height
                opacity: root.tabsProgress
            }
        }
    }
}
