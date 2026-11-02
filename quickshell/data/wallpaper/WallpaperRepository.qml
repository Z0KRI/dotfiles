pragma Singleton

// REPOSITORIO: los fondos de pantalla son las imágenes de una carpeta,
//     ~/Pictures/Wallpapers
// y nada más. No hay lista que mantener: lo que pongas ahí aparece en el
// selector, y lo que borres desaparece, sin recargar la shell.
//
// ¿Cómo se entera? FolderListModel (viene con Qt) vigila la carpeta con el
// observador de archivos del sistema (inotify). Cuando cambia, el modelo
// avisa fila por fila y aquí se rearma `files`.
//
// Dos detalles:
//   - Solo lee la carpeta, no subcarpetas.
//   - Una carpeta que todavía no existe no se puede vigilar. Por eso, al
//     arrancar, primero se crea (mkdir -p no toca nada si ya está) y solo
//     después se empieza a leer.

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string folder: Quickshell.env("HOME") + "/Pictures/Wallpapers"

    // [{ name: "niebla", file: "niebla.jpg", path: "/home/…/niebla.jpg",
    //    url: "file:///home/…/niebla.jpg" }], por nombre.
    property var files: []

    // Ya se leyó la carpeta al menos una vez (antes, `files` vacío no quiere
    // decir "no hay fondos").
    property bool loaded: false

    // La carpeta ya existe y se está vigilando.
    property bool ready: false

    // Abre la carpeta en el gestor de archivos (para el "Abrir carpeta" del
    // selector cuando está vacía).
    function openFolder(): void {
        Quickshell.execDetached(["xdg-open", root.folder]);
    }

    function rebuild(): void {
        if (listing.status !== FolderListModel.Ready)
            return;

        const out = [];
        for (let i = 0; i < listing.count; ++i) {
            const file = String(listing.get(i, "fileName"));
            const path = String(listing.get(i, "filePath"));
            const dot = file.lastIndexOf(".");

            // La url la arma Qt (fileUrl) y no "file://" + ruta: un nombre
            // con # o ? rompería la de a mano.
            out.push({
                name: dot > 0 ? file.slice(0, dot) : file,
                file: file,
                path: path,
                url: String(listing.get(i, "fileUrl"))
            });
        }

        root.files = out;
        root.loaded = true;
    }

    Process {
        running: true
        command: ["mkdir", "-p", root.folder]
        onExited: root.ready = true
    }

    FolderListModel {
        id: listing

        folder: root.ready ? "file://" + root.folder : ""

        // Lo que Qt sabe pintar. Sin distinguir mayúsculas: FOTO.JPG también.
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp", "*.gif", "*.avif", "*.jxl", "*.tif", "*.tiff"]
        caseSensitive: false

        showDirs: false
        showDotAndDotDot: false
        showHidden: false
        sortField: FolderListModel.Name

        onStatusChanged: root.rebuild()
    }

    // Llegó, se fue o cambió de nombre un archivo.
    Connections {
        target: listing

        function onRowsInserted() { root.rebuild(); }
        function onRowsRemoved() { root.rebuild(); }
        function onModelReset() { root.rebuild(); }
        function onDataChanged() { root.rebuild(); }
    }
}
