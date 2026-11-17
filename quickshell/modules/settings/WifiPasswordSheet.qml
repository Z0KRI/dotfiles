// La hoja que pide la contraseña de una red Wi-Fi, como la de macOS: el
// campo, "Mostrar contraseña" y Cancelar / Conectar. Si la contraseña está
// mal, se queda abierta y dice por qué.
//
// Qué red la pide, cuántos caracteres hacen falta y los mensajes de error
// viven en domain/network/WifiControl; aquí solo se acomodan.

import QtQuick
import QtQuick.Layouts
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.network

Sheet {
    id: root

    shown: WifiControl.asking !== null
    cardWidth: 400

    // Se guarda lo último que se pidió: mientras la hoja se desvanece ya no
    // hay red (asking es null) y los textos no deben quedarse en blanco.
    property var asked: ({ name: "", security: "", enterprise: false, minimumLength: 8 })

    readonly property bool ready: !root.asked.enterprise
                                  && !WifiControl.joining
                                  && field.text.length >= root.asked.minimumLength

    function open(): void {
        root.asked = WifiControl.asking;
        field.text = "";
        reveal.checked = false;
        if (!root.asked.enterprise)
            field.forceActiveFocus();
    }

    onShownChanged: {
        if (root.shown)
            root.open();
    }

    // Si la ventana nace con la hoja ya pedida (venías del Centro de
    // control), `shown` no "cambia": hay que abrirla a mano.
    Component.onCompleted: {
        if (root.shown)
            root.open();
    }

    // Mientras se intenta entrar el campo se apaga, y un campo apagado suelta
    // el foco. Si el intento falla, se le devuelve con todo seleccionado:
    // escribir encima borra la contraseña mala.
    Connections {
        target: WifiControl

        function onJoiningChanged() {
            if (!WifiControl.joining && root.shown) {
                field.forceActiveFocus();
                field.selectAll();
            }
        }
    }

    // Cerrar Ajustes a media pregunta = cancelar.
    Component.onDestruction: WifiControl.cancelPassword()

    onReturnPressed: WifiControl.submitPassword(field.text)
    onEscapePressed: WifiControl.cancelPassword()

    Row {
        width: parent.width
        spacing: 12

        SymbolTile {
            id: tile

            size: 36
            icon: Theme.systemIcons.wifi.high
            tint: "#0a84ff"
        }

        Column {
            width: parent.width - tile.width - parent.spacing
            spacing: 3

            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "La red Wi-Fi «" + root.asked.name + "» requiere una contraseña"
                      + (root.asked.security !== "" ? " " + root.asked.security : "") + "."
                color: Theme.window.text
                font.pixelSize: Theme.window.fontBody
                font.weight: Font.DemiBold
            }

            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Se guarda en NetworkManager: la próxima vez se conecta sola."
                color: Theme.window.textMuted
                font.pixelSize: Theme.window.fontCaption
            }
        }
    }

    SettingsGroup {
        visible: !root.asked.enterprise

        SettingsRow {
            title: "Contraseña"

            TextField {
                id: field

                // Va dentro del RowLayout de la fila: el tamaño se pide así.
                Layout.preferredWidth: 210
                Layout.preferredHeight: 24

                enabled: !WifiControl.joining
                placeholder: "Obligatoria"
                color: Theme.window.text
                font.pixelSize: Theme.window.fontBody
                horizontalAlignment: TextInput.AlignRight
                echoMode: reveal.checked ? TextInput.Normal : TextInput.Password
                maximumLength: 63
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhSensitiveData

                onAccepted: WifiControl.submitPassword(field.text)
                Keys.onEscapePressed: WifiControl.cancelPassword()
            }
        }

        ToggleRow {
            id: reveal

            title: "Mostrar contraseña"
            onToggled: reveal.checked = !reveal.checked
        }
    }

    Label {
        visible: WifiControl.joinError !== ""
        width: parent.width
        wrapMode: Text.WordWrap
        text: WifiControl.joinError
        color: Theme.window.destructive
        font.pixelSize: Theme.window.fontCaption + 1
    }

    Item {
        width: 1
        height: 2
    }

    Row {
        anchors.right: parent.right
        spacing: 10

        PushButton {
            width: 96
            text: root.asked.enterprise ? "Cerrar" : "Cancelar"
            onClicked: WifiControl.cancelPassword()
        }

        PushButton {
            visible: !root.asked.enterprise
            width: 110
            primary: true
            enabled: root.ready
            text: WifiControl.joining ? "Conectando…" : "Conectar"
            onClicked: WifiControl.submitPassword(field.text)
        }
    }
}
