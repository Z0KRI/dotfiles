// REPOSITORIO: el que abre cosas fuera de la shell. Spotlight le pide abrir
// una página, un archivo, una carpeta o correr un comando, y no sabe con qué
// programa se hace cada uno: eso solo lo sabe este archivo.
//
//   - Páginas y archivos: xdg-open, que pregunta a tu sistema cuál es la app
//     predeterminada (el navegador para https://, el visor de PDF para .pdf).
//   - Carpetas: el gestor de archivos directo. xdg-open, sin un escritorio
//     completo detrás, a veces cae en mailcap y abre la carpeta en una
//     terminal; lo descubrimos con rofi y aquí no se repite.
//   - Mostrar en carpeta: nautilus --select, como Cmd+Enter en macOS.
//
// Todo va con execDetached: el programa queda suelto de Quickshell. Si
// recargas la shell, tu PDF no se cierra con ella.

pragma Singleton

import Quickshell

Singleton {
    id: root

    // El mismo de hypr/theme/config/programs.lua (fileManager).
    readonly property string fileManager: "nautilus"

    function openUri(uri): void {
        if (!uri)
            return;

        Quickshell.execDetached(["xdg-open", uri]);
    }

    function openFile(path): void {
        root.openUri(path);
    }

    function openFolder(path): void {
        if (!path)
            return;

        Quickshell.execDetached([root.fileManager, path]);
    }

    // Abre la carpeta que contiene `path`, con el archivo ya seleccionado.
    function reveal(path): void {
        if (!path)
            return;

        Quickshell.execDetached([root.fileManager, "--select", path]);
    }

    // Un comando escrito a mano (Spotlight › "> comando"). Va por sh -c para
    // que funcionen las tuberías y las comillas, igual que en una terminal,
    // pero sin terminal: lo que imprima no se ve.
    function run(command): void {
        if (!command)
            return;

        Quickshell.execDetached(["sh", "-c", command]);
    }
}
