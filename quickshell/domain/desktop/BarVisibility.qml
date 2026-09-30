pragma Singleton

import Quickshell
import qs.data.hyprland

Singleton {
    id: root

    readonly property int pinnedWorkspace: 1

    function isPinned(screen) {
        return HyprlandRepository.activeWorkspaceId(screen) === root.pinnedWorkspace;
    }

    function isFullscreen(screen) {
        return HyprlandRepository.hasFullscreen(screen);
    }

    // It hides automatically only in full-screen mode, and never in the fixed workspace.
    function autoHide(screen) {
        return root.isFullscreen(screen) && !root.isPinned(screen);
    }

    // In full-screen mode, there's nothing to click.
    function reserveSpace(screen) {
        return !root.isFullscreen(screen);
    }

    // To view an app in full-screen mode, you need to switch to a higher layer.
    function aboveFullscreen(screen) {
        return root.isFullscreen(screen);
    }

    // When it's hidden on its own, it appears as a solid bar
    function solid(screen) {
        return root.autoHide(screen);
    }
}