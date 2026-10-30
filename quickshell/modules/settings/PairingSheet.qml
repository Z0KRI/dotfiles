// La hoja de emparejamiento de Bluetooth, encima de toda la ventana de
// Ajustes mientras dura, como el diálogo de macOS. Según lo que pida el
// aparato enseña:
//
//   - el código para escribir en el teclado (con cada dígito marcado al
//     teclearlo, si el teclado lo informa);
//   - el número a comparar con el de la otra pantalla (teléfonos);
//   - un campo para que escribas tú el PIN del aparato;
//   - por qué falló, con "Reintentar".
//
// Las reglas y los textos viven en domain/bluetooth/BluetoothPairing; aquí
// solo se acomodan.

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.bluetooth

Sheet {
    id: root

    shown: BluetoothPairing.shown
    cardWidth: 380

    readonly property string stage: BluetoothPairing.stage
    readonly property bool failed: root.stage === "failed"
    readonly property bool showsCode: ["pin", "passkey", "confirm"].indexOf(root.stage) >= 0
    readonly property bool asksInput: root.stage === "enter-pin" || root.stage === "enter-passkey"

    onReturnPressed: {
        if (root.stage === "confirm")
            BluetoothPairing.confirm();
        else if (root.failed)
            BluetoothPairing.retry();
    }

    onEscapePressed: BluetoothPairing.cancel()

    // El campo se limpia y toma el foco cada vez que aparece; al irse, el foco
    // vuelve a la hoja para que Escape siga funcionando.
    onAsksInputChanged: {
        if (root.asksInput) {
            field.text = "";
            field.forceActiveFocus();
        } else {
            root.focusSheet();
        }
    }

    SymbolTile {
        anchors.horizontalCenter: parent.horizontalCenter
        size: 44
        icon: root.failed ? Theme.systemIcons.warning
                          : (Theme.systemIcons.device[BluetoothPairing.kind] ?? Theme.systemIcons.device.bluetooth)
        tint: root.failed ? "#ff9f0a" : "#0a84ff"
    }

    Label {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: BluetoothPairing.name
        color: Theme.window.text
        font.pixelSize: Theme.window.fontTitle
        font.weight: Font.Bold
    }

    Label {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: BluetoothPairing.message
        color: Theme.window.textMuted
        font.pixelSize: Theme.window.fontBody - 1
    }

    // Mientras BlueZ no pide nada: el ícono de "buscando" late.
    Icon {
        visible: root.stage === "starting"
        anchors.horizontalCenter: parent.horizontalCenter
        icon: Theme.systemIcons.scanning
        size: 22
        color: Theme.colors.accent

        SequentialAnimation on opacity {
            running: root.shown && root.stage === "starting"
            loops: Animation.Infinite
            NumberAnimation { from: 1; to: 0.3; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.3; to: 1; duration: 700; easing.type: Easing.InOutSine }
        }
    }

    CodeDigits {
        visible: root.showsCode
        anchors.horizontalCenter: parent.horizontalCenter
        code: BluetoothPairing.code
        entered: BluetoothPairing.entered
    }

    Label {
        visible: BluetoothPairing.hint !== ""
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: BluetoothPairing.hint
        color: Theme.window.textMuted
        font.pixelSize: Theme.window.fontCaption
    }

    // El PIN del aparato, cuando es él el que lo sabe.
    Rectangle {
        visible: root.asksInput
        width: parent.width
        height: 32
        radius: 8
        color: Theme.window.control
        border.width: 1
        border.color: field.activeFocus ? Theme.colors.accent : Theme.window.controlBorder

        TextField {
            id: field

            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            placeholder: root.stage === "enter-passkey" ? "Hasta 6 números" : "PIN"
            color: Theme.window.text
            font.pixelSize: Theme.window.fontBody
            horizontalAlignment: TextInput.AlignHCenter
            maximumLength: root.stage === "enter-passkey" ? 6 : 16
            inputMethodHints: root.stage === "enter-passkey" ? Qt.ImhDigitsOnly : Qt.ImhNone
            validator: RegularExpressionValidator {
                regularExpression: root.stage === "enter-passkey" ? /\d{0,6}/ : /.{0,16}/
            }

            onAccepted: BluetoothPairing.submit(field.text)
            Keys.onEscapePressed: BluetoothPairing.cancel()
        }
    }

    Item {
        width: 1
        height: 4
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10

        PushButton {
            width: 140
            text: root.failed ? "Cerrar" : (root.stage === "confirm" ? "Rechazar" : "Cancelar")
            onClicked: {
                if (root.stage === "confirm")
                    BluetoothPairing.rejectCode();
                else
                    BluetoothPairing.cancel();
            }
        }

        PushButton {
            visible: root.failed || root.stage === "confirm" || root.asksInput
            width: 140
            primary: true
            text: root.failed ? "Reintentar" : "Emparejar"
            enabled: !root.asksInput || field.text.length > 0
            onClicked: {
                if (root.failed)
                    BluetoothPairing.retry();
                else if (root.stage === "confirm")
                    BluetoothPairing.confirm();
                else
                    BluetoothPairing.submit(field.text);
            }
        }
    }
}
