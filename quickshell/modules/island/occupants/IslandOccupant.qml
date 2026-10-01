// El contrato de un ocupante: todo lo que el árbitro necesita saber de él.
//
// Es un QtObject y no un Item, y esa es la decisión importante del archivo. La
// LÓGICA vive una sola vez; la VISTA la instancia cada ventana desde `view`.
// Si el ocupante fuera un item visual habría una copia de su temporizador y de
// sus Connections por cada monitor, y con dos monitores el volumen se pediría
// dos veces.
//
// Vive junto a sus implementaciones, y no en la carpeta de arriba, para que un
// ocupante no tenga que importar el módulo que lo contiene.
//
// Y NO importa el tema a propósito. Esto define qué es un ocupante, no cómo se
// ve; sus valores por defecto son parte del contrato.

import QtQuick
import qs.domain.island

QtObject {
    id: root

    // Lo que se declare dentro de un ocupante —Timer, Connections— cae aquí.
    // Un QtObject no trae propiedad por defecto, así que hay que dársela.
    default property list<QtObject> resources

    required property string name

    // Gana el mayor. 0 sería el fondo de armario.
    property int priority: 50

    // ¿quiere la island ahora mismo?
    property bool active: false

    // ── plegado ───────────────────────────────────────────────────
    property int contentWidth: 185
    property int contentHeight: 32

    // La vista, instanciada por cada ventana. Al declararla DENTRO del archivo
    // del ocupante puede leer sus propiedades directamente: un Component se
    // lleva consigo el ámbito donde se escribió, no el del Loader que lo carga.
    property Component view: null

    // ── desplegado ────────────────────────────────────────────────
    property bool expandable: false
    property bool expanded: false

    property int expandedWidth: 640
    property int expandedHeight: 190
    property Component expandedView: null

    readonly property bool isExpanded: root.expandable && root.expanded

    // TEMPORAL — ¿llega el estado desplegado a existir?
    onIsExpandedChanged: console.log("[island]", root.name,
                                     "desplegado:", root.isExpanded,
                                     "| mide:", root.currentWidth, "x", root.currentHeight)

    // Lo que el cuerpo de la island tiene que medir y dibujar AHORA.
    readonly property int currentWidth: root.isExpanded ? root.expandedWidth
                                                        : root.contentWidth
    readonly property int currentHeight: root.isExpanded ? root.expandedHeight
                                                         : root.contentHeight
    readonly property Component currentView: root.isExpanded ? root.expandedView
                                                             : root.view

    // Desplegado, nadie le quita la island.
    readonly property int effectivePriority: root.isExpanded ? 1000 : root.priority

    function toggleExpanded(): void {
        if (root.expandable)
            root.expanded = !root.expanded;
    }

    function collapse(): void {
        hoverIn.stop();
        hoverOut.stop();
        root.expanded = false;
    }

    // ── abrir al pasar el ratón ───────────────────────────────────
    //
    // Los dos retardos no son adorno. Sin el de entrada, cruzar la pantalla por
    // arriba te abre la tarjeta de golpe; sin el de salida, rozar el borde
    // mientras bajas el ratón la cierra a media animación. Los 300 ms de
    // entrada son el `minimumHoverDuration` de Boring Notch.
    property bool expandOnHover: false
    property int hoverEnterDelay: 300
    property int hoverExitDelay: 380

    readonly property bool pointerInside: IslandState.hovered
                                          && IslandState.occupant === root.name

    onPointerInsideChanged: {
        // TEMPORAL
        console.log("[island]", root.name,
                    "ratón dentro:", root.pointerInside,
                    "| desplegable:", root.expandable,
                    "| por hover:", root.expandOnHover,
                    "| retardo:", root.hoverEnterDelay);

        if (!root.expandable || !root.expandOnHover)
            return;

        if (root.pointerInside) {
            hoverOut.stop();
            hoverIn.restart();
            return;
        }

        hoverIn.stop();
        hoverOut.restart();
    }

    property Timer _hoverIn: Timer {
        id: hoverIn
        interval: root.hoverEnterDelay
        repeat: false

        onTriggered: {
            // TEMPORAL — si esta línea no sale, el ratón se fue antes de los
            // 300 ms y el temporizador se paró.
            console.log("[island]", root.name, "dispara el despliegue");
            root.expanded = true;
        }
    }

    property Timer _hoverOut: Timer {
        id: hoverOut
        interval: root.hoverExitDelay
        repeat: false
        onTriggered: root.expanded = false
    }

    // ── los que se van solos ──────────────────────────────────────
    //
    // `poke()` pide la island por `timeout` ms y cada llamada reinicia la
    // cuenta. El reloj no corre mientras el ratón esté encima ni con la vista
    // desplegada: nadie quiere que se le cierre en la cara lo que está mirando.
    //
    // Se llama `ephemeral` y no `transient` porque esa segunda es palabra
    // reservada: QML hereda de JavaScript un montón de nombres que ES3 reservó
    // "para el futuro" y nunca liberó.
    property bool ephemeral: false
    property int timeout: 2200

    function poke(): void {
        root.active = true;
        if (root.ephemeral)
            retreat.restart();
    }

    function retreatNow(): void {
        retreat.stop();
        root.active = false;
    }

    property Timer _retreat: Timer {
        id: retreat
        interval: root.timeout
        repeat: false

        onTriggered: {
            const busy = root.isExpanded || root.pointerInside;

            if (busy) {
                retreat.restart();
                return;
            }
            root.active = false;
        }
    }
}