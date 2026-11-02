// CASO DE USO: Mission Control. Sale del borde de abajo con una tarjeta
// vertical por escritorio del monitor enfocado.
// Reglas:
//   - Cada tarjeta lleva sus ventanas y, debajo, el nombre de sus apps unido
//     con « + ». Una app con dos ventanas cuenta una vez (dos Terminal siguen
//     siendo «Terminal»). Sin ventanas: «Sin apps».
//   - Si ningún escritorio está vacío, al final va uno vacío nuevo (el
//     siguiente número libre), para poder irte a un escritorio limpio.
//   - Elegir una tarjeta te lleva a ese escritorio y cierra Mission Control.
//   - Comparte el borde de abajo con Spotlight, el portapapeles y los fondos.
//
// Los nombres de las apps son los mismos de la barra (ActiveWindow.nameOf).
//
// Por IPC (modules/mission): toggle | open | close. F3 en el teclado Apple.

pragma Singleton

import Quickshell
import qs.data.applications
import qs.data.hyprland

Singleton {
    id: root

    readonly property bool shown: BottomEdge.owner === "mission"

    // El monitor donde se abre: el enfocado, el mismo donde el compositor
    // pone la ventana de Mission Control.
    readonly property string monitor: HyprlandRepository.focusedMonitorName

    // [{ id, active, label, windows: [{ appId, name, icon }] }]
    readonly property var desks: {
        const out = HyprlandRepository.workspacesOn(root.monitor).map(workspace => {
            const windows = workspace.toplevels.values.map(toplevel => {
                const appId = HyprlandRepository.appIdOf(toplevel);
                const entry = AppRepository.entryFor(appId);
                return {
                    appId: appId,
                    name: appId !== "" ? ActiveWindow.nameOf(appId) : "Ventana",
                    icon: entry ? String(entry.icon || "") : ""
                };
            });

            const names = windows
                .map(window => window.name)
                .filter((name, index, all) => all.indexOf(name) === index);

            return {
                id: workspace.id,
                active: workspace.active,
                label: names.length > 0 ? names.join(" + ") : "Sin apps",
                windows: windows
            };
        });

        if (!out.some(desk => desk.windows.length === 0)) {
            const taken = HyprlandRepository.workspaceIds;
            let id = out.length > 0 ? out[out.length - 1].id + 1 : 1;
            while (taken.indexOf(id) >= 0)
                id++;
            out.push({ id: id, active: false, label: "Sin apps", windows: [] });
        }

        return out;
    }

    // Dónde empieza la selección al abrir: el escritorio en el que estás.
    readonly property int activeIndex: Math.max(0, root.desks.findIndex(desk => desk.active))

    function go(id): void {
        HyprlandRepository.focusWorkspace(id);
        root.close();
    }

    function open(): void {
        BottomEdge.claim("mission");
    }

    function close(): void {
        BottomEdge.release("mission");
    }

    function toggle(): void {
        if (root.shown)
            root.close();
        else
            root.open();
    }
}
