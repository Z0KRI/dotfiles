// CASO DE USO: quién ocupa el borde de abajo del marco.
// Reglas:
//   - De ahí salen cuatro cajones: Spotlight, el portapapeles, Mission
//     Control y el selector de fondos. Comparten el borde, así que solo uno
//     a la vez: abrir uno cierra el que estuviera.
//   - Cada uno pide el borde al abrirse (claim) y lo suelta al cerrarse
//     (release). Si otro lo pide, el primero se entera porque ya no es el
//     dueño: su `shown` sale de aquí.
//
// Así ninguno de los cuatro tiene que conocer a los otros tres. Antes el
// portapapeles cerraba Spotlight a mano; con cuatro, serían doce reglas.
//
// Los nombres: "spotlight", "clipboard", "mission", "wallpaper".

pragma Singleton

import Quickshell

Singleton {
    id: root

    // Quién lo tiene ahora; "" si nadie.
    property string owner: ""

    function claim(name): void {
        root.owner = String(name || "");
    }

    // Solo el dueño puede soltarlo: un cajón que se cierra tarde no le quita
    // el borde al que acaba de abrirse.
    function release(name): void {
        if (root.owner === name)
            root.owner = "";
    }

    function owns(name): bool {
        return root.owner === name;
    }
}
