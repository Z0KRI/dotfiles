// La feature de Ajustes. Siempre viva, pero la ventana solo existe mientras
// está abierta (LazyLoader), igual que tu launcher.
//
// Por IPC, para el atajo y el .desktop:
//   qs ipc call settings toggle
//   qs ipc call settings open
//   qs ipc call settings go wifi
//   qs ipc call settings close

import QtQuick
import Quickshell
import Quickshell.Io
import qs.domain.settings
import qs.domain.desktop
import qs.domain.keyboard

Scope {
    id: root

    IpcHandler {
        target: "settings"

        function toggle(): void {
            SettingsControl.toggle();
        }

        function open(): void {
            SettingsControl.open("");
        }

        function go(section: string): void {
            SettingsControl.open(section);
        }

        function close(): void {
            SettingsControl.close();
        }
    }

    // Despierta al arrancar los dominios que APLICAN una preferencia guardada
    // (modo oscuro, acento y vidrio; brillo; luz nocturna). Un singleton se
    // crea la primera vez que alguien lo toca: si nadie los tocara hasta abrir
    // Ajustes, tu luz nocturna no volvería sola después de reiniciar.
    //
    // AppleKeyboard por lo mismo: le pone ⌘ y ⌥ cambiadas a un teclado Apple
    // que conectes por primera vez (o por cable), aunque Ajustes no se abra.
    readonly property var awake: [Appearance.dark, Brightness.value, NightLight.enabled,
                                  AppleKeyboard.swapCommandOption]

    LazyLoader {
        active: SettingsControl.shown

        component: SettingsWindow {}
    }
}
