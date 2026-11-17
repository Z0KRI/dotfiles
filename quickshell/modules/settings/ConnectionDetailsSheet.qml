pragma ComponentBehavior: Bound

// (Bound: los delegados de los Repeater pueden leer los id de afuera,
// como `root`, y qmllint lo sabe. A cambio, lo de cada delegado se pide
// con su id: `fila.modelData`, no `modelData` a secas desde un hijo.)

// La hoja de "Detalles…" de una conexión, igual que la de macOS: a la
// izquierda la conexión y sus apartados (TCP/IP, DNS, WINS, 802.1X, Proxies,
// Hardware); a la derecha lo del apartado elegido; abajo Cancelar y Aceptar
// (y, en Wi-Fi, "Olvidar esta red…").
//
// Sirve para Wi-Fi y para Ethernet. Lo que cambia entre las dos son dos
// propiedades:
//   - `control`: el caso de uso que la alimenta (WifiControl o
//     EthernetControl). Los dos ofrecen lo mismo con los mismos nombres:
//     details, editableKeys, detailsError, saveDetails(), closeDetails() y
//     renewLease(). A eso se le llama tener la misma INTERFAZ, y es lo que
//     deja que una sola hoja atienda a los dos.
//   - `kind`: "wifi" o "wired", para el ícono y el primer apartado, que es
//     lo único distinto a la vista.
//
// Patrón BORRADOR: nada de lo que tocas cambia la red todavía. Al abrir se
// copian los valores reales a `draft`; cada control cambia el borrador con
// set(), y solo Aceptar se lo entrega al dominio, que lo revisa y manda a
// NetworkManager lo que de verdad cambió. Cancelar es simplemente cerrar: el
// borrador se tira. Por eso puedes pasear por los apartados sin miedo.
//
// `info` es lo que solo se lee (la IP de ahora, la MAC...) y se sigue
// actualizando con la hoja abierta; el borrador no, para no pisarte.

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.network

Sheet {
    id: root

    // WifiControl o EthernetControl (ver arriba).
    required property var control
    property string kind: "wifi"
    readonly property bool wired: root.kind === "wired"

    shown: root.control.details !== null
    cardWidth: 700
    padding: 0
    cardColor: Theme.window.background

    // El apartado a la vista: "network", "tcpip", "dns", "wins", "8021x",
    // "proxies" o "hardware".
    property string tab: "network"

    readonly property var tabs: [
        { id: "tcpip", title: "TCP/IP" },
        { id: "dns", title: "DNS" },
        { id: "wins", title: "WINS" },
        { id: "8021x", title: "802.1X" },
        { id: "proxies", title: "Proxies" },
        { id: "hardware", title: "Hardware" }
    ]

    // Lo último que se enseñó: mientras la hoja se desvanece, `details` ya es
    // null y los textos no deben quedarse en blanco.
    property var info: ({
        name: "", connected: false, state: "", status: "", level: "none", security: "", enterprise: false,
        saved: false, loaded: false, address: "",
        ipv6Addresses: [], ipv6Router: "", liveDns: [], hostname: "", workgroup: "", winsServer: "", eap: "", identity: "", liveMtu: 0
    })

    readonly property var blank: ({
        autoJoin: true, privateAddress: "off", lowData: false, limitTracking: false,
        ipv4Method: "auto", ipv4Address: "", ipv4Mask: "", ipv4Router: "", dhcpClientId: "",
        ipv6Method: "auto",
        dnsServers: [], searchDomains: [],
        proxyDiscovery: false, proxyPac: false, pacUrl: "",
        mtuAuto: true, mtu: 1500
    })

    property var draft: root.blank

    // Sin perfil guardado (o mientras llegan sus ajustes) no hay qué editar.
    readonly property bool editable: root.info.saved && root.info.loaded
    readonly property bool manualIp: root.draft.ipv4Method === "manual"

    // El apartado que tiene algo mal escrito lleva un aviso en la barra
    // lateral, como en macOS, sin esperar a que des Aceptar.
    readonly property var warnings: ({
        tcpip: root.editable && ConnectionSettings.tcpipProblem(root.draft) !== ""
    })

    // El punto de estado: verde conectada, ámbar entrando, rojo sin cable,
    // gris inactiva.
    readonly property color statusColor: root.info.connected ? Theme.colors.success
        : (root.info.state === "connecting" ? Theme.colors.warning
        : (root.info.state === "unavailable" ? Theme.window.destructive : Theme.window.textMuted))

    readonly property var addressModes: [
        { value: "off", label: "Desactivada" },
        { value: "fixed", label: "Fija" },
        { value: "rotating", label: "Rotativa" }
    ]

    readonly property var ipv4Modes: [
        { value: "auto", label: "Usando DHCP" },
        { value: "manual", label: "Manualmente" },
        { value: "disabled", label: "Desactivado" }
    ]

    readonly property var ipv6Modes: [
        { value: "auto", label: "Automáticamente" },
        { value: "link-local", label: "Solo enlace local" },
        { value: "disabled", label: "Desactivado" }
    ]

    readonly property var mtuModes: [
        { value: true, label: "Automáticamente" },
        { value: false, label: "Manualmente" }
    ]

    // Cambia una cosa del borrador. Se crea un objeto nuevo a propósito: QML
    // solo se entera de que `draft` cambió si se le asigna otro objeto.
    function set(key: string, value: var): void {
        const next = Object.assign({}, root.draft);
        next[key] = value;
        root.draft = next;
    }

    function load(): void {
        const details = root.control.details;
        // Sobre los valores de relleno: en Ethernet no vienen los que son
        // solo de Wi-Fi (autoJoin...), y sus controles no deben quedarse
        // sin valor aunque no se vean.
        const next = Object.assign({}, root.blank);
        for (const key of root.control.editableKeys)
            next[key] = details[key];

        root.info = details;
        root.draft = next;
    }

    function accept(): void {
        root.control.saveDetails(root.draft);
    }

    onShownChanged: {
        if (root.shown) {
            root.tab = "network";
            root.load();
        }
    }

    Connections {
        target: root.control

        function onDetailsChanged() {
            const details = root.control.details;
            if (!details)
                return;

            // Cuando por fin llegan los ajustes del perfil, el borrador se
            // vuelve a copiar (antes solo tenía valores de relleno).
            const arrived = !(root.info.saved && root.info.loaded) && details.saved && details.loaded;
            root.info = details;
            if (arrived)
                root.load();
        }
    }

    Component.onDestruction: root.control.closeDetails()

    onReturnPressed: root.accept()
    onEscapePressed: root.control.closeDetails()

    // Un apartado de la barra lateral.
    component TabItem: Rectangle {
        id: item

        property string title: ""
        property bool current: false
        property bool warning: false

        signal picked()

        width: parent.width
        height: 28
        radius: 7
        color: item.current ? Theme.colors.accent : (itemHover.hovered ? Theme.window.hover : "transparent")

        Label {
            id: itemTitle

            x: 10
            anchors.verticalCenter: parent.verticalCenter
            text: item.title
            color: item.current ? "white" : Theme.window.text
            font.pixelSize: Theme.window.fontBody
        }

        Icon {
            visible: item.warning
            anchors.left: itemTitle.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            icon: Theme.systemIcons.warning
            size: 14
            color: item.current ? "white" : Theme.colors.warning
        }

        HoverHandler {
            id: itemHover
        }

        TapHandler {
            onTapped: item.picked()
        }
    }

    Item {
        width: parent.width
        height: 480

        // ── Barra lateral ────────────────────────────────────
        Rectangle {
            id: sidebar

            width: 200
            height: parent.height
            color: Theme.window.control

            Column {
                x: 10
                y: 10
                width: parent.width - 20
                spacing: 2

                // La red: el primer apartado, con su estado.
                Rectangle {
                    id: networkItem

                    readonly property bool current: root.tab === "network"

                    width: parent.width
                    height: 44
                    radius: 8
                    color: networkItem.current ? Theme.colors.accent
                                               : (networkHover.hovered ? Theme.window.hover : "transparent")

                    SymbolTile {
                        id: tile

                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        size: 28
                        icon: root.wired ? Theme.systemIcons.ethernet
                                         : (Theme.systemIcons.wifi[root.info.level] ?? Theme.systemIcons.wifi.high)
                        tint: root.wired ? "#8e8e93" : "#0a84ff"
                    }

                    Column {
                        anchors.left: tile.right
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        Label {
                            width: parent.width
                            text: root.info.name
                            color: networkItem.current ? "white" : Theme.window.text
                            font.pixelSize: Theme.window.fontBody
                            font.weight: Font.DemiBold
                        }

                        Row {
                            spacing: 5

                            Rectangle {
                                visible: root.wired || root.info.connected
                                anchors.verticalCenter: parent.verticalCenter
                                width: 7
                                height: 7
                                radius: 3.5
                                color: root.statusColor
                            }

                            Label {
                                text: root.wired || root.info.connected ? root.info.status : "No conectada"
                                color: networkItem.current ? Qt.rgba(1, 1, 1, 0.85) : Theme.window.textMuted
                                font.pixelSize: Theme.window.fontCaption
                            }
                        }
                    }

                    HoverHandler {
                        id: networkHover
                    }

                    TapHandler {
                        onTapped: root.tab = "network"
                    }
                }

                Item {
                    width: 1
                    height: 4
                }

                Repeater {
                    model: root.tabs

                    TabItem {
                        id: entry

                        required property var modelData

                        title: entry.modelData.title
                        current: root.tab === entry.modelData.id
                        warning: root.warnings[entry.modelData.id] ?? false
                        onPicked: root.tab = entry.modelData.id
                    }
                }
            }
        }

        Rectangle {
            x: sidebar.width
            width: 1
            height: parent.height
            color: Theme.window.separator
        }

        // ── El apartado elegido ──────────────────────────────
        Flickable {
            id: flick

            anchors.left: sidebar.right
            anchors.leftMargin: 1
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: bar.top
            contentWidth: width
            contentHeight: pane.implicitHeight + 32
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            // Al cambiar de apartado se empieza desde arriba.
            Connections {
                target: root

                function onTabChanged() {
                    flick.contentY = 0;
                }
            }

            Column {
                id: pane

                x: 16
                y: 16
                width: flick.width - 32
                spacing: 14

                // Red que no está guardada: se puede ver, no ajustar.
                Label {
                    visible: !root.info.saved
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: root.wired
                        ? "Este servicio no tiene un perfil guardado. Actívalo una vez y podrás cambiar sus ajustes."
                        : "Esta red no está guardada en este equipo. Conéctate una vez y podrás cambiar sus ajustes."
                    color: Theme.window.textMuted
                    font.pixelSize: Theme.window.fontCaption + 1
                }

                // ── El servicio de cable ─────────────────────
                Column {
                    visible: root.tab === "network" && root.wired
                    width: parent.width
                    spacing: 14
                    enabled: root.editable

                    SettingsGroup {
                        SettingsRow {
                            title: "Nombre"
                            value: root.info.name
                        }
                    }

                    SettingsGroup {
                        ToggleRow {
                            title: "Limitar el rastreo de dirección IP"
                            subtitle: "Usa direcciones IPv6 temporales, que cambian cada cierto tiempo, "
                                      + "para que los sitios no te sigan por tu dirección."
                            checked: root.draft.limitTracking
                            onToggled: root.set("limitTracking", !root.draft.limitTracking)
                        }
                    }
                }

                // ── La red Wi-Fi ─────────────────────────────
                Column {
                    visible: root.tab === "network" && !root.wired
                    width: parent.width
                    spacing: 14
                    enabled: root.editable

                    SettingsGroup {
                        ToggleRow {
                            title: "Conectarse automáticamente a esta red"
                            checked: root.draft.autoJoin
                            onToggled: root.set("autoJoin", !root.draft.autoJoin)
                        }
                    }

                    SettingsGroup {
                        SettingsRow {
                            title: "Dirección Wi-Fi privada"
                            subtitle: "Una dirección privada reduce el rastreo de tu equipo por parte de "
                                      + "los operadores de redes Wi-Fi. La fija deja que esta red te "
                                      + "reconozca y reduce el rastreo entre redes; la rotativa cambia "
                                      + "en cada conexión."

                            PopupButton {
                                options: root.addressModes
                                current: root.draft.privateAddress
                                onSelected: value => root.set("privateAddress", value)
                            }
                        }

                        SettingsRow {
                            title: "Dirección Wi-Fi"
                            value: root.info.address !== "" ? root.info.address : "—"
                        }
                    }

                    SettingsGroup {
                        ToggleRow {
                            title: "Modo de datos reducidos"
                            subtitle: "Ayuda a reducir el uso de datos de tu equipo en las redes Wi-Fi "
                                      + "que elijas: las apps que lo respetan evitan descargas grandes."
                            checked: root.draft.lowData
                            onToggled: root.set("lowData", !root.draft.lowData)
                        }

                        ToggleRow {
                            title: "Limitar el rastreo de dirección IP"
                            subtitle: "Usa direcciones IPv6 temporales, que cambian cada cierto tiempo, "
                                      + "para que los sitios no te sigan por tu dirección."
                            checked: root.draft.limitTracking
                            onToggled: root.set("limitTracking", !root.draft.limitTracking)
                        }
                    }
                }

                // ── TCP/IP ───────────────────────────────────
                Column {
                    visible: root.tab === "tcpip"
                    width: parent.width
                    spacing: 14
                    enabled: root.editable

                    SettingsGroup {
                        SettingsRow {
                            title: "Configurar IPv4"

                            PopupButton {
                                options: root.ipv4Modes
                                current: root.draft.ipv4Method
                                onSelected: value => root.set("ipv4Method", value)
                            }
                        }

                        FieldRow {
                            visible: root.draft.ipv4Method !== "disabled"
                            title: "Dirección IP"
                            text: root.draft.ipv4Address
                            placeholder: "192.168.1.10"
                            editable: root.manualIp
                            onEdited: text => root.set("ipv4Address", text)
                        }

                        FieldRow {
                            visible: root.draft.ipv4Method !== "disabled"
                            title: "Máscara de subred"
                            text: root.draft.ipv4Mask
                            placeholder: "255.255.255.0"
                            editable: root.manualIp
                            onEdited: text => root.set("ipv4Mask", text)
                        }

                        FieldRow {
                            visible: root.draft.ipv4Method !== "disabled"
                            title: "Router"
                            text: root.draft.ipv4Router
                            placeholder: "192.168.1.1"
                            editable: root.manualIp
                            onEdited: text => root.set("ipv4Router", text)
                        }
                    }

                    SettingsGroup {
                        visible: root.draft.ipv4Method === "auto"

                        // Renovar = volver a levantar la conexión: se corta
                        // un momento y el router reparte la dirección otra vez.
                        SettingsRow {
                            title: "Concesión DHCP"

                            PushButton {
                                enabled: root.info.connected
                                text: "Renovar concesión DHCP"
                                onClicked: root.control.renewLease()
                            }
                        }

                        FieldRow {
                            title: "ID de cliente DHCP (si se requiere)"
                            text: root.draft.dhcpClientId
                            placeholder: "ID de cliente DHCP"
                            onEdited: text => root.set("dhcpClientId", text)
                        }
                    }

                    SettingsGroup {
                        SettingsRow {
                            title: "Configurar IPv6"

                            PopupButton {
                                options: root.ipv6Modes
                                current: root.draft.ipv6Method
                                onSelected: value => root.set("ipv6Method", value)
                            }
                        }

                        // Vacío se ve el nombre del campo en gris, como en macOS.
                        SettingsRow {
                            visible: root.draft.ipv6Method !== "disabled"
                            title: "Router"
                            value: root.info.ipv6Router !== "" ? root.info.ipv6Router : "Router"
                            opacity: root.info.ipv6Router !== "" ? 1 : 0.55
                        }

                        Repeater {
                            model: root.info.ipv6Addresses

                            SettingsRow {
                                id: address6

                                required property var modelData

                                title: "Dirección IPv6"
                                value: address6.modelData
                            }
                        }
                    }
                }

                // ── DNS ──────────────────────────────────────
                Column {
                    visible: root.tab === "dns"
                    width: parent.width
                    spacing: 14
                    enabled: root.editable

                    EditableList {
                        header: "Servidores DNS"
                        values: root.draft.dnsServers
                        fallback: root.info.liveDns
                        placeholder: "1.1.1.1"
                        onEdited: values => root.set("dnsServers", values)
                    }

                    Label {
                        width: parent.width
                        leftPadding: 4
                        wrapMode: Text.WordWrap
                        text: root.draft.dnsServers.length === 0
                            ? "En gris, los que dio el router. Agrega uno con + para usar los tuyos."
                            : "Se usan solo estos; los del router se ignoran."
                        color: Theme.window.textMuted
                        font.pixelSize: Theme.window.fontCaption
                    }

                    EditableList {
                        header: "Dominios de búsqueda"
                        values: root.draft.searchDomains
                        placeholder: "ejemplo.local"
                        onEdited: values => root.set("searchDomains", values)
                    }
                }

                // ── WINS ─────────────────────────────────────
                Column {
                    visible: root.tab === "wins"
                    width: parent.width
                    spacing: 14

                    SettingsGroup {
                        footer: "En Linux, WINS no es parte de la conexión: el nombre NetBIOS, el grupo "
                                + "de trabajo y los servidores WINS son de Samba y se ponen en "
                                + "/etc/samba/smb.conf, para todas las redes a la vez."

                        SettingsRow {
                            title: "Nombre NetBIOS"
                            value: root.info.hostname !== "" ? root.info.hostname.toUpperCase().slice(0, 15) : "—"
                        }

                        SettingsRow {
                            title: "Grupo de trabajo"
                            value: root.info.workgroup || "—"
                        }

                        SettingsRow {
                            title: "Servidores WINS"
                            value: root.info.winsServer || "—"
                        }
                    }
                }

                // ── 802.1X ───────────────────────────────────
                Column {
                    visible: root.tab === "8021x"
                    width: parent.width
                    spacing: 14

                    SettingsGroup {
                        footer: root.info.enterprise || root.info.eap !== ""
                            ? "Los perfiles 802.1X (usuario, certificados) se editan con nm-connection-editor o nmtui."
                            : (root.wired
                                ? "Esta conexión no usa 802.1X: basta con enchufar el cable."
                                : "Esta red no usa 802.1X: entra con contraseña"
                                  + (root.info.security === "Ninguna" ? " o sin ella" : "") + ", sin usuario ni certificado.")

                        SettingsRow {
                            title: "Seguridad"
                            value: root.info.security
                        }

                        SettingsRow {
                            title: "Autenticación"
                            value: root.info.eap !== "" ? root.info.eap.toUpperCase() : "Ninguna"
                        }

                        SettingsRow {
                            visible: root.info.identity !== ""
                            title: "Identidad"
                            value: root.info.identity
                        }
                    }
                }

                // ── Proxies ──────────────────────────────────
                Column {
                    visible: root.tab === "proxies"
                    width: parent.width
                    spacing: 14
                    enabled: root.editable

                    // NetworkManager tiene un solo modo automático: sin URL
                    // lo descubre (WPAD) y con URL usa ese archivo. Por eso
                    // encender uno apaga el otro.
                    SettingsGroup {
                        ToggleRow {
                            title: "Detección automática de proxy"
                            checked: root.draft.proxyDiscovery
                            onToggled: {
                                const on = !root.draft.proxyDiscovery;
                                root.set("proxyDiscovery", on);
                                if (on)
                                    root.set("proxyPac", false);
                            }
                        }
                    }

                    SettingsGroup {
                        footer: "Los proxies fijos (web, web seguro, SOCKS) en Linux no van por red: "
                                + "se ponen en cada app o con las variables http_proxy y https_proxy."

                        ToggleRow {
                            title: "Configuración automática de proxy"
                            checked: root.draft.proxyPac
                            onToggled: {
                                const on = !root.draft.proxyPac;
                                root.set("proxyPac", on);
                                if (on)
                                    root.set("proxyDiscovery", false);
                            }
                        }

                        FieldRow {
                            visible: root.draft.proxyPac
                            title: "URL"
                            text: root.draft.pacUrl
                            placeholder: "http://ejemplo.com/proxy.pac"
                            fieldWidth: 280
                            onEdited: text => root.set("pacUrl", text)
                        }
                    }
                }

                // ── Hardware ─────────────────────────────────
                Column {
                    visible: root.tab === "hardware"
                    width: parent.width
                    spacing: 14
                    enabled: root.editable

                    SettingsGroup {
                        SettingsRow {
                            title: "Dirección MAC"
                            value: root.info.address !== "" ? root.info.address : "—"
                        }

                        SettingsRow {
                            title: "Configurar"

                            PopupButton {
                                options: root.mtuModes
                                current: root.draft.mtuAuto
                                onSelected: value => root.set("mtuAuto", value)
                            }
                        }

                        SettingsRow {
                            visible: root.draft.mtuAuto
                            title: "MTU"
                            value: "Estándar (" + (root.info.liveMtu || 1500) + ")"
                        }

                        FieldRow {
                            visible: !root.draft.mtuAuto
                            title: "MTU"
                            text: String(root.draft.mtu)
                            placeholder: "1500"
                            fieldWidth: 90
                            onEdited: text => root.set("mtu", text)
                        }
                    }
                }
            }
        }

        // ── Abajo: olvidar, cancelar y aceptar ───────────────
        Item {
            id: bar

            anchors.left: flick.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: buttons.height + 28 + (problem.visible ? problem.implicitHeight + 8 : 0)

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.window.separator
            }

            Label {
                id: problem

                visible: root.control.detailsError !== ""
                x: 16
                y: 10
                width: parent.width - 32
                wrapMode: Text.WordWrap
                text: root.control.detailsError
                color: Theme.window.destructive
                font.pixelSize: Theme.window.fontCaption + 1
            }

            PushButton {
                visible: root.info.saved && !root.wired
                x: 16
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14
                text: "Olvidar esta red…"
                onClicked: root.control.askForget(root.info.name)
            }

            Row {
                id: buttons

                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14
                spacing: 10

                PushButton {
                    width: 84
                    text: "Cancelar"
                    onClicked: root.control.closeDetails()
                }

                PushButton {
                    width: 84
                    primary: true
                    text: "Aceptar"
                    onClicked: root.accept()
                }
            }
        }
    }
}
