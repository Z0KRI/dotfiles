// CASO DE USO: "Acerca de este equipo".
// Reglas:
//   - El procesador sin adornos de marketing: "AMD Ryzen 7 5800X 8-Core
//     Processor" → "AMD Ryzen 7 5800X", y los hilos aparte.
//   - La memoria en GB redondeada al tamaño de módulo más cercano (el kernel
//     reporta un poco menos de lo instalado: 31.3 GB son 32 GB).
//   - La gráfica por su nombre comercial: lo que va entre corchetes en lspci.
//   - Lo que no se pudo leer se muestra como "—", nunca vacío.

pragma Singleton

import Quickshell
import qs.data.system
import qs.data.session

Singleton {
    id: root

    readonly property var info: SystemInfoRepository.info

    readonly property string hostName: root.info.host || "—"
    readonly property string system: root.info.os || "Linux"
    readonly property string kernel: root.info.kernel || "—"
    readonly property string userName: SessionRepository.userName

    readonly property string processor: {
        const name = root.cleanCpu(root.info.cpu || "");
        if (!name)
            return "—";
        const threads = parseInt(root.info.cores || "0");
        return threads > 0 ? name + " · " + threads + " hilos" : name;
    }

    readonly property string memory: {
        const kb = parseInt(root.info.memory || "0");
        if (!(kb > 0))
            return "—";

        const gb = kb / 1048576;
        const rounded = gb < 3 ? Math.round(gb * 10) / 10 : Math.ceil(gb / 2) * 2;
        return rounded + " GB";
    }

    readonly property string graphics: root.cleanGpu(root.info.gpu || "")

    readonly property string hyprland: (root.info.hyprland || "").replace(/^v/, "") || "—"

    readonly property string quickshell: {
        const match = (root.info.quickshell || "").match(/\d+\.\d+(\.\d+)?/);
        return match ? match[0] : "—";
    }

    readonly property string uptime: root.formatUptime(parseInt(root.info.uptime || "0"))

    function refresh(): void {
        SystemInfoRepository.refresh();
    }

    function cleanCpu(text) {
        return text
            .replace(/\((R|TM)\)/gi, "")
            .replace(/\s+\d+-Core Processor/i, "")
            .replace(/\s+(CPU|Processor)\b/gi, "")
            .replace(/\s+with .*$/i, "")
            .replace(/\s*@.*$/, "")
            .replace(/\s+/g, " ")
            .trim();
    }

    function cleanGpu(text) {
        const raw = text.replace(/\(rev [^)]*\)/i, "").trim();
        if (!raw)
            return "—";

        let vendor = "";
        if (/nvidia/i.test(raw))
            vendor = "NVIDIA";
        else if (/amd|ati\b|advanced micro/i.test(raw))
            vendor = "AMD";
        else if (/intel/i.test(raw))
            vendor = "Intel";

        // El último [..] es el nombre comercial; el primero en AMD es "[AMD/ATI]".
        const brackets = raw.match(/\[[^\]]+\]/g) || [];
        const model = brackets.length > 0
            ? brackets[brackets.length - 1].slice(1, -1)
            : raw;

        if (!vendor || model.toLowerCase().indexOf(vendor.toLowerCase()) === 0)
            return model;
        return vendor + " " + model;
    }

    function formatUptime(seconds) {
        if (!(seconds > 0))
            return "—";

        const days = Math.floor(seconds / 86400);
        const hours = Math.floor((seconds % 86400) / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);

        if (days > 0)
            return days + (days === 1 ? " día, " : " días, ") + hours + " h";
        if (hours > 0)
            return hours + " h " + minutes + " min";
        return minutes + " min";
    }
}
