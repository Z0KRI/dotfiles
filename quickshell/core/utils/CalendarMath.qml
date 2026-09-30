// UTILIDAD: cuentas de calendario. No sabe nada de la barra ni del tema:
// recibe fechas y devuelve datos, igual que Fuzzy.

pragma Singleton

import Quickshell

Singleton {
    id: root

    // ¿Dos fechas caen en el mismo día?
    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate();
    }

    // Las 42 celdas (6 semanas) de un mes.
    // month va de 0 a 11, como en Date.
    // firstDayOfWeek: 0 = domingo, 1 = lunes...
    function monthGrid(year, month, firstDayOfWeek, today) {
        const first = new Date(year, month, 1);

        // Cuántos días del mes anterior se asoman antes del día 1.
        const offset = (first.getDay() - firstDayOfWeek + 7) % 7;

        const cells = [];
        for (let i = 0; i < 42; i++) {
            // Date corrige solo los desbordes: el día 0 es el último
            // del mes anterior, el 32 cae en el mes siguiente.
            const day = new Date(year, month, 1 - offset + i);

            cells.push({
                day: day.getDate(),
                inMonth: day.getMonth() === month,
                isToday: root.sameDay(day, today)
            });
        }

        return cells;
    }
}