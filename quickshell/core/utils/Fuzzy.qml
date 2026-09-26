pragma Singleton

import Quickshell

Singleton {
    function score(text, needle) {
        if (!text || !needle) return 0;

        const t = text.toLowerCase();

        if (t === needle) return 100;
        if (t.startsWith(needle)) return 80;

        const at = t.indexOf(needle);
        if (at >= 0) return 60 - Math.min(at, 20);

        let j = 0;
        for (let i = 0; i < t.length && j < needle.length; i++) {
            if (t[i] === needle[j]) j++;
        }
        return j === needle.length ? 20 : 0;
    }
}