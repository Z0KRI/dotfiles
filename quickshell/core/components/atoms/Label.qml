import QtQuick
import qs.core.theme

Text {
    id: root

    // info | success | warning | error
    property string variant: "content"

    readonly property var colorMap: ({
        "error": Theme.colors.error,
        "warning": Theme.colors.warning,
        "success": Theme.colors.success,
        "info": Theme.colors.info
    })

    color: colorMap[variant] || Theme.colors.baseContent
    font.family: Theme.font.ui
    elide: Text.ElideRight
}
