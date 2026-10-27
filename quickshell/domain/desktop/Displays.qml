pragma Singleton

// CASO DE USO: los monitores, como en Ajustes › Pantallas de macOS.
// Reglas:
//   - Todo cambio que pueda dejarte sin imagen (modo, escala, rotación, VRR,
//     duplicar, apagar) se aplica a prueba: o lo conservas en 15 s o se
//     revierte solo. Acomodar los monitores no pregunta: no apaga nada.
//   - Lo que conservas se guarda en hypr/hosts/displays.lua.
//   - El último monitor encendido no se puede apagar.
//   - Al cambiar de tamaño un monitor, los que estaban a su derecha o abajo
//     se recorren lo mismo: siguen pegados, sin huecos ni encimados.
//   - Al acomodarlos, un monitor siempre queda pegado al borde de otro
//     (como en macOS) y sin encimarse. Luego todo se recorre para que la
//     esquina de arriba a la izquierda quede en 0×0.
//   - La escala solo ofrece valores que Hyprland acepta tal cual (que dejan
//     un tamaño lógico entero). Si le das otro, lo cambia y te avisa en rojo.
//   - Las frecuencias se escriben redondeadas ("144 Hz" para 143.91) salvo
//     que dos se redondeen igual: entonces van con decimales (60 y 59.94).
//
// Tamaños: Hyprland mide la posición en píxeles LÓGICOS (los de la pantalla
// divididos entre la escala, y al revés si está girado 90° o 270°). Todo lo
// de acomodar trabaja en esos.

import QtQuick
import Quickshell
import qs.data.hyprland

Singleton {
    id: root

    readonly property int confirmSeconds: 15

    readonly property var monitors: MonitorRepository.monitors.map(monitor => root.describe(monitor))
    readonly property var active: root.monitors.filter(monitor => !monitor.disabled)
    readonly property bool loaded: MonitorRepository.loaded
    readonly property string lastError: MonitorRepository.lastError

    // Los que tienen lugar propio en el escritorio (ni apagados ni duplicando).
    readonly property var arranged: root.active.filter(monitor => monitor.mirror === "")

    // ── la prueba de 15 segundos ─────────────────────────────────
    property var pending: null          // { previous: [reglas], next: [reglas] }
    property int secondsLeft: 0
    readonly property bool confirming: root.pending !== null

    function refresh(): void {
        MonitorRepository.refresh();
    }

    function find(name) {
        return root.monitors.find(monitor => monitor.name === name) ?? null;
    }

    // ── lo que se ve de cada monitor ─────────────────────────────
    function describe(raw) {
        const modes = root.parseModes(raw.availableModes ?? []);
        const rotated = (raw.transform | 0) % 2 === 1;
        const scale = raw.scale > 0 ? raw.scale : 1;
        const pixelW = rotated ? raw.height : raw.width;
        const pixelH = rotated ? raw.width : raw.height;
        const saved = MonitorRepository.savedRule(raw.name);

        return {
            name: raw.name,
            title: raw.description || raw.name,
            model: [raw.make, raw.model].filter(part => part && part.length > 0).join(" "),
            focused: !!raw.focused,
            disabled: !!raw.disabled,
            mirror: raw.mirrorName ?? "",

            width: raw.width,
            height: raw.height,
            refreshRate: raw.refreshRate,
            scale: scale,
            transform: raw.transform | 0,
            // El JSON solo dice si VRR está activo AHORA. El modo configurado
            // (siempre / solo pantalla completa) se recuerda de lo guardado.
            vrr: saved && saved.vrr !== undefined ? saved.vrr : (raw.vrr ? 1 : 0),

            x: raw.x,
            y: raw.y,
            logicalWidth: Math.round(pixelW / scale),
            logicalHeight: Math.round(pixelH / scale),

            modes: modes,
            resolutions: root.resolutionsOf(modes),
            rates: root.rateLabels(root.ratesOf(modes, raw.width, raw.height)),
            scales: root.scalesFor(raw.width, raw.height, scale),

            label: raw.width + " × " + raw.height + " · " + Math.round(raw.refreshRate) + " Hz"
        };
    }

    // "2560x1440@143.91Hz" → { width, height, rate }
    function parseModes(list) {
        return list
            .map(text => /^(\d+)x(\d+)@([\d.]+)/.exec(text))
            .filter(match => match !== null)
            .map(match => ({ width: parseInt(match[1]), height: parseInt(match[2]), rate: parseFloat(match[3]) }));
    }

    // Una entrada por resolución, de la más grande a la más chica.
    function resolutionsOf(modes) {
        const seen = {};
        const out = [];
        for (const mode of modes) {
            const key = mode.width + "x" + mode.height;
            if (seen[key])
                continue;
            seen[key] = true;
            out.push({ width: mode.width, height: mode.height });
        }
        return out.sort((a, b) => b.width * b.height - a.width * a.height || b.width - a.width);
    }

    // Las frecuencias de UNA resolución, de la más alta a la más baja.
    function ratesOf(modes, width, height) {
        const seen = {};
        return modes
            .filter(mode => mode.width === width && mode.height === height)
            .map(mode => Math.round(mode.rate * 100) / 100)
            .filter(rate => {
                if (seen[rate])
                    return false;
                seen[rate] = true;
                return true;
            })
            .sort((a, b) => b - a);
    }

    // [143.91, 120, 59.95] → [{ rate, label: "144 Hz" }, ...]
    function rateLabels(rates) {
        return rates.map(rate => {
            const rounded = Math.round(rate);
            const clash = rates.some(other => other !== rate && Math.round(other) === rounded);
            const text = Number.isInteger(rate) || !clash ? String(rounded) : rate.toFixed(2);
            return { rate: rate, label: text + " Hz" };
        });
    }

    // La misma búsqueda que hace Hyprland (Monitor.cpp): de la escala pedida,
    // la fracción n/120 más cercana que deje un tamaño lógico entero.
    function validScale(width, height, wanted) {
        const fits = scale => Number.isInteger(width / scale) && Number.isInteger(height / scale);
        const base = Math.round(wanted * 120);

        if (fits(base / 120))
            return base / 120;

        for (let step = 1; step < 90; ++step) {
            if (fits((base + step) / 120))
                return (base + step) / 120;
            if (base - step > 0 && fits((base - step) / 120))
                return (base - step) / 120;
        }
        return 0;
    }

    // Las opciones de "Texto más grande ↔ Más espacio", de la escala mayor a
    // la menor. Hasta cinco, como en macOS, y sin bajar de 1024 × 600 lógicos
    // (en un ultra ancho, 3.2 dejaría el escritorio en 1075 × 450).
    function scalesFor(width, height, current) {
        if (!(width > 0) || !(height > 0))
            return [];

        const wanted = [1, 1.25, 1.5, 1.75, 2, 2.5, 3];
        const found = [];

        for (const target of wanted) {
            const scale = root.validScale(width, height, target);
            if (scale > 0 && width / scale >= 1024 && height / scale >= 600
                    && found.every(other => Math.abs(other - scale) > 0.01))
                found.push(scale);
        }

        if (current > 0 && found.every(other => Math.abs(other - current) > 0.01))
            found.push(current);

        found.sort((a, b) => b - a);

        // Si sobran, se queda con las de los extremos y las de en medio,
        // pero nunca deja fuera la actual.
        while (found.length > 5) {
            const middle = Math.floor(found.length / 2);
            const drop = Math.abs(found[middle] - current) > 0.01 ? middle : middle + 1;
            found.splice(Math.min(drop, found.length - 2), 1);
        }

        return found.map(scale => ({
            scale: scale,
            width: Math.round(width / scale),
            height: Math.round(height / scale)
        }));
    }

    // ── la regla completa de un monitor, como la entiende hl.monitor() ──
    function ruleOf(monitor) {
        const saved = MonitorRepository.savedRule(monitor.name);
        const usable = monitor.width > 0 && monitor.height > 0;

        return {
            output: monitor.name,
            mode: usable
                ? monitor.width + "x" + monitor.height + "@" + monitor.refreshRate.toFixed(2)
                : (saved?.mode ?? "preferred"),
            position: monitor.x + "x" + monitor.y,
            // Con 6 decimales: si es n/120, Hyprland la redondea en silencio.
            scale: String(Number(monitor.scale.toFixed(6))),
            transform: monitor.transform,
            vrr: monitor.vrr,
            disabled: monitor.disabled,
            mirror: monitor.mirror
        };
    }

    function sizeOf(rule) {
        const mode = /^(\d+)x(\d+)/.exec(rule.mode);
        const scale = parseFloat(rule.scale) > 0 ? parseFloat(rule.scale) : 1;
        if (!mode)
            return { width: 0, height: 0 };

        const rotated = (rule.transform | 0) % 2 === 1;
        const width = parseInt(rotated ? mode[2] : mode[1]);
        const height = parseInt(rotated ? mode[1] : mode[2]);
        return { width: Math.round(width / scale), height: Math.round(height / scale) };
    }

    function positionOf(rule) {
        const match = /^(-?\d+)x(-?\d+)$/.exec(rule.position);
        return match ? { x: parseInt(match[1]), y: parseInt(match[2]) } : { x: 0, y: 0 };
    }

    // ── cambiar un monitor (a prueba) ────────────────────────────
    function setResolution(name, width, height): void {
        const monitor = root.find(name);
        if (!monitor)
            return;

        // Se queda con la frecuencia actual si esa resolución la tiene; si
        // no, con la más alta.
        const rates = root.ratesOf(monitor.modes, width, height);
        const current = Math.round(monitor.refreshRate * 100) / 100;
        const rate = rates.indexOf(current) >= 0 ? current : (rates[0] ?? 60);
        root.change(name, { mode: width + "x" + height + "@" + rate.toFixed(2) });
    }

    function setRate(name, rate): void {
        const monitor = root.find(name);
        if (monitor)
            root.change(name, { mode: monitor.width + "x" + monitor.height + "@" + Number(rate).toFixed(2) });
    }

    function setScale(name, scale): void {
        root.change(name, { scale: String(Number(Number(scale).toFixed(6))) });
    }

    function setTransform(name, transform): void {
        root.change(name, { transform: transform | 0 });
    }

    function setVrr(name, mode): void {
        root.change(name, { vrr: mode | 0 });
    }

    function setMirror(name, target): void {
        if (target === name || root.find(target)?.mirror === name)
            return;
        root.change(name, { mirror: target || "" });
    }

    function canDisable(name): bool {
        return root.active.length > 1 || root.find(name)?.disabled === true;
    }

    function setEnabled(name, on): void {
        if (!on && !root.canDisable(name))
            return;

        if (!on) {
            root.change(name, { disabled: true });
            return;
        }

        // Al encenderlo vuelve a donde estaba guardado, si ese lugar sigue
        // libre (mientras estuvo apagado, los otros pudieron recorrerse a su
        // hueco). Si no, a la derecha de todo.
        const saved = MonitorRepository.savedRule(name);
        const mode = saved?.mode && saved.mode !== "preferred" ? saved.mode : root.ruleOf(root.find(name)).mode;
        const right = root.arranged.reduce((edge, monitor) => Math.max(edge, monitor.x + monitor.logicalWidth), 0);

        let position = right + "x0";
        if (saved?.position) {
            const size = root.sizeOf(Object.assign({}, saved, { mode: mode }));
            const at = root.positionOf(saved);
            const box = { x: at.x, y: at.y, w: size.width, h: size.height };
            const taken = root.arranged.some(monitor => root.overlaps(box,
                { x: monitor.x, y: monitor.y, w: monitor.logicalWidth, h: monitor.logicalHeight }));
            if (!taken)
                position = saved.position;
        }

        root.change(name, { disabled: false, mode: mode, position: position });
    }

    // patch: los campos que cambian. Arma las reglas de antes y de después de
    // TODOS los monitores, recorre a los vecinos si cambió el tamaño, aplica
    // solo las que cambiaron y arranca la cuenta regresiva.
    function change(name, patch): void {
        if (root.confirming)
            return;

        const before = root.monitors.map(monitor => root.ruleOf(monitor));
        let after = before.map(rule => rule.output === name ? Object.assign({}, rule, patch) : rule);
        after = root.keepTogether(before, after, name);

        const changed = after.filter((rule, i) => JSON.stringify(rule) !== JSON.stringify(before[i]));
        if (changed.length === 0)
            return;

        root.pending = {
            previous: before.filter(rule => changed.some(other => other.output === rule.output)),
            next: changed
        };
        root.secondsLeft = root.confirmSeconds;
        countdown.restart();

        MonitorRepository.apply(changed);
    }

    // Si `name` cambió de tamaño (o se apagó), los de su derecha y los de
    // abajo se recorren lo mismo.
    function keepTogether(before, after, name) {
        const old = before.find(rule => rule.output === name);
        const now = after.find(rule => rule.output === name);
        if (!old || !now || old.disabled || old.mirror !== "")
            return after;

        const oldSize = root.sizeOf(old);
        const newSize = now.disabled || now.mirror !== "" ? { width: 0, height: 0 } : root.sizeOf(now);
        const dw = newSize.width - oldSize.width;
        const dh = newSize.height - oldSize.height;
        if (dw === 0 && dh === 0)
            return after;

        const origin = root.positionOf(old);
        const right = origin.x + oldSize.width;
        const bottom = origin.y + oldSize.height;

        return after.map(rule => {
            if (rule.output === name || rule.disabled || rule.mirror !== "")
                return rule;

            const at = root.positionOf(rule);
            const x = at.x >= right ? at.x + dw : at.x;
            const y = at.y >= bottom ? at.y + dh : at.y;
            return x === at.x && y === at.y ? rule : Object.assign({}, rule, { position: x + "x" + y });
        });
    }

    function keep(): void {
        if (!root.pending)
            return;

        countdown.stop();
        MonitorRepository.save(root.pending.next);
        root.pending = null;
    }

    function revert(): void {
        if (!root.pending)
            return;

        countdown.stop();
        MonitorRepository.apply(root.pending.previous);
        root.pending = null;
    }

    function reset(): void {
        if (!root.confirming)
            MonitorRepository.reset();
    }

    // ── acomodar (sin prueba) ────────────────────────────────────
    //
    // x, y: donde lo soltaste, en píxeles lógicos. Lo pega al borde más
    // cercano de otro monitor sin encimarlo, recorre todo a 0×0, aplica y
    // guarda.
    function move(name, x, y): void {
        if (root.confirming)
            return;

        const me = root.arranged.find(monitor => monitor.name === name);
        if (!me)
            return;

        const others = root.arranged.filter(monitor => monitor.name !== name);
        const spot = root.snap(me, others, Math.round(x), Math.round(y));

        // Todas las posiciones nuevas, recorridas para que la mínima sea 0×0.
        const placed = root.arranged.map(monitor => ({
            name: monitor.name,
            x: monitor.name === name ? spot.x : monitor.x,
            y: monitor.name === name ? spot.y : monitor.y
        }));
        const minX = Math.min(...placed.map(p => p.x));
        const minY = Math.min(...placed.map(p => p.y));

        const changed = [];
        for (const p of placed) {
            const monitor = root.find(p.name);
            const x2 = p.x - minX;
            const y2 = p.y - minY;
            if (x2 !== monitor.x || y2 !== monitor.y)
                changed.push(Object.assign(root.ruleOf(monitor), { position: x2 + "x" + y2 }));
        }

        if (changed.length === 0)
            return;

        MonitorRepository.apply(changed);
        MonitorRepository.save(changed);
    }

    function overlaps(a: var, b: var): bool {
        return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
    }

    // Las cuatro formas de pegarse a cada otro monitor (a su derecha, a su
    // izquierda, abajo, arriba), alineando el borde si quedó cerca. Gana la
    // más cercana a donde lo soltaste que no se encime con nadie.
    function snap(me: var, others: var, x: int, y: int): var {
        if (others.length === 0)
            return { x: 0, y: 0 };

        const w = me.logicalWidth;
        const h = me.logicalHeight;
        const rects = others.map(o => ({ x: o.x, y: o.y, w: o.logicalWidth, h: o.logicalHeight }));
        const clamp = (value, low, high) => Math.max(low, Math.min(high, value));

        // Que compartan al menos un 10 % del borde: si no, el ratón casi no
        // tendría por dónde pasar de uno a otro.
        const alongY = (o, wantY) => {
            const overlap = Math.round(Math.min(h, o.h) * 0.1);
            const ny = clamp(wantY, o.y - h + overlap, o.y + o.h - overlap);
            const tolerance = Math.round(Math.min(h, o.h) * 0.06);
            for (const edge of [o.y, o.y + o.h - h, o.y + Math.round((o.h - h) / 2)])
                if (Math.abs(ny - edge) <= tolerance)
                    return edge;
            return ny;
        };
        const alongX = (o, wantX) => {
            const overlap = Math.round(Math.min(w, o.w) * 0.1);
            const nx = clamp(wantX, o.x - w + overlap, o.x + o.w - overlap);
            const tolerance = Math.round(Math.min(w, o.w) * 0.06);
            for (const edge of [o.x, o.x + o.w - w, o.x + Math.round((o.w - w) / 2)])
                if (Math.abs(nx - edge) <= tolerance)
                    return edge;
            return nx;
        };

        let best = null;
        for (const o of rects) {
            const candidates = [
                { x: o.x + o.w, y: alongY(o, y) },
                { x: o.x - w, y: alongY(o, y) },
                { x: alongX(o, x), y: o.y + o.h },
                { x: alongX(o, x), y: o.y - h }
            ];

            for (const c of candidates) {
                const box = { x: c.x, y: c.y, w: w, h: h };
                if (rects.some(other => root.overlaps(box, other)))
                    continue;

                const distance = Math.hypot(c.x - x, c.y - y);
                if (best === null || distance < best.distance)
                    best = { x: c.x, y: c.y, distance: distance };
            }
        }

        return best ?? { x: me.x, y: me.y };
    }

    Timer {
        id: countdown
        interval: 1000
        repeat: true

        onTriggered: {
            root.secondsLeft -= 1;
            if (root.secondsLeft <= 0)
                root.revert();
        }
    }
}
