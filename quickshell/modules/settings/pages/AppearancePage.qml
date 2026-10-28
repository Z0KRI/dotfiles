// Ajustes › Apariencia: modo, color de acento y Liquid Glass.
//
// La vista previa del vidrio usa tu BarGroup de verdad, no un dibujo: mueves
// el deslizador y ves la barra tal como va a quedar, porque es la misma
// pieza leyendo los mismos colores del tema.

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

    SettingsGroup {
        header: "Liquid Glass"
        footer: "Cambia qué tan transparente es el vidrio de la barra, el Centro de "
                + "control, los menús, Spotlight y esta barra lateral. En medio queda como siempre."

        // Vista previa: un "fondo de pantalla" y tu barra encima.
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

                BarGroup {
                    anchors.centerIn: parent

                    BarItem {
                        interactive: false

                        Icon {
                            icon: Theme.systemIcons.arch.icon
                            ink: Theme.systemIcons.arch.ink
                            color: Theme.glass.content
                            font.family: Theme.systemIcons.arch.family
                        }
                    }

                    BarItem {
                        interactive: false

                        Label {
                            text: "Ajustes"
                            color: Theme.glass.content
                            font.weight: Font.ExtraBold
                        }
                    }

                    BarItem {
                        interactive: false

                        Icon {
                            icon: Theme.systemIcons.controlCenter
                            size: 14
                            color: Theme.glass.content
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
