// UTILIDAD: el trazado del marco como texto SVG. Recibe números y devuelve
// un "d" de SVG; no sabe de la barra, del tema ni de Wayland, igual que
// Fuzzy o CalendarMath. Por eso se puede probar sola.
//
// Es el mismo trazado del lienzo "Shell orgánica" (dirección C · Marco),
// pasado de JavaScript de página a JavaScript de QML casi línea por línea.
//
// ── La idea ─────────────────────────────────────────────────────────────
//
// El marco NO se dibuja como cuatro tiras y unas pestañas pegadas. Es UNA
// figura: el rectángulo de la pantalla con un hueco, y el hueco es lo que
// ves del escritorio. Pestañas y cajones son entrantes del hueco. Con
// fillRule OddEvenFill (la regla con la que una "O" tiene agujero), lo que
// queda entre el borde de afuera y el hueco se rellena: el marco.
//
// Así no hay uniones: el ala de una pestaña es parte del mismo trazo que el
// marco, y el antialiasing es uno solo.
//
// ── Las curvas ──────────────────────────────────────────────────────────
//
// Todas son cuadráticas (Q en SVG) con el punto de control en la esquina,
// como en IslandShape: llegan tangentes y la unión no se nota. Un arco de
// círculo deja un quiebre que se ve.
//
//   ala      cóncava: la figura entra hacia la pestaña.
//   esquina  convexa: la punta de afuera de la pestaña o del cajón.
//
// Si una pestaña es más baja que su ala y su esquina juntas (mientras se
// esconde, por ejemplo), las dos se encogen en proporción: fit().

pragma Singleton

import Quickshell

Singleton {
    id: root

    // Redondea a décimas: el texto queda corto y Qt no ve cambios de
    // 0.0001 px como cambios de figura.
    function n(value): real {
        return Math.round(value * 10) / 10;
    }

    // ¿Caben ala + esquina en lo que baja la pestaña por debajo de la
    // franja de arriba? Si no, se encogen juntas. Devuelve [ala, esquina].
    function fit(depth, band, wing, corner) {
        const room = Math.max(0, depth - band);
        const k = wing + corner > 0 ? Math.min(1, room / (wing + corner)) : 0;
        return [wing * k, corner * k];
    }

    // g = {
    //   width, height        la pantalla
    //   band                 alto de la franja de arriba (el marco, o la
    //                        barra sólida entera cuando se oculta sola)
    //   side                 grosor del marco a los lados y abajo
    //   topRadius            esquinas de la pantalla debajo de las pestañas
    //   bottomRadius         esquinas de abajo
    //   left:  { x, depth, wing, corner }   pestaña izquierda: x es su orilla derecha
    //   right: { x, depth, wing, corner }   pestaña derecha:   x es su orilla izquierda
    //   drawer: { x, top, bottom, wing, corner }
    //                        el cajón del borde izquierdo: x es su orilla derecha;
    //                        con x igual a `side` está cerrado
    //   notifications        cuánto engorda el borde derecho (el panel de
    //                        notificaciones), de arriba abajo; 0 = cerrado
    // }
    function build(g): string {
        const W = g.width;
        const H = g.height;
        const band = g.band;
        const left = g.side;
        const right = W - g.side;
        const bottom = H - g.side;
        const rTop = g.topRadius;
        const rBottom = g.bottomRadius;

        // Pestaña izquierda.
        const L = g.left.x;
        const hL = Math.max(band, g.left.depth);
        const [wL, cL] = root.fit(hL, band, g.left.wing, g.left.corner);

        // Pestaña derecha (y el cajón que crece de ella).
        const R = g.right.x;
        const hR = Math.max(band, g.right.depth);
        const [wR, cR] = root.fit(hR, band, g.right.wing, g.right.corner);

        // Cajón del borde izquierdo: una pestaña acostada, con un ala arriba
        // y otra abajo. Cerrado mide 0 de ancho y sus curvas se encogen con
        // él, así sale "de la nada" sin una muesca.
        const dx = Math.max(left, g.drawer.x);
        const dw = dx - left;
        const ks = g.drawer.wing + g.drawer.corner > 0
            ? Math.min(1, dw / (g.drawer.wing + g.drawer.corner))
            : 0;
        const wS = g.drawer.wing * ks;
        const cS = g.drawer.corner * ks;

        // Nunca más arriba que la esquina de la pantalla de arriba: en una
        // pantalla muy baja, el cajón no se mete en la pestaña.
        const yt = Math.max(g.drawer.top, hL + rTop + wS);
        const yb = Math.max(yt, g.drawer.bottom);

        const p = (x, y) => root.n(x) + " " + root.n(y);

        // 1. El rectángulo de la pantalla.
        let d = "M0 0 L0 " + H + " L" + W + " " + H + " L" + W + " 0 Z ";

        // 2. El hueco. Empieza abajo a la izquierda y sube por el borde
        //    izquierdo, cruza por arriba, baja por la derecha y vuelve por
        //    abajo.

        // Borde izquierdo, con el cajón del menú del sistema.
        d += "M" + p(left, bottom - rBottom) + " ";
        d += "L" + p(left, yb + wS) + " Q" + p(left, yb) + " " + p(left + wS, yb) + " ";
        d += "L" + p(dx - cS, yb) + " Q" + p(dx, yb) + " " + p(dx, yb - cS) + " ";
        d += "L" + p(dx, yt + cS) + " Q" + p(dx, yt) + " " + p(dx - cS, yt) + " ";
        d += "L" + p(left + wS, yt) + " Q" + p(left, yt) + " " + p(left, yt - wS) + " ";

        // Esquina de arriba a la izquierda, debajo de la pestaña.
        d += "L" + p(left, hL + rTop) + " Q" + p(left, hL) + " " + p(left + rTop, hL) + " ";

        // Pestaña izquierda: su esquina de abajo y su ala.
        d += "L" + p(L - cL, hL) + " Q" + p(L, hL) + " " + p(L, hL - cL) + " ";
        d += "L" + p(L, band + wL) + " Q" + p(L, band) + " " + p(L + wL, band) + " ";

        // Notificaciones: el borde derecho engorda de arriba abajo, como una
        // barra lateral. Cuando alcanza a la pestaña, la pestaña se disuelve
        // en él: su esquina de abajo y la esquina de la pantalla debajo de
        // ella se encogen hasta 0, y lo único que queda de la pestaña es su
        // ala, que pasa a ser la esquina redondeada de arriba de la pantalla.
        const nW = Math.max(0, g.notifications || 0);
        const rightN = right - nW;
        const Re = Math.min(R, rightN);
        const kN = cR + rTop > 0 ? Math.min(1, Math.max(0, rightN - Re) / (cR + rTop)) : 0;
        const cRe = cR * kN;
        const rTe = rTop * kN;

        // La franja de arriba, hasta la pestaña derecha. (La isla cuelga de
        // aquí, pero es su propia ventana: no va en este trazo.)
        d += "L" + p(Re - wR, band) + " Q" + p(Re, band) + " " + p(Re, band + wR) + " ";
        d += "L" + p(Re, hR - cRe) + " Q" + p(Re, hR) + " " + p(Re + cRe, hR) + " ";

        // Esquina de arriba a la derecha, debajo de la pestaña.
        d += "L" + p(rightN - rTe, hR) + " Q" + p(rightN, hR) + " " + p(rightN, hR + rTe) + " ";

        // Lado derecho (o la orilla del panel) y abajo.
        d += "L" + p(rightN, bottom - rBottom) + " Q" + p(rightN, bottom) + " " + p(rightN - rBottom, bottom) + " ";
        d += "L" + p(left + rBottom, bottom) + " Q" + p(left, bottom) + " " + p(left, bottom - rBottom) + " Z";

        return d;
    }

    // ── Los cajones de abajo ────────────────────────────────────────────
    //
    // Spotlight y el portapapeles salen del borde de abajo. Son figuras
    // aparte (viven en su propia ventana, la que se queda con el teclado), del
    // mismo negro, y se meten `overlap` px en el marco para que no quede
    // costura. Cerrados miden 0 y sus curvas se encogen con ellos.
    //
    // Las dos miden en coordenadas de su propio item, no de la pantalla.

    // Al centro de un borde: un cuerpo de `bodyWidth` × `bodyHeight` con un
    // ala cóncava a cada lado. El item mide bodyWidth + 2 alas de ancho y
    // bodyHeight + overlap de alto; el borde del marco queda en
    // y = height - overlap.
    function bottomDrawer(bodyWidth, bodyHeight, wing, corner, overlap): string {
        const k = wing + corner > 0 ? Math.min(1, Math.max(0, bodyHeight) / (wing + corner)) : 0;
        const j = wing * k;
        const c = corner * k;

        // Siempre con las alas completas de ancho: así el item no cambia de
        // tamaño cuando las alas se encogen, y la figura no se mueve.
        const x0 = wing;
        const x1 = wing + bodyWidth;
        const base = Math.max(0, bodyHeight);
        const top = 0;
        const p = (x, y) => root.n(x) + " " + root.n(y);

        if (bodyHeight <= 0.5)
            return "M0 0";

        return "M" + p(x0 - j, base + overlap) + " L" + p(x0 - j, base)
             + " Q" + p(x0, base) + " " + p(x0, base - j)
             + " L" + p(x0, top + c) + " Q" + p(x0, top) + " " + p(x0 + c, top)
             + " L" + p(x1 - c, top) + " Q" + p(x1, top) + " " + p(x1, top + c)
             + " L" + p(x1, base - j) + " Q" + p(x1, base) + " " + p(x1 + j, base)
             + " L" + p(x1 + j, base + overlap) + " Z";
    }

    // En la esquina de abajo a la derecha: pegado a dos bordes, con una
    // unión cóncava hacia cada uno. El item mide bodyWidth + ala + overlap
    // de ancho y bodyHeight + ala + overlap de alto; las orillas del marco
    // quedan en x = width - overlap y en y = height - overlap.
    function cornerDrawer(bodyWidth, bodyHeight, wing, corner, overlap): string {
        const size = Math.min(bodyWidth, bodyHeight);
        const k = wing + corner > 0 ? Math.min(1, Math.max(0, size) / (wing + corner)) : 0;
        const j = wing * k;
        const c = corner * k;

        if (bodyWidth <= 0.5 || bodyHeight <= 0.5)
            return "M0 0";

        const R = wing + bodyWidth;      // la orilla derecha (el marco)
        const base = wing + bodyHeight;  // la de abajo (el marco)
        const x0 = wing;                 // la orilla izquierda del cuerpo
        const y0 = wing;                 // la de arriba
        const p = (x, y) => root.n(x) + " " + root.n(y);

        return "M" + p(R + overlap, y0 - j) + " L" + p(R, y0 - j)
             + " Q" + p(R, y0) + " " + p(R - j, y0)
             + " L" + p(x0 + c, y0) + " Q" + p(x0, y0) + " " + p(x0, y0 + c)
             + " L" + p(x0, base - j) + " Q" + p(x0, base) + " " + p(x0 - j, base)
             + " L" + p(x0 - j, base + overlap) + " L" + p(R + overlap, base + overlap) + " Z";
    }
}
