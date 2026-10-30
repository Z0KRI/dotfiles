// CASO DE USO: emparejar un dispositivo Bluetooth, con su código si lo pide.
// Lo usa Ajustes › Bluetooth (botón "Conectar" de los cercanos) y lo enseña
// la hoja de emparejamiento de la ventana de Ajustes.
//
// Reglas:
//   - Uno a la vez, como en BlueZ. Pedir otro mientras hay uno en curso no
//     hace nada.
//   - Lo que se enseña depende de lo que pida el aparato:
//       pin, passkey          "Escribe este código en «X» y presiona Retorno".
//                             Con passkey se marca cada dígito que tecleas.
//       confirm               "¿«X» muestra este mismo código?" (teléfonos,
//                             computadoras): Emparejar o Rechazar.
//       enter-pin, -passkey   un campo para escribir TÚ el código del aparato.
//       starting              antes de que pida nada: "Conectando con «X»…".
//   - Si sale bien, la hoja se cierra sola: el aviso lo da la isla.
//   - Si falla, se dice por qué con palabras, y se puede reintentar. Si lo
//     cancelaste o rechazaste tú, no hay nada que avisar: solo se cierra.
//   - Cerrar Ajustes a media espera cancela, como cerrar el diálogo en macOS.

pragma Singleton

import QtQuick
import Quickshell
import qs.data.bluetooth
import qs.domain.settings

Singleton {
    id: root

    // idle | starting | pin | passkey | confirm | enter-pin | enter-passkey | failed
    property string stage: "idle"

    property string address: ""
    property string name: ""
    property string kind: "bluetooth"

    // El código a enseñar, y cuántos dígitos llevas tecleados (-1 = el
    // aparato no lo informa: con PIN clásico BlueZ no se entera).
    property string code: ""
    property int entered: -1

    property string errorText: ""

    readonly property bool shown: root.stage !== "idle"
    readonly property bool busy: root.shown && root.stage !== "failed"

    // ¿cuál se está emparejando? Para el "Emparejando…" de la lista.
    function isPairing(address): bool {
        return root.busy && root.address === address;
    }

    // Lo cancelaste o rechazaste tú: el error que llegue después no se avisa.
    property bool _quiet: false

    // ── textos ────────────────────────────────────────────────────

    readonly property bool isKeyboard: root.kind === "keyboard"

    readonly property string message: {
        const who = "«" + root.name + "»";
        switch (root.stage) {
        case "starting":
            return "Conectando con " + who + "…";
        case "pin":
        case "passkey":
            return root.isKeyboard
                ? "Escribe este código en " + who + " y presiona Retorno."
                : "Escribe este código en " + who + ".";
        case "confirm":
            return "Confirma que " + who + " muestre este mismo código.";
        case "enter-pin":
            return "Escribe el código de " + who + ". Si no lo sabes, suele ser 0000.";
        case "enter-passkey":
            return "Escribe el número que aparece en " + who + ".";
        case "failed":
            return root.errorText;
        }
        return "";
    }

    // Lo que confunde la primera vez: mientras escribes el código, el teclado
    // todavía no está conectado, así que no aparece nada en la pantalla.
    readonly property string hint: root.isKeyboard && (root.stage === "pin" || root.stage === "passkey")
        ? "No verás lo que escribes: el teclado aún no está conectado."
        : ""

    // ── acciones ──────────────────────────────────────────────────

    function start(address, name, kind): void {
        if (PairingRepository.running)
            return;

        root.address = address;
        root.name = name || address;
        root.kind = kind || "bluetooth";
        root.code = "";
        root.entered = -1;
        root.errorText = "";
        root._quiet = false;

        if (PairingRepository.start(address))
            root.stage = "starting";
    }

    function retry(): void {
        if (root.stage === "failed")
            root.start(root.address, root.name, root.kind);
    }

    function cancel(): void {
        if (!root.busy) {
            root.dismiss();
            return;
        }
        root._quiet = true;
        PairingRepository.cancel();
    }

    function confirm(): void {
        if (root.stage !== "confirm")
            return;
        PairingRepository.accept();
        root.stage = "starting";
    }

    function rejectCode(): void {
        if (root.stage === "confirm") {
            root._quiet = true;
            PairingRepository.reject();
        }
    }

    function submit(text): void {
        const value = String(text || "").trim();

        if (root.stage === "enter-pin" && value.length > 0) {
            PairingRepository.answerPin(value);
            root.stage = "starting";
        } else if (root.stage === "enter-passkey" && /^\d{1,6}$/.test(value)) {
            PairingRepository.answerPasskey(value);
            root.stage = "starting";
        }
    }

    function dismiss(): void {
        if (!root.busy)
            root.stage = "idle";
    }

    // ── lo que dice el agente ─────────────────────────────────────

    function explain(error): string {
        const who = "«" + root.name + "»";
        switch (error) {
        case "org.bluez.Error.AuthenticationFailed":
            return "El código no coincidió. Vuelve a intentarlo: escribe el código completo y luego Retorno.";
        case "org.bluez.Error.AuthenticationRejected":
            return who + " rechazó el emparejamiento.";
        case "org.bluez.Error.AuthenticationCanceled":
            return "Se canceló el emparejamiento.";
        case "org.bluez.Error.AuthenticationTimeout":
        case "dotfiles.Error.Timeout":
            return "Pasó demasiado tiempo sin escribir el código.";
        case "org.bluez.Error.ConnectionAttemptFailed":
        case "org.bluez.Error.Failed":
        case "org.bluez.Error.NotReady":
            return who + " no respondió. Revisa que esté encendido y cerca.";
        case "org.bluez.Error.DoesNotExist":
            return who + " ya no está a la vista. Enciéndelo y vuelve a buscar.";
        case "org.bluez.Error.InProgress":
            return "Ya hay otro emparejamiento en curso.";
        case "dotfiles.Error.NoGObject":
            return "Falta python-gobject para mostrar el código. Corre ./install.sh en tus dotfiles.";
        case "dotfiles.Error.NoBluez":
            return "El servicio de Bluetooth no está corriendo.";
        }
        return "No se pudo emparejar " + who + ".";
    }

    Connections {
        target: PairingRepository

        function onEvent(payload) {
            switch (payload.event) {
            case "pin":
                root.code = String(payload.code);
                root.entered = -1;
                root.stage = "pin";
                break;
            case "passkey":
                root.code = String(payload.code);
                root.entered = payload.entered | 0;
                root.stage = "passkey";
                break;
            case "confirm":
                root.code = String(payload.code);
                root.entered = -1;
                root.stage = "confirm";
                break;
            case "enter-pin":
            case "enter-passkey":
                root.code = "";
                root.stage = payload.event;
                break;
            case "paired":
                // Listo: se cierra ya. El agente termina de conectarlo solo.
                root.stage = "idle";
                break;
            case "failed":
                if (root._quiet) {
                    root.stage = "idle";
                } else {
                    root.errorText = root.explain(payload.error);
                    root.stage = "failed";
                }
                break;
            }
        }

        function onEnded(address, exitCode) {
            // Terminó sin avisar por qué (lo mataron, o no había python3).
            if (root.busy && exitCode !== 0) {
                if (root._quiet) {
                    root.stage = "idle";
                    return;
                }
                root.errorText = exitCode === 127
                    ? "No se pudo arrancar el agente de emparejamiento (falta python3)."
                    : root.explain("");
                root.stage = "failed";
            }
        }
    }

    Connections {
        target: SettingsControl

        function onShownChanged() {
            if (SettingsControl.shown)
                return;
            if (root.busy)
                root.cancel();
            else
                root.dismiss();
        }
    }
}
