import QtQuick
import qs.core.theme
import qs.core.components.molecules

import QtQuick
import qs.core.theme
import qs.core.components.molecules

ListView {
    id: root

    signal activated(var entry)

    clip: true
    spacing: Theme.spacing.xs
    currentIndex: 0
    highlightMoveDuration: 90
    keyNavigationEnabled: false

    function move(delta: int): void {
        if (count === 0) return;
        currentIndex = (currentIndex + delta + count) % count;
        positionViewAtIndex(currentIndex, ListView.Contain);
    }

    function activateCurrent(): void {
        if (count === 0) return;
        root.activated(model[currentIndex]);
    }

    delegate: ResultRow {
        required property var modelData
        required property int index

        width: ListView.view.width
        entry: modelData
        selected: ListView.isCurrentItem

        onHovered: root.currentIndex = index
        onActivated: root.activated(modelData)
    }
}
