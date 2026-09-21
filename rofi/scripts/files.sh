#!/usr/bin/env bash
# ~/.config/rofi/scripts/files.sh  —  versión para rofi-blocks
#
# Búsqueda de archivos en vivo al estilo Spotlight:
#
#   Sin texto   -> los N archivos más recientes (caché de un find).
#   Escribiendo -> tras una pausa corta (debounce), busca en la caché Y
#                  en plocate, y sustituye la lista.
#
# Por qué rofi-blocks: un modo script normal solo recibe 5 estados y
# ninguno significa "cambió el texto". rofi-blocks sí manda un evento
# INPUT_CHANGE por cada tecla (con "input action": "send"), y eso es lo
# que hace posible el debounce: hay por fin un evento que rebotar.
#
# Y por qué esto escala cuando darle todo a rofi no escalaba: rofi tarda
# ~21 µs por fila en ingerir la lista (medido: 113k filas = 2,4 s). Aquí
# rofi nunca recibe más de FILES_HITS filas, así que la ingesta es
# despreciable sea cual sea el tamaño del disco.
#
# Lanzar:   rofi -show combi -blocks-wrap /home/zokri/.config/rofi/scripts/files.sh
#           ("blocks" en modes: de config.rasi; display-blocks ahí también)
#
#   OJO: -blocks-wrap TIENE que ir en la línea de comandos. El plugin lo
#   lee con find_arg_str(), que no mira config.rasi; puesto ahí se ignora
#   y el chip queda vacío.
#
# Requiere: rofi-blocks-git (AUR), plocate, gawk, show-icons y un tema de
#           iconos. Probado con rofi 2.0.0 y rofi-blocks 026073d.

ROOT="${FILES_ROOT:-$HOME}"
RECIENTES="${FILES_RECENT:-50}"     # filas de la primera vista
HITS="${FILES_HITS:-200}"           # resultados máximos por búsqueda
DEBOUNCE="${FILES_DEBOUNCE:-0.15}"  # segundos de silencio antes de buscar
TTL="${FILES_TTL:-60}"              # segundos de vida de la caché
GESTOR="${FILES_MANAGER:-nautilus}" # para carpetas
ABRIDOR="${FILES_OPENER:-xdg-open}" # para archivos
DB="${FILES_DB:-}"                  # base de plocate alternativa (pruebas)
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/rofi-files.raw"

FORMATO='%TY-%Tm-%Td %TH:%TM:%TS\t%y\t%s\t%h\t%f\n'

# Las tildes necesitan una locale UTF-8 en DOS sitios: plocate aborta con
# "Invalid or incomplete multibyte character" sin ella, y tolower() no
# convierte Ó en ó. rofi hereda el entorno de la sesión, que normalmente
# ya es UTF-8; esto solo actúa si no lo es. (C.UTF-8 viene integrada en
# glibc >= 2.35.)
[[ $(locale charmap 2>/dev/null) == UTF-8 ]] || export LC_CTYPE=C.UTF-8

# gawk pliega mayúsculas acentuadas en UTF-8; mawk no lo hace nunca. Se
# usa solo para la comparación de nombres, que es donde importa.
AWK_UTF=$(command -v gawk || command -v awk)

# Formato en que rofi-blocks nos escribe los eventos. El separador es el
# carácter 0x1F: no puede aparecer en lo que tecleas ni en una ruta, a
# diferencia de un espacio o un tabulador. \u001f es el escape JSON, que
# rofi-blocks decodifica. {{value}} va el último para que lo tecleado
# pueda contener cualquier cosa.
export EVENTO='{{name_enum}}\u001f{{data}}\u001f{{value}}'

# --------------------------------------------------------------------
# Caché: el recorrido completo, en crudo (5 columnas de find).
# Sirve para dos cosas: la primera vista (lo reciente) y para encontrar
# lo creado hoy, que plocate aún no tiene indexado (su base se regenera
# una vez al día).
# --------------------------------------------------------------------
listar_crudo() {
    # -prune sobre '.?*' corta la RAMA entera: sin eso ~/.rustup o
    # ~/.mozilla se recorrerían y se listarían enteros.
    # La fecha va primera y de ancho fijo (%TS: siempre 13 caracteres),
    # así que LC_ALL=C sort -r ordena cronológicamente byte a byte.
    find "$ROOT" -mindepth 1 \
         \( -name '.?*' -o -name 'node_modules' -o -name '__pycache__' \) -prune -o \
         -printf "$FORMATO" 2>/dev/null \
    | LC_ALL=C sort -r -S 32M
}

# Temporal + mv: si listar_crudo() muere a medias, no se instala nada.
construir() {
    if listar_crudo > "$CACHE.$$"; then
        mv -f "$CACHE.$$" "$CACHE"
    else
        rm -f "$CACHE.$$"
        return 1
    fi
}

refrescar_si_caduco() {
    (( $(date +%s) - $(stat -c %Y "$CACHE") > TTL )) || return 0
    (
        # flock -n: si ya hay otro recorriendo el disco, no se duplica.
        exec 9> "$CACHE.lock"
        flock -n 9 || exit 0
        construir
    ) >/dev/null 2>&1 &
}

# --------------------------------------------------------------------
# De 5 columnas crudas a un mensaje JSON de rofi-blocks, en UNA línea.
# rofi-blocks lee línea a línea: un salto de línea dentro del JSON
# partiría el mensaje y el parser fallaría.
# --------------------------------------------------------------------
a_json() {
    LC_ALL=C awk -F'\t' '
        BEGIN { home = ENVIRON["HOME"]; hl = length(home); n = 0 }

        # Pango es XML: & y < en un nombre romperían el markup.
        function pango(s) {
            if (index(s, "&")) gsub(/&/, "\\&amp;", s)
            if (index(s, "<")) gsub(/</, "\\&lt;",  s)
            return s
        }
        # Escape JSON. Se hace con split() y no con gsub() porque las
        # barras invertidas en el reemplazo de gsub se interpretan
        # distinto en gawk y en mawk; así sale igual en los dos.
        function js(s,    partes, k, i, r) {
            if (index(s, "\\")) {
                k = split(s, partes, /\\/); r = partes[1]
                for (i = 2; i <= k; i++) r = r "\\\\" partes[i]
                s = r
            }
            if (index(s, "\"")) {
                k = split(s, partes, /"/); r = partes[1]
                for (i = 2; i <= k; i++) r = r "\\\"" partes[i]
                s = r
            }
            # Un carácter de control sin escapar invalida TODO el mensaje
            # y rofi se queda en blanco. Rarísimo en un nombre, pero caro.
            gsub(/[\001-\037]/, "?", s)
            return s
        }
        function human(b) {
            if (b < 1024)       return b " B"
            if (b < 1048576)    return sprintf("%.0f KB", b/1024)
            if (b < 1073741824) return sprintf("%.1f MB", b/1048576)
            return sprintf("%.1f GB", b/1073741824)
        }
        {
            dir  = $4
            ruta = dir "/" $5
            if (substr(dir, 1, hl) == home) dir = "~" substr(dir, hl + 1)

            # Carpeta -> icono de carpeta. Archivo -> miniatura XDG; si no
            # hay thumbnailer para el tipo, rofi cae al icono de mimetype.
            if ($2 == "d") { clase = "Carpeta"; icono = "folder" }
            else           { clase = human($3); icono = "thumbnail://" ruta }

            texto = pango($5) "   <span size=\x27small\x27 fgcolor=\x27#86868B\x27>" \
                    clase " · " substr($1, 1, 16) " · " pango(dir) "</span>"

            filas = filas (n++ ? "," : "") \
                "{\"text\":\"" js(texto) "\",\"markup\":true," \
                "\"icon\":\"" js(icono) "\",\"data\":\"" js(ruta) "\"}"
        }
        END {
            if (n == 0)
                filas = "{\"text\":\"Sin resultados\",\"nonselectable\":true}"
            # "input action": "send" es lo que desactiva el filtrado propio
            # de rofi y hace que cada tecla nos llegue como INPUT_CHANGE.
            # "overlay": "" oculta el aviso de "Indexando" si lo hubo.
            #
            # NUNCA se manda "prompt". En rofi-blocks el prompt y la
            # etiqueta del chip son el mismo campo (display_name), así que
            # pisaría el glifo del chip. Y peor: al cambiarlo, el plugin
            # hace g_free() del nombre anterior, y si ese nombre vino de
            # -display-blocks en la línea de comandos, rofi 2.0 lo guarda
            # como puntero a argv (memoria de la pila): segfault garantizado.
            printf "{\"input action\":\"send\",\"event format\":\"%s\"," \
                   "\"overlay\":\"\",\"lines\":[%s]}\n",
                   ENVIRON["EVENTO"], filas
        }'
}

recientes() {
    head -n "$RECIENTES" "$CACHE" 2>/dev/null | a_json
}

buscar() {
    local consulta="$1"
    {
        # 1) Caché: coincidencia en el NOMBRE. Atrapa lo creado desde el
        #    último updatedb. Sin LC_ALL=C a propósito: tolower() necesita
        #    la locale real para las tildes (Ó -> ó). La consulta viaja por
        #    ENVIRON y no por -v, que interpretaría sus barras invertidas.
        [[ -s $CACHE ]] && Q="$consulta" "$AWK_UTF" -F'\t' \
            'BEGIN { q = tolower(ENVIRON["Q"]) } index(tolower($5), q)' "$CACHE" \
            | head -n "$HITS"

        # 2) plocate: todo el disco. Varios patrones son un AND, así que
        #    pasar "$ROOT" primero limita a tu home. -files0-from permite
        #    que find ponga fecha y tamaño a las rutas que da plocate.
        plocate ${DB:+-d "$DB"} -0 -i -l "$HITS" -- "$ROOT" "$consulta" 2>/dev/null \
        | find -files0-from - -maxdepth 0 -printf "$FORMATO" 2>/dev/null
    } \
    | awk -F'\t' '!visto[$4 "/" $5]++' \
    | LC_ALL=C sort -r \
    | head -n "$HITS" \
    | a_json
}

abrir() {
    local ruta="$1"
    [[ -z $ruta ]] && return
    # setsid -f + redirecciones: el hijo no hereda nada de rofi, así que
    # rofi puede cerrarse aunque el programa abierto siga vivo.
    if [[ -d $ruta ]]; then
        setsid -f "$GESTOR"  "$ruta" >/dev/null 2>&1 </dev/null
    else
        setsid -f "$ABRIDOR" "$ruta" >/dev/null 2>&1 </dev/null
    fi
}

# --------------------------------------------------------------------
# Arranque
# --------------------------------------------------------------------
umask 077
mkdir -p "${CACHE%/*}"

if [[ -s $CACHE ]]; then
    recientes
    refrescar_si_caduco
else
    # Primer arranque: el recorrido puede tardar. Se pinta un aviso YA y
    # la lista cuando esté; rofi-blocks actualiza la ventana con cada
    # línea que le llega, sin esperar a que el script termine.
    printf '{"input action":"send","event format":"%s","overlay":"Indexando…"}\n' "$EVENTO"
    construir
    recientes
fi

# --------------------------------------------------------------------
# Bucle de eventos con debounce
#
# Un solo hilo, sin procesos en segundo plano: mientras haya una búsqueda
# pendiente, read espera como mucho DEBOUNCE segundos. Si llega otra
# tecla, se reinicia la espera; si vence el plazo (read devuelve >128),
# el usuario dejó de teclear y se busca. Sin hilos no hay carreras ni dos
# búsquedas escribiendo a la vez en la salida.
# --------------------------------------------------------------------
pendiente=0
consulta=""

while :; do
    if (( pendiente )); then
        IFS=$'\x1f' read -r -t "$DEBOUNCE" nombre datos valor
        rc=$?
        if (( rc > 128 )); then
            pendiente=0
            if [[ -z $consulta ]]; then recientes; else buscar "$consulta"; fi
            continue
        fi
    else
        IFS=$'\x1f' read -r nombre datos valor
        rc=$?
    fi

    (( rc != 0 )) && exit 0          # rofi cerró el canal

    case $nombre in
        INPUT_CHANGE)
            consulta=$valor
            pendiente=1
            ;;
        SELECT_ENTRY)
            abrir "$datos"
            # rofi-blocks no cierra rofi al elegir una fila (devuelve
            # RELOAD_DIALOG); lo que lo cierra es que el script termine.
            exit 0
            ;;
    esac
done