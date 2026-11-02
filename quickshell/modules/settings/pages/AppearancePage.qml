// Ajustes › Apariencia: modo, color de acento, fondo de pantalla y Liquid Glass.
//
// La vista previa del vidrio es una barra lateral de Ajustes en miniatura,
// con el mismo color del tema (Theme.window.sidebar): mueves el deslizador y
// la ves cambiar. Es lo único que sigue siendo vidrio; el marco y todo lo que
// sale de él es negro, como la isla.

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.desktop

SettingsPage {
    id: root

    readonly property var accentNames: ({
        blue: "Azul", purple: "Morado", pink: "Rosa", red: "Rojo",
        orange: "Naranja", yellow: "Amarillo", green: "Verde", graphite: "Grafito"
    })

    SettingsGroup {
        footer: Appearance.mode === "auto"
            ? "Automático cambia a oscuro de 7 p.m. a 7 a.m."
            : ""

        SettingsRow {
            title: "Apariencia"
            implicitHeight: 96

            Row {
                spacing: 6

                AppearanceOption {
                    look: "light"
                    text: "Claro"
                    selected: Appearance.mode === "light"
                    onActivated: Appearance.setMode("light")
                }

                AppearanceOption {
                    look: "dark"
                    text: "Oscuro"
                    selected: Appearance.mode === "dark"
                    onActivated: Appearance.setMode("dark")
                }

                AppearanceOption {
                    look: "auto"
                    text: "Automático"
                    selected: Appearance.mode === "auto"
                    onActivated: Appearance.setMode("auto")
                }
            }
        }

        SettingsRow {
            title: "Color de acento"
            subtitle: root.accentNames[Appearance.accent] ?? ""

            Row {
                spacing: 4

                Repeater {
                    model: Appearance.accentIds

                    ColorSwatch {
                        required property string modelData

                        tint: Theme.isDark
                            ? Theme.accents[modelData].dark
                            : Theme.accents[modelData].light
                        selected: Appearance.accent === modelData
                        onActivated: Appearance.setAccent(modelData)
                    }
                }
            }
        }
    }

    // El fondo: cuál está puesto y el botón al selector (el cajón de tarjetas
    // que sale del borde de abajo). Los fondos no se agregan aquí: son las
    // imágenes de la carpeta.
    SettingsGroup {
        header: "Fondo de pantalla"
        footer: "Se leen solos de " + Wallpapers.folder + ": lo que pongas o quites ahí "
                + "aparece o desaparece del selector, sin reiniciar nada."

        SettingsRow {
            glyph: Theme.systemIcons.launcher.image
            title: Wallpapers.current ? Wallpapers.current.name : "Ninguno"
            subtitle: Wallpapers.empty
                ? "La carpeta está vacía: se ve el fondo de Hyprland."
                : Wallpapers.list.length + (Wallpapers.list.length === 1 ? " fondo" : " fondos")

            Row {
                spacing: 6

                PushButton {
                    text: "Abrir la carpeta"
                    onClicked: Wallpapers.openFolder()
                }

                PushButton {
                    primary: true
                    enabled: !Wallpapers.empty
                    text: "Elegir…"
                    onClicked: Wallpapers.open()
                }
            }
        }
    }

    SettingsGroup {
        header: "Liquid Glass"
        footer: "Cambia qué tan transparente es esta barra lateral. En medio queda como "
                + "siempre. El marco de la pantalla y lo que sale de él (los menús, el Centro "
                + "de control, las notificaciones, Spotlight y el portapapeles) es negro, como la isla."

        // Vista previa: un "fondo de pantalla" y una barra lateral encima.
        Item {
            width: parent.width
            height: 92

            Rectangle {
                anchors.fill: parent
                anchors.margins: 12
                radius: 9

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#ff7a59" }
                    GradientStop { position: 0.45; color: "#c74fd8" }
                    GradientStop { position: 1.0; color: "#3a7bfd" }
                }

                // Unos círculos para que se note la transparencia.
                Rectangle {
                    x: parent.width * 0.18
                    y: -10
                    width: 70
                    height: 70
                    radius: 35
                    color: Qt.rgba(1, 1, 1, 0.35)
                }

                Rectangle {
                    x: parent.width * 0.62
                    y: 30
                    width: 54
                    height: 54
                    radius: 27
                    color: Qt.rgba(0, 0, 0, 0.25)
                }

                // Una barra lateral de Ajustes en miniatura, con su color.
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 170
                    radius: 9
                    color: Theme.window.sidebar

                    Column {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Repeater {
                            model: [
                                { glyph: Theme.systemIcons.settings, text: "Apariencia" },
                                { glyph: Theme.systemIcons.bell, text: "Notificaciones" }
                            ]

                            Row {
                                id: sample

                                required property var modelData

                                spacing: 8

                                Icon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    icon: sample.modelData.glyph
                                    size: 13
                                    color: Theme.window.text
                                }

                                Label {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: sample.modelData.text
                                    color: Theme.window.text
                                    font.pixelSize: Theme.window.fontBody
                                }
                            }
                        }
                    }
                }
            }
        }

        SettingsRow {
            title: "Vidrio"

            KnobSlider {
                implicitWidth: 300
                value: Appearance.glass
                ticks: 5
                minLabel: "Transparente"
                maxLabel: "Tintado"
                onMoved: value => Appearance.setGlass(value)
            }
        }
    }
}
