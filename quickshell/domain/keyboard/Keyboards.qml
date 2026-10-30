// CASO DE USO: los teclados conectados, de cualquier marca: el Apple, el Dell
// de la oficina, el ROG Strix Scope, el de una laptop.
// Reglas:
//   - Un teclado = un aparato, aunque el sistema lo vea en pedazos. Un
//     teclado USB suele salir tres veces en Hyprland (las letras, las teclas
//     multimedia, las de apagado): se juntan por dónde están conectados (USB)
//     o por su MAC (Bluetooth).
//   - Solo cuenta lo que tiene letras: una cámara con un botón o unos
//     audífonos con teclas multimedia también le salen a Hyprland como
//     "teclados", y no lo son; un mouse gamer con macros, tampoco. El botón
//     de encendido y similares tampoco (no son USB, Bluetooth ni el teclado
//     integrado).
//   - El nombre: el de Bluetooth si es Bluetooth (el que le pusiste); el del
//     fabricante si es USB, sin la marca repetida ("Dell Dell USB…" → "Dell
//     USB…"); "Teclado integrado" el de una laptop.
//   - "Apple" = lo maneja hid_apple, el driver de Apple, y no es uno de los
//     que se hacen pasar por Apple. Algunos genéricos (los de chip SONiX, un
//     Keychron en modo Mac…) usan el número de fabricante de Apple y el kernel
//     les pone ese mismo driver; el kernel los reconoce por su nombre y aquí
//     se usa su misma lista. Solo los Apple de verdad ven las opciones de
//     AppleKeyboard (la tecla fn, ⌘ y ⌥). Un Dell o un ROG ni siquiera pasan
//     por ese driver.
//   - Se vuelve a mirar al conectar o desconectar algo (el kernel avisa, ver
//     InputRepository), por cable o Bluetooth.
//   - Distribución por teclado: cada uno puede tener la suya; sin regla, la
//     del equipo (hosts/<equipo>.lua). En un teclado Apple, España e Inglés
//     usan la variante "mac" (los símbolos donde los imprime Apple).
//   - Avisos de la isla, para cualquier teclado Bluetooth, una vez por
//     conexión: al conectarse, y al bajar de 20 % y de 10 % sin cargar. Al
//     arrancar la shell no se avisa de lo que ya estaba conectado.

pragma Singleton

import QtQuick
import Quickshell
import qs.data.keyboard
import qs.data.hyprland
import qs.domain.bluetooth

Singleton {
    id: root

    // ── los teclados ──────────────────────────────────────────────

    // [{ id, name, bus, apple, lookalike, names, address, battery, charging, layout, options }]
    //   bus: usb | bluetooth | internal
    //   apple: un teclado Apple de verdad
    //   lookalike: un genérico que se hace pasar por Apple (usa hid_apple)
    //   names: sus nombres en Hyprland (para las reglas)
    //   layout: el id de su distribución (ver `layouts`), "system" o "custom"
    //   options: sus opciones de xkb propias (ej. ⌘ y ⌥ cambiadas), o ""
    readonly property var list: {
        const nodes = InputRepository.devices;
        const groups = {};
        const order = [];

        for (const keyboard of KeyboardRulesRepository.keyboards) {
            const node = root.nodeFor(keyboard.name, nodes);
            if (!node || node.bus === "other")
                continue;

            const key = root.groupKey(node);
            let group = groups[key];
            if (!group) {
                group = { id: key, bus: node.bus, uniq: node.uniq, nodes: [], names: [] };
                groups[key] = group;
                order.push(key);
            }
            group.names.push(keyboard.name);
            group.nodes.push(node);
        }

        return order
            .map(key => groups[key])
            .filter(group => group.nodes.some(node => node.letters) && !root.isMouse(group))
            .map(group => root.describe(group));
    }

    // Los mouses "gamer" traen un teclado completo de mentira para sus
    // macros ("Logitech G502 HERO Gaming Mouse Keyboard"). Pasan la prueba de
    // las letras, pero se llaman mouse. Los combos de teclado y mouse no
    // cuentan como mouse.
    function isMouse(group): bool {
        const typing = group.nodes.filter(node => node.letters);
        return typing.every(node => /\bmouse\b/i.test(node.name)
                                    && !/keyboard\s*(and|&|\+|y)\s*mouse|receiver|receptor/i.test(node.name));
    }

    readonly property bool connected: root.list.length > 0

    function refresh(): void {
        KeyboardRulesRepository.refresh();
        InputRepository.refresh();
    }

    // Cuando Hyprland ve otro teclado (o deja de verlo), se vuelve a leer
    // /sys para saber cuál es.
    readonly property string hyprNames: KeyboardRulesRepository.keyboards.map(k => k.name).join("\n")
    onHyprNamesChanged: InputRepository.refresh()

    // Al conectar o desconectar algo, el kernel manda varios avisos seguidos
    // (uno por pedazo del aparato) y Hyprland tarda un instante en verlo: se
    // espera a que se calme y se lee una sola vez.
    Connections {
        target: InputRepository

        function onChanged() {
            settle.restart();
        }
    }

    Timer {
        id: settle
        interval: 700
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()

    // ── Apple o no ────────────────────────────────────────────────

    // La lista del kernel (drivers/hid/hid-apple.c, `non_apple_keyboards`):
    // teclados de otras marcas que se presentan como Apple. El kernel los
    // compara por el principio del nombre, y aquí igual.
    readonly property var lookalikeNames: [
        "SONiX KN85 Keyboard", "SONiX USB DEVICE", "SONiX AK870 PRO", "Keychron", "AONE",
        "GANSS", "Hailuck", "Jamesdonkey", "A3R", "hfd.cn", "WKB603", "TH87",
        "HFD Epomaker TH87", "2.4G Wireless Receiver", "Thock TKL Wireless", "USB Dongle",
        "HFD GS3104T PRO", "GS3104T-PRO 2.4G", "GS3104T PRO"
    ]

    function isLookalike(node): bool {
        if (root.lookalikeNames.some(prefix => node.name.indexOf(prefix) === 0))
            return true;
        // El Omoton KB066 usa el número de modelo de un teclado Apple de aluminio.
        return node.product === "022c" && node.name === "Bluetooth Keyboard";
    }

    // El nombre que Hyprland le da a un dispositivo: minúsculas, y espacios y
    // comas como guiones. Solo las letras ASCII: Hyprland no cambia las demás
    // (la Ø de "ZØKRI" se queda Ø), y JavaScript sí lo haría.
    function hyprName(name): string {
        return String(name).replace(/[A-Z]/g, c => c.toLowerCase()).replace(/[ \n,]/g, "-");
    }

    // Qué nodo de /sys es este teclado de Hyprland. Si dos se llaman igual,
    // Hyprland numera los repetidos en el orden en que aparecen ("x",
    // "x-1", "x-2"), y /sys los numera en ese mismo orden.
    function nodeFor(name, nodes) {
        const exact = nodes.filter(node => root.hyprName(node.name) === name);
        if (exact.length > 0)
            return exact[0];

        const numbered = /^(.*)-(\d+)$/.exec(name);
        if (!numbered)
            return null;

        const same = nodes.filter(node => root.hyprName(node.name) === numbered[1]);
        return same[parseInt(numbered[2])] ?? same[same.length - 1] ?? null;
    }

    // Los pedazos de un mismo aparato comparten esto: la MAC por Bluetooth;
    // por USB, el puerto ("usb-0000:00:14.0-2/input1" → "usb-0000:00:14.0-2").
    function groupKey(node): string {
        if (node.bus === "bluetooth" && node.uniq !== "")
            return "bluetooth:" + node.uniq;
        if (node.phys !== "")
            return node.bus + ":" + node.phys.replace(/\/input\d+(:\d+)?$/, "");
        return "name:" + node.name;
    }

    function describe(group) {
        const bluetooth = group.bus === "bluetooth"
            ? (BluetoothControl.devices.find(d => d.address.toLowerCase() === group.uniq) ?? null)
            : null;
        const appleDriver = group.nodes.filter(node => node.driver === "apple");
        const lookalike = appleDriver.length > 0 && appleDriver.some(node => root.isLookalike(node));
        const apple = appleDriver.length > 0 && !lookalike;

        return {
            id: group.id,
            name: root.labelFor(group, bluetooth),
            bus: group.bus,
            apple: apple,
            lookalike: lookalike,
            names: group.names,
            nodeNames: group.nodes.map(node => root.hyprName(node.name)),
            address: bluetooth ? bluetooth.address : "",
            battery: bluetooth ? bluetooth.battery : -1,
            charging: bluetooth ? bluetooth.charging : false,
            layout: root.choiceFor(root.ruleFor(group.names), apple),
            options: root.ruleFor(group.names)?.options ?? ""
        };
    }

    function labelFor(group, bluetooth): string {
        if (bluetooth)
            return bluetooth.name;
        if (group.bus === "internal")
            return "Teclado integrado";

        // El más corto de los que tienen letras: "ASUSTeK ROG STRIX SCOPE" y
        // no "ASUSTeK ROG STRIX SCOPE Keyboard".
        const typing = group.nodes.filter(node => node.letters);
        const pool = (typing.length > 0 ? typing : group.nodes).map(node => node.name);
        const shortest = pool.reduce((a, b) => b.length < a.length ? b : a);

        const words = shortest.trim().split(/\s+/);
        if (words.length > 2 && words[0].toLowerCase() === words[1].toLowerCase())
            words.shift();
        return words.join(" ");
    }

    function busLabel(keyboard): string {
        if (keyboard.bus === "bluetooth")
            return "Bluetooth";
        if (keyboard.bus === "internal")
            return "Integrado";
        return "Por cable o receptor";
    }

    // ── distribución ──────────────────────────────────────────────

    // `macVariant` es la que se usa en un teclado Apple.
    readonly property var layouts: [
        { id: "system", label: "La del equipo" },
        { id: "latam", label: "Español (Latinoamérica)", layout: "latam", variant: "", macVariant: "" },
        { id: "es", label: "Español (España)", layout: "es", variant: "", macVariant: "mac" },
        { id: "us", label: "Inglés (EE. UU.)", layout: "us", variant: "", macVariant: "mac" },
        { id: "us-intl", label: "Inglés internacional", layout: "us", variant: "altgr-intl", macVariant: "altgr-intl",
          note: "ñ y acentos con AltGr" }
    ]

    // La del equipo: la que reporta Hyprland para un teclado sin regla.
    readonly property string systemLayout: {
        const free = KeyboardRulesRepository.keyboards
            .find(k => KeyboardRulesRepository.rules[k.name]?.layout === undefined);
        return free ? free.layout : "";
    }

    // Las opciones con su detalle para este teclado ("es · mac" en uno Apple).
    function optionsFor(keyboard) {
        return root.layouts.map(option => {
            if (option.id === "system")
                return Object.assign({}, option, {
                    detail: root.systemLayout !== "" ? root.systemLayout + " · la de hosts/<equipo>.lua"
                                                     : "La de hosts/<equipo>.lua"
                });
            const variant = keyboard && keyboard.apple ? option.macVariant : option.variant;
            const code = option.layout + (variant !== "" ? " · " + variant : "");
            return Object.assign({}, option, { detail: option.note ? code + " — " + option.note : code });
        });
    }

    function labelOf(choiceId): string {
        if (choiceId === "custom")
            return "Personalizada";
        return root.layouts.find(option => option.id === choiceId)?.label ?? "";
    }

    function ruleFor(names) {
        for (const name of names) {
            const rule = KeyboardRulesRepository.rules[name];
            if (rule)
                return rule;
        }
        return null;
    }

    function choiceFor(rule, apple): string {
        // Una regla puede ser solo de opciones (⌘ y ⌥): la distribución sigue
        // siendo la del equipo.
        if (!rule || rule.layout === undefined)
            return "system";
        const variant = rule.variant || "";
        const match = root.layouts.find(option => option.layout === rule.layout
                                                  && (variant === option.variant || variant === option.macVariant));
        return match ? match.id : "custom";
    }

    // Los nombres a los que va la regla: los de ahora y, de los numerados, el
    // de base ("magic-keyboard-1" → también "magic-keyboard"). Hyprland
    // numera según qué más esté conectado; así la regla sigue valiendo la
    // próxima vez aunque le toque otro número.
    function ruleNames(keyboard) {
        const out = [];
        for (const name of keyboard.names) {
            if (out.indexOf(name) < 0)
                out.push(name);
            const numbered = /^(.*)-(\d+)$/.exec(name);
            if (numbered && keyboard.nodeNames.indexOf(numbered[1]) >= 0 && out.indexOf(numbered[1]) < 0)
                out.push(numbered[1]);
        }
        return out;
    }

    // Cambia la regla de un teclado, en todos sus nombres (ver `update` en
    // KeyboardRulesRepository). Al quitar algo, también en los otros números
    // con que Hyprland lo haya visto antes.
    function updateRule(keyboard, patch): void {
        const names = root.ruleNames(keyboard);
        if (patch.layout === "" || patch.options === "") {
            for (const name of Object.keys(KeyboardRulesRepository.rules)) {
                const numbered = /^(.*)-(\d+)$/.exec(name);
                if (numbered && keyboard.nodeNames.indexOf(numbered[1]) >= 0 && names.indexOf(name) < 0)
                    names.push(name);
            }
        }
        KeyboardRulesRepository.update(names, patch);
    }

    function setLayout(keyboardId, choiceId): void {
        const keyboard = root.list.find(k => k.id === keyboardId);
        if (!keyboard || choiceId === keyboard.layout)
            return;

        if (choiceId === "system") {
            root.updateRule(keyboard, { layout: "" });
            return;
        }

        const option = root.layouts.find(o => o.id === choiceId);
        if (option)
            root.updateRule(keyboard, {
                layout: option.layout,
                variant: keyboard.apple ? option.macVariant : option.variant
            });
    }

    // ── avisos de la isla ─────────────────────────────────────────

    // [{ address, name, battery, charging }]
    readonly property var bluetooth: BluetoothControl.connected
        .filter(device => device.kind === "keyboard")
        .map(device => ({
            address: device.address,
            name: device.name,
            battery: device.battery,
            charging: device.charging
        }))

    signal arrived(var keyboard)
    signal lowBattery(var keyboard)

    readonly property var thresholds: [0.2, 0.1]

    // address → el umbral más bajo ya avisado (1 = ninguno).
    property var _warned: ({})
    property bool _armed: false

    Timer {
        interval: 3000
        running: true
        onTriggered: {
            // Lo que ya estaba al arrancar cuenta como visto.
            root._warned = root.seen(root.bluetooth, {});
            root._armed = true;
        }
    }

    function seen(list, previous) {
        const next = {};
        for (const keyboard of list)
            next[keyboard.address] = previous[keyboard.address] ?? root.levelFor(keyboard);
        return next;
    }

    // Al conectarse ya bajo (ej. 15 %), el aviso de conexión lo enseña en
    // rojo: ese umbral ya no se repite.
    function levelFor(keyboard): real {
        let level = 1;
        for (const threshold of root.thresholds) {
            if (keyboard.battery >= 0 && !keyboard.charging && keyboard.battery <= threshold)
                level = threshold;
        }
        return level;
    }

    onBluetoothChanged: {
        if (!root._armed)
            return;

        const previous = root._warned;
        for (const keyboard of root.bluetooth) {
            if (previous[keyboard.address] === undefined) {
                root.arrived(keyboard);
                continue;
            }

            if (keyboard.battery < 0 || keyboard.charging)
                continue;

            const next = root.levelFor(keyboard);
            if (next < previous[keyboard.address]) {
                previous[keyboard.address] = next;
                root.lowBattery(keyboard);
            }
        }
        // Los que se fueron se olvidan: al volver, otra vez se avisa.
        root._warned = root.seen(root.bluetooth, previous);
    }
}
