import QtQuick
import qs.core.theme

Text {
    id: root

    property string icon: ""
    property int size: 32

    text: root.icon
    color: Theme.colors.baseContent
    
    font.family: Theme.font.icon
    font.pixelSize: root.size

    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}