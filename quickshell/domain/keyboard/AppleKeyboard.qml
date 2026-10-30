// CASO DE USO: las opciones de los teclados Apple.
// Reglas:
//   - Solo existen mientras haya un teclado Apple conectado (de verdad: los
//     genéricos que se hacen pasar por Apple no cuentan, ver Keyboards). Con
//     tu Dell o tu ROG no hay nada que cambiar, y Ajustes no las enseña.
//   - Teclas de función estándar: es del driver hid_apple (fnmode 2; apagado,
//     3 = automático, como macOS). Es del kernel: pide tu contraseña. Solo
//     cambia a los Apple: a los genéricos que usan ese driver el kernel ya
//     les pone F1–F12 primero en los dos casos.
//   - ⌘ y ⌥ intercambiadas: NO es del driver, aunque el driver sabe hacerlo,
//     porque ahí también intercambiaría las teclas de esos genéricos. Es una
//     opción de xkb solo para cada teclado Apple (altwin:swap_lalt_lwin, en
//     hosts/keyboard.lua): la ⌥ izquierda pasa a ser SUPER y la ⌘ izquierda
//     Alt, como en un teclado de PC. Las de la derecha se quedan: la ⌥ derecha
//     sigue siendo AltGr (@, #, [ ] en latam). No pide contraseña. Se recuerda
//     y se aplica solo a cualquier teclado Apple que conectes, también por
//     cable (con otro nombre en Hyprland).
//   - ° y < (iso_layout del driver): automático (-1) / no (0) / sí (1). Con
//     "sí", el driver también las cambia en esos genéricos; si hay uno
//     conectado, Ajustes lo advierte.
//   - Qué teclados hay, su batería, su distribución y los avisos son de
//     Keyboards: un teclado Apple es un teclado más.

pragma Singleton

import QtQuick
import Quickshell
import qs.data.keyboard
import qs.data.hyprland
import qs.data.system

Singleton {
    id: root

    readonly property var keyboards: Keyboards.list.filter(keyboard => keyboard.apple)
    readonly property bool connected: root.keyboards.length > 0

    // Genéricos conectados que usan el driver de Apple.
    readonly property var lookalikes: Keyboards.list.filter(keyboard => keyboard.lookalike)

    // /sys no avisa: se lee al abrir Ajustes › Teclado y al conectar uno.
    function refresh(): void {
        HidAppleRepository.refresh();
    }

    // Al crearse ya puede haber uno conectado: eso no es un "cambio" y
    // onConnectedChanged no se dispararía.
    onConnectedChanged: {
        if (root.connected)
            root.refresh();
    }

    Component.onCompleted: {
        if (root.connected)
            root.refresh();
    }

    readonly property bool driverLoaded: HidAppleRepository.loaded
    readonly property bool applying: HidAppleRepository.applying
    readonly property string lastError: HidAppleRepository.lastError

    // ── teclas de función y ° < (el driver) ───────────────────────

    readonly property bool functionKeys: HidAppleRepository.fnmode === 2 || HidAppleRepository.fnmode === 0
    readonly property bool hasIsoOption: HidAppleRepository.hasIsoLayout
    readonly property string isoMode: HidAppleRepository.isoLayout < 0 ? "auto"
                                    : HidAppleRepository.isoLayout === 0 ? "normal" : "swapped"

    // swap_opt_cmd del driver siempre va en 0: ⌘ y ⌥ ya no se cambian ahí.
    // Si alguien lo había prendido (una versión anterior de esta página), su
    // efecto pasa a la preferencia de abajo antes de apagarlo.
    function applyDriver(fnmode, iso): void {
        if (HidAppleRepository.swapOptCmd !== 0 && !PreferencesRepository.keyboardSwapCommand) {
            PreferencesRepository.keyboardSwapCommand = true;
            root.sync();
        }
        HidAppleRepository.apply(fnmode, 0, iso);
    }

    function currentIso(): int {
        return HidAppleRepository.hasIsoLayout ? HidAppleRepository.isoLayout : -1;
    }

    function setFunctionKeys(on): void {
        root.applyDriver(on ? 2 : 3, root.currentIso());
    }

    function setIsoMode(mode): void {
        const iso = mode === "normal" ? 0 : mode === "swapped" ? 1 : -1;
        root.applyDriver(root.functionKeys ? 2 : 3, iso);
    }

    // ── ⌘ y ⌥ (xkb, por teclado) ──────────────────────────────────

    readonly property string swapOption: "altwin:swap_lalt_lwin"

    // Lo que quieres; el driver viejo prendido también cuenta (cambia las
    // teclas aunque no lo hayas elegido aquí).
    readonly property bool swapCommandOption: PreferencesRepository.keyboardSwapCommand
                                              || HidAppleRepository.swapOptCmd !== 0

    function setSwapCommandOption(on): void {
        PreferencesRepository.keyboardSwapCommand = on;

        if (on) {
            root.sync();
            return;
        }

        // Apagado: fuera de todas las reglas que lo tengan, también las de
        // teclados Apple desconectados (si no, al volver lo traerían). Y si el
        // driver viejo lo tenía, se apaga ahí también (pide contraseña).
        const names = Object.keys(KeyboardRulesRepository.rules)
            .filter(name => KeyboardRulesRepository.rules[name].options === root.swapOption);
        KeyboardRulesRepository.update(names, { options: "" });

        if (HidAppleRepository.swapOptCmd !== 0)
            HidAppleRepository.apply(root.functionKeys ? 2 : 3, 0, root.currentIso());
    }

    // Cada teclado Apple conectado con lo que quieres. Corre al conectar uno
    // (si es nuevo para Hyprland, todavía no tiene su regla) y al cambiar la
    // preferencia. No se repite: una vez puesta la regla, ya coincide.
    function sync(): void {
        const wanted = PreferencesRepository.keyboardSwapCommand ? root.swapOption : "";
        for (const keyboard of root.keyboards) {
            if (keyboard.options !== wanted)
                Keyboards.updateRule(keyboard, { options: wanted });
        }
    }

    // Después y no ya: poner la regla cambia la lista de teclados, y esa
    // lista es justo la que acaba de avisar (QML lo vería como un ciclo).
    onKeyboardsChanged: Qt.callLater(root.sync)
}
