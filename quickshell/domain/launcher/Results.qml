pragma Singleton

// pragma Singleton va en la PRIMERA línea a propósito: el escáner de
// Quickshell solo lo busca en la cabecera, y la cabecera termina en la
// primera línea que tenga una llave, aunque sea un comentario. El
// comentario de abajo tiene llaves.
//
// MODELO + MAPPERS: la forma común de un resultado de Spotlight.
//
// Una app, un archivo, una entrada del portapapeles y una búsqueda web no se
// parecen en nada: cada fuente trae sus propios campos. La lista de Spotlight
// solo sabe dibujar una cosa. Así que cada fuente pasa por su mapper (las
// funciones de abajo) y sale con la misma forma:
//
//   {
//     kind:     "app" | "file" | "folder" | "clip" | "image" | "url" | "web"
//               | "command" | "header" | "notice"
//     key:      único en la lista (para no confundir dos filas)
//     title:    el texto principal
//     subtitle: el texto gris de abajo ("" si no hay)
//     icon:     nombre de ícono del tema ("" si no hay), como Icon= de un .desktop
//     image:    ruta de una imagen para usar de miniatura ("" si no es imagen)
//     action:   qué pasa con Enter: "open" | "switch" | "paste" | "copy"
//               | "search" | "run"
//     modified: fecha en segundos (archivos), 0 en lo demás
//     target:   el objeto original de la fuente, para cuando lo elijas
//   }
//
// Es lo mismo que tus mappers de S.I.R.A (asset-entity.mapper.ts): la entidad
// de afuera entra, el modelo que usa tu app sale. Los glifos de Lucide y los
// textos de las teclas NO van aquí: son de la vista y los pone el panel.


import Quickshell

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")

    // ── Las que no se eligen ─────────────────────────────────────
    function header(title) {
        return { kind: "header", key: "header:" + title, title: title };
    }

    function notice(title, subtitle) {
        return { kind: "notice", key: "notice:" + title, title: title, subtitle: subtitle || "" };
    }

    function selectable(result) {
        return !!result && result.kind !== "header" && result.kind !== "notice";
    }

    // ── Apps ─────────────────────────────────────────────────────
    // `window`: la ventana abierta de esa app, o null. Con ventana, Enter va a
    // ella en vez de abrir otra (la regla vive en LaunchApp).
    function app(entry, window) {
        return {
            kind: "app",
            key: "app:" + entry.id,
            title: entry.name,
            subtitle: entry.genericName || entry.comment || "",
            icon: entry.icon || "",
            image: "",
            action: window ? "switch" : "open",
            modified: 0,
            target: entry
        };
    }

    // ── Archivos ─────────────────────────────────────────────────
    function file(file) {
        const slash = file.path.lastIndexOf("/");
        const name = file.path.slice(slash + 1);
        const folder = slash > 0 ? file.path.slice(0, slash) : "/";
        const image = !file.folder && root.isImage(name);

        return {
            kind: file.folder ? "folder" : "file",
            key: "file:" + file.path,
            title: name,
            subtitle: root.tilde(folder),
            icon: file.folder ? "folder" : root.iconForFile(name),
            image: image ? "file://" + file.path : "",
            action: "open",
            modified: file.modified,
            target: file
        };
    }

    // /home/zokri/Documentos → ~/Documentos
    function tilde(path) {
        if (root.home && (path === root.home || path.startsWith(root.home + "/")))
            return "~" + path.slice(root.home.length);
        return path;
    }

    function extension(name) {
        const dot = name.lastIndexOf(".");
        return dot > 0 ? name.slice(dot + 1).toLowerCase() : "";
    }

    readonly property var imageTypes: ["png", "jpg", "jpeg", "gif", "webp", "bmp", "svg", "avif", "ico", "tiff"]

    function isImage(name) {
        return root.imageTypes.indexOf(root.extension(name)) >= 0;
    }

    // Por extensión, con los nombres estándar de freedesktop: casi todos los
    // temas de íconos los traen. Si el tuyo no, la fila pone un glifo.
    readonly property var fileIcons: ({
        pdf: "application-pdf",
        doc: "x-office-document", docx: "x-office-document", odt: "x-office-document", rtf: "x-office-document",
        xls: "x-office-spreadsheet", xlsx: "x-office-spreadsheet", ods: "x-office-spreadsheet", csv: "x-office-spreadsheet",
        ppt: "x-office-presentation", pptx: "x-office-presentation", odp: "x-office-presentation",
        mp3: "audio-x-generic", flac: "audio-x-generic", wav: "audio-x-generic", ogg: "audio-x-generic",
        m4a: "audio-x-generic", opus: "audio-x-generic",
        mp4: "video-x-generic", mkv: "video-x-generic", webm: "video-x-generic", mov: "video-x-generic",
        avi: "video-x-generic",
        zip: "package-x-generic", tar: "package-x-generic", gz: "package-x-generic", xz: "package-x-generic",
        zst: "package-x-generic", "7z": "package-x-generic", rar: "package-x-generic",
        sh: "text-x-script", py: "text-x-script", js: "text-x-script", ts: "text-x-script",
        qml: "text-x-script", lua: "text-x-script", php: "text-x-script", rs: "text-x-script",
        go: "text-x-script", c: "text-x-script", cpp: "text-x-script", java: "text-x-script",
        html: "text-html", css: "text-css"
    })

    function iconForFile(name) {
        if (root.isImage(name))
            return "image-x-generic";
        return root.fileIcons[root.extension(name)] ?? "text-x-generic";
    }

    // ── Portapapeles ─────────────────────────────────────────────
    function clip(entry, pastes) {
        // cliphist describe las imágenes así: "[[ binary data 23 KiB png 800x600 ]]".
        // La expresión va aquí adentro y no en una propiedad: una propiedad
        // `var` convierte la expresión regular a un tipo de Qt y pierde exec().
        const binary = /^\[\[ binary data (.+) ([a-z0-9]+) (\d+)x(\d+) \]\]$/i.exec(entry.preview);

        if (binary) {
            return {
                kind: "image",
                key: "clip:" + entry.id,
                title: "Imagen " + binary[2].toUpperCase(),
                subtitle: binary[3] + " × " + binary[4] + " · " + binary[1],
                icon: "image-x-generic",
                image: "",
                action: pastes ? "paste" : "copy",
                modified: 0,
                target: entry
            };
        }

        // Una sola línea: los saltos y tabuladores se vuelven espacios.
        return {
            kind: "clip",
            key: "clip:" + entry.id,
            title: entry.preview.replace(/\s+/g, " ").trim() || " ",
            subtitle: "",
            icon: "",
            image: "",
            action: pastes ? "paste" : "copy",
            modified: 0,
            target: entry
        };
    }

    // ── Web y comandos ───────────────────────────────────────────
    function url(address) {
        return {
            kind: "url", key: "url:" + address, title: address,
            subtitle: "Abrir en el navegador", icon: "", image: "",
            action: "open", modified: 0, target: address
        };
    }

    function web(query, engine, address) {
        return {
            kind: "web", key: "web:" + query, title: query,
            subtitle: "Buscar en " + engine.label, icon: "", image: "",
            action: "search", modified: 0, target: address
        };
    }

    function command(text) {
        return {
            kind: "command", key: "command:" + text, title: text,
            subtitle: "Ejecutar comando", icon: "", image: "",
            action: "run", modified: 0, target: text
        };
    }
}
