#!/usr/bin/env bash
#
# Modo script "web" para rofi.
#
# NO aporta ninguna entrada a la lista. Existe solo para capturar el texto
# que no coincide con nada. combi delega la entrada personalizada al PRIMER
# modo de combi-modes (source/modes/combi.c -> switchers[0]), así que este
# tiene que ir el primero de la lista o no recibe nada.
#
# Qué hace con lo que escribas:
#   1. Parece una URL           -> la abre en el navegador
#   2. Es un comando en $PATH   -> lo ejecuta
#   3. Cualquier otra cosa      -> lo busca en la web
#
# Uso en config.rasi:
#   combi-modes: "web:/home/zokri/.config/hypr/theme/scripts/rofi_web.sh,window,drun,run";

set -uo pipefail

BUSCADOR="https://duckduckgo.com/?q="

# ROFI_RETV=0 es el arranque: no imprimimos entradas, la lista queda intacta.
if [[ "${ROFI_RETV:-0}" == "0" ]]; then
    exit 0
fi

query="${1:-}"
[[ -z "$query" ]] && exit 0

abrir() {
    # setsid para que el proceso sobreviva al cierre de rofi
    setsid -f xdg-open "$1" >/dev/null 2>&1
}

# 1. URL explícita
if [[ "$query" =~ ^(https?|ftp|file)://[^[:space:]]+$ ]]; then
    abrir "$query"
    exit 0
fi

# 2. Dominio sin esquema: algo.algo, sin espacios, con TLD de 2+ letras.
#    La lista de extensiones evita que "notas.txt" se tome por dominio.
EXTENSIONES='txt|md|sh|lua|conf|rasi|json|yaml|yml|toml|log|png|jpg|jpeg|gif|svg|webp|pdf|zip|tar|gz|py|js|ts|css|html|c|cpp|h|rs|go|php|sql|csv|mp3|mp4|mkv'

if [[ "$query" =~ ^[a-zA-Z0-9._~-]+\.[a-zA-Z]{2,}(/[^[:space:]]*)?$ ]]; then
    extension="${query##*.}"
    if [[ ! "${extension,,}" =~ ^(${EXTENSIONES})$ ]]; then
        abrir "https://$query"
        exit 0
    fi
fi

# 3. Comando ejecutable: recupera el "custom input" que normalmente
#    manejaría el modo run, y que este script se estaría tragando.
primera_palabra="${query%% *}"
if command -v "$primera_palabra" >/dev/null 2>&1; then
    setsid -f sh -c "$query" >/dev/null 2>&1
    exit 0
fi

# 4. Si no es nada de lo anterior, a buscar
#    (jq no hace falta: solo escapamos espacios y los caracteres problemáticos)
escapado=$(printf '%s' "$query" | sed -e 's/%/%25/g' -e 's/&/%26/g' -e 's/#/%23/g' -e 's/+/%2B/g' -e 's/ /+/g')
abrir "${BUSCADOR}${escapado}"
exit 0
