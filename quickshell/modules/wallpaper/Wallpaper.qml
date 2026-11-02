// La feature de los fondos de pantalla:
//   - el fondo de cada monitor (BackgroundWindow), con fundido al cambiar;
//   - el selector, un cajón de tarjetas que sale del borde de abajo (como
//     Mission Control). Se abre desde el menú del sistema: «Fondo de
//     pantalla…».
//
// Los fondos son las imágenes de ~/Pictures/Wallpapers: se agregan y se
// quitan solos (data/wallpaper/WallpaperRepository).
//
// Por IPC:
//   qs ipc call wallpaper toggle|open|close   el selector
//   qs ipc call wallpaper next|previous       el siguiente / anterior

import QtQuick
import Quickshell
import Quickshell.Io

import qs.core.theme
import qs.core.components.templates
import qs.domain.desktop

Scope {
    id: root

    IpcHandler {
        target: "wallpaper"

        function toggle(): void {
            Wallpapers.toggle();
        }
        function open(): void {
            Wallpapers.open();
        }
        function close(): void {
            Wallpapers.close();
        }
        function next(): void {
            Wallpapers.step(1);
        }
        function previous(): void {
            Wallpapers.step(-1);
        }
    }

    // El fondo, uno por monitor. El mismo en todos.
    Variants {
        model: Quickshell.screens

        BackgroundWindow {
            required property var modelData

            screen: modelData
            source: Wallpapers.source
        }
    }

    // El selector.
    DrawerWindow {
        id: drawer

        namespace: "z0-wallpapers"
        attach: "bottom"
        open: Wallpapers.shown

        // Cuántas tarjetas caben a lo ancho, con aire a los lados. Con más
        // fondos que eso, el cajón se desplaza de lado (rueda o flechas).
        readonly property int fits: Theme.deckFits(drawer.width, 160)

        bodyWidth: Wallpapers.empty
            ? 560
            : Theme.deckWidth(Math.min(Wallpapers.list.length, drawer.fits))
        bodyHeight: Theme.frame.deckHeight
        closedWidth: Theme.frame.deckClosedWidth

        bottomInset: BarVisibility.focusedFramed ? Theme.frame.thickness : 0

        onDismissed: Wallpapers.close()

        Loader {
            anchors.fill: parent
            active: drawer.present

            sourceComponent: WallpaperPanel {
                onDismissed: Wallpapers.close()
            }
        }
    }
}
