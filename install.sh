#!/usr/bin/env bash
#
# Instala los dotfiles en Arch Linux: paquetes, enlaces, fuentes y servicios.
# Se puede correr las veces que quieras: lo que ya está, lo deja.
#
#   ./install.sh               todo: paquetes + enlaces + servicios
#   ./install.sh --links       solo los enlaces y la fuente (no usa sudo)
#   ./install.sh --check       solo revisa qué falta; no cambia nada
#   ./install.sh --blueferry   además instala o actualiza BlueFerry (iPhone)
#   ./install.sh --calls       además prepara las llamadas del iPhone (oFono)
#   ./install.sh --airpods     además LibrePods (AirPods); te pregunta por el modo Apple
#
# Las opciones se combinan: ./install.sh --blueferry --airpods
#
# Cada paquete está aquí porque un archivo concreto lo usa; el comentario dice
# cuál. Si quitas algo de la config, quita su paquete; si agregas, agrégalo.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
BACKUP="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
BLUEFERRY_SRC="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/blueferry"
# El commit de BlueFerry que se instaló desde aquí la última vez, y el drop-in
# de bluetooth.service que trae su paquete.
BLUEFERRY_BUILT="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/blueferry.built"
BLUEFERRY_DROPIN=/usr/lib/systemd/system/bluetooth.service.d/blueferry.conf

# Versiones mínimas: la config de Hyprland es Lua (0.56+) y la shell usa
# Quickshell.Networking y hasFullscreen de los workspaces (0.3+).
MIN_HYPRLAND="0.56"
MIN_QUICKSHELL="0.3"


# ── Paquetes ──────────────────────────────────────────────────────────

# Repos oficiales.
PACKAGES=(
    # Compositor y sesión
    hyprland                      # hypr/hyprland.lua (config Lua, 0.56+)
    xdg-desktop-portal-hyprland   # capturas y compartir pantalla en las apps
    xdg-desktop-portal-gtk        # el portal de "Settings": las apps leen modo claro/oscuro
    mate-polkit                   # hyprland.lua (autostart): Nautilus monta discos
    xdg-user-dirs                 # xdg-user-dir PICTURES (capturas en Imágenes/Capturas)

    # La shell
    quickshell                    # quickshell/ (qs)
    hyprsunset                    # brillo y luz nocturna (HyprsunsetRepository, autostart)
    grim                          # capturas (CaptureRepository)
    slurp                         # captura de zona (CaptureRepository)
    wl-clipboard                  # wl-copy (capturas) y wl-paste (cliphist)
    cliphist                      # historial del portapapeles (autostart, Spotlight › Portapapeles)
    plocate                       # Spotlight › Archivos (FileRepository)
    xdg-utils                     # xdg-open: Spotlight abre páginas y archivos (OpenerRepository)
    hyprpicker                    # selector de color (Centro de control)
    glib2                         # gsettings: modo oscuro de las apps (ColorSchemeRepository)
    gsettings-desktop-schemas     # el esquema org.gnome.desktop.interface que usa gsettings
    pciutils                      # lspci: la gráfica en "Acerca de" (SystemInfoRepository)

    # Servicios que la shell lee directo (sin comandos de por medio)
    pipewire                      # Quickshell.Services.Pipewire (volumen, micrófono)
    pipewire-pulse                # apps que hablan PulseAudio, y pavucontrol
    wireplumber                   # wpctl (teclas de volumen en keybindings.lua)
    networkmanager                # Quickshell.Networking (Wi-Fi)
    bluez                         # Quickshell.Bluetooth
    bluez-utils                   # bluetoothctl, por si quieres emparejar desde la terminal
    python-gobject                # el agente que enseña el código al emparejar (data/bluetooth/pair-agent.py)
    upower                        # batería del teclado y del mouse Bluetooth (UPowerRepository)
    polkit                        # pkexec: Ajustes › Teclado cambia las opciones de hid_apple

    # Apps de programs.lua
    nautilus                      # fileManager

    # Fuentes de Theme.qml (la de íconos, lucide, va en fonts/)
    adwaita-fonts                 # Theme.font.ui = "Adwaita Sans"
    ttf-jetbrains-mono-nerd       # Theme.font.mono / iconNerd
    fontconfig                    # fc-cache

    # Lo que abren los botones "Configuración avanzada…" y el reloj.
    # Si no están, el botón simplemente no aparece.
    nm-connection-editor          # WifiControl.settingsApp
    blueman                       # BluetoothControl.settingsApp (blueman-manager)
    pavucontrol                   # Audio.settingsApp
    gnome-calendar                # Clock.calendarApp
)

# AUR (necesita paru o yay).
AUR_PACKAGES=(
    warp-terminal                 # programs.lua: terminal
)

# Para compilar BlueFerry (--blueferry).
BLUEFERRY_BUILD=(base-devel git python)

# LibrePods (--airpods), del AUR: modos de ruido, detección de conversación y
# batería de cada AirPod. Es la versión nueva (Rust); la shell la arranca sola
# y la maneja desde su ícono de bandeja (data/airpods/LibrePodsRepository.qml).
AIRPODS_AUR=librepods-rust-git

# Modo Apple (--airpods, solo si dices que sí): tu PC se presenta ante las
# AirPods como un aparato de Apple, el "DeviceID" del perfil DID de Bluetooth.
# Los AirPods guardan algunas funciones para Apple, y LibrePods las necesita
# así ("VendorID spoofing"). NO es la MAC: tu dirección Bluetooth no cambia.
BT_CONF=/etc/bluetooth/main.conf
APPLE_DEVICE_ID="bluetooth:004C:0000:0000"
APPLE_MARK="# dotfiles: modo Apple para los AirPods (./install.sh --airpods)"


# ── Utilidades ────────────────────────────────────────────────────────

say()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m ✗\033[0m %s\n' "$*" >&2; exit 1; }

# Pregunta de sí o no; si solo das Enter, es que no. Sin terminal (lo corre
# otro script) también es que no: nada de sistema se cambia sin preguntarte.
ask() {
    local answer=""
    [[ -t 0 ]] || return 1
    read -r -p "$(printf '\033[1;35m ?\033[0m %s [s/N] ' "$*")" answer || true
    [[ "$answer" =~ ^[sSyY] ]]
}

# Instalar de los repos. La PRIMERA vez en cada corrida va con -Syu: instalar
# contra una base de paquetes vieja es lo que dio los 404 al compilar
# BlueFerry, y en Arch no se actualiza "a medias".
SYNCED=false
pacman_install() {
    if $SYNCED; then
        sudo pacman -S --needed "$@"
    else
        sudo pacman -Syu --needed "$@"
        SYNCED=true
    fi
}

# Qué paquetes faltan. `pacman -T` revisa dependencias, no nombres exactos:
# si tienes hyprland-git o quickshell-git (que "proveen" hyprland y
# quickshell), cuentan como instalados y no se pisan.
missing_packages() {
    pacman -T "$@" 2>/dev/null || true
}

aur_helper() {
    command -v paru 2>/dev/null || command -v yay 2>/dev/null || true
}

# ¿Ya existe el índice de plocate? Se le pregunta a plocate y no al archivo:
# /var/lib/plocate es de root y del grupo plocate, y tu usuario puede no
# tener permiso ni para ver si está. plocate sí (es setgid plocate). Toda
# ruta contiene "/", así que con un índice cualquiera encuentra algo.
plocate_ready() {
    command -v plocate >/dev/null && plocate -l 1 -- / >/dev/null 2>&1
}

# "0.56.2" >= "0.56"
version_ge() {
    [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" == "$2" ]]
}

backup() {
    local path="$1"
    local rel="${path#"$HOME"/}"
    mkdir -p "$BACKUP/$(dirname "$rel")"
    mv "$path" "$BACKUP/$rel"
    warn "respaldo: $path → $BACKUP/$rel"
}

# Enlace simbólico idempotente: si ya apunta ahí, no hace nada; si hay algo
# que no es nuestro enlace, lo respalda antes de reemplazarlo.
link() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"

    if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
        ok "$dest"
        return
    fi

    if [[ -L "$dest" ]]; then
        rm "$dest"
    elif [[ -e "$dest" ]]; then
        backup "$dest"
    fi

    ln -s "$src" "$dest"
    ok "$dest → $src"
}

# Los perfiles de máquina (hypr/hosts/<hostname>.lua) no van en git. Si antes
# ~/.config/hypr apuntaba a OTRA copia de los dotfiles, se traen de allá para
# no perderlos al cambiar de carpeta.
migrate_hosts() {
    local current="$CONFIG/hypr"
    [[ -L "$current" ]] || return 0

    local old
    old="$(readlink -f "$current")"
    [[ "$old" == "$(readlink -f "$DOTFILES/hypr")" ]] && return 0
    [[ -d "$old/hosts" ]] || return 0

    local f name
    for f in "$old"/hosts/*.lua; do
        [[ -e "$f" ]] || continue
        name="$(basename "$f")"
        [[ "$name" == "init.lua" || "$name" == "default.lua" ]] && continue
        if [[ ! -e "$DOTFILES/hypr/hosts/$name" ]]; then
            cp "$f" "$DOTFILES/hypr/hosts/$name"
            ok "perfil de máquina copiado: hosts/$name (desde $old)"
        fi
    done
}


# ── Pasos ─────────────────────────────────────────────────────────────

install_packages() {
    say "Paquetes de los repos oficiales"
    local missing
    mapfile -t missing < <(missing_packages "${PACKAGES[@]}")
    if (( ${#missing[@]} )); then
        say "Faltan: ${missing[*]}"
        pacman_install "${missing[@]}"
    else
        ok "todos instalados"
    fi

    say "Paquetes del AUR"
    mapfile -t missing < <(missing_packages "${AUR_PACKAGES[@]}")
    if (( ${#missing[@]} == 0 )); then
        ok "todos instalados"
    else
        local helper
        helper="$(aur_helper)"
        if [[ -n "$helper" ]]; then
            "$helper" -S --needed "${missing[@]}"
        else
            warn "faltan ${missing[*]} y no hay paru ni yay. Instálalos a mano,"
            warn "o cambia la terminal en hypr/theme/config/programs.lua."
        fi
    fi
}

install_links() {
    say "Enlaces"
    migrate_hosts
    link "$DOTFILES/hypr"       "$CONFIG/hypr"
    link "$DOTFILES/quickshell" "$CONFIG/quickshell"

    # El .desktop de Ajustes: así Spotlight lo encuentra (y el menú de apps).
    local desktop
    for desktop in "$DOTFILES"/applications/*.desktop; do
        link "$desktop" "$DATA/applications/$(basename "$desktop")"
    done

    say "Fuente de íconos (Lucide)"
    local font
    for font in "$DOTFILES"/fonts/*.ttf; do
        link "$font" "$DATA/fonts/dotfiles/$(basename "$font")"
    done
    if command -v fc-cache >/dev/null; then
        fc-cache -f "$DATA/fonts" >/dev/null && ok "caché de fuentes al día"
    else
        warn "no hay fc-cache (fontconfig): la fuente se verá al reiniciar sesión"
    fi
}

enable_services() {
    say "Servicios"

    # Las carpetas de usuario (Imágenes, Descargas…) en el idioma del sistema.
    command -v xdg-user-dirs-update >/dev/null && xdg-user-dirs-update && ok "carpetas de usuario"

    local unit
    # plocate-updatedb.timer: regenera una vez al día el índice de archivos
    # que usa Spotlight. Sin él, plocate busca en una base que nunca cambia.
    for unit in NetworkManager.service bluetooth.service plocate-updatedb.timer; do
        if systemctl is-enabled --quiet "$unit" 2>/dev/null; then
            ok "$unit"
        else
            sudo systemctl enable --now "$unit" && ok "$unit habilitado"
        fi
    done

    # El timer corre una vez al día: la primera vez no hay índice todavía y
    # Spotlight no encontraría nada hasta mañana. Se arma ya (tarda unos
    # segundos; recorre el disco una sola vez).
    if command -v updatedb >/dev/null && ! plocate_ready; then
        sudo updatedb && ok "índice de plocate creado"
    fi

    # PipeWire viene habilitado de serie en Arch (presets de usuario).
    for unit in pipewire.socket pipewire-pulse.socket wireplumber.service; do
        if systemctl --user is-enabled --quiet "$unit" 2>/dev/null; then
            ok "$unit (usuario)"
        else
            systemctl --user enable --now "$unit" && ok "$unit (usuario) habilitado"
        fi
    done
}

install_blueferry() {
    say "BlueFerry (iPhone)"

    # Instalado por otro camino (no es el paquete blueferry-backend que arma
    # su build.sh): ese no se toca.
    if command -v blueferry >/dev/null && ! pacman -Q blueferry-backend >/dev/null 2>&1; then
        ok "instalado por fuera de este script: no se toca"
        return
    fi

    command -v git >/dev/null || pacman_install git
    if [[ -d "$BLUEFERRY_SRC/.git" ]]; then
        git -C "$BLUEFERRY_SRC" pull --ff-only
    else
        mkdir -p "$(dirname "$BLUEFERRY_SRC")"
        git clone https://github.com/erikwb/blueferry.git "$BLUEFERRY_SRC"
    fi

    # Se compila si el código cambió desde la última instalación hecha desde
    # aquí. Sin esa marca (lo instalaste antes de que existiera) también: así
    # un BlueFerry viejo se pone al día.
    local head have
    head="$(git -C "$BLUEFERRY_SRC" rev-parse HEAD)"
    have="$(pacman -Q blueferry-backend 2>/dev/null | cut -d' ' -f2 || true)"
    if [[ -n "$have" ]] && command -v blueferry-quickshell >/dev/null \
            && [[ "$(cat "$BLUEFERRY_BUILT" 2>/dev/null)" == "$head" ]]; then
        ok "al día ($have, ${head:0:7})"
        return
    fi
    [[ -n "$have" ]] && say "actualizando BlueFerry $have al código de ${head:0:7}"

    # Las herramientas de compilación, y el sistema al día: makepkg instala
    # las dependencias de BlueFerry con pacman.
    local missing
    mapfile -t missing < <(missing_packages "${BLUEFERRY_BUILD[@]}")
    if (( ${#missing[@]} )) || ! $SYNCED; then
        pacman_install "${missing[@]}"
    fi

    # build.sh arma los cuatro paquetes de Arch (backend, gtk, qt, quickshell)
    # y los instala con pacman. El backend trae el servicio de usuario (arranca
    # solo al iniciar sesión) y el drop-in de bluetooth.service (-E -P hfp);
    # al instalarse reinicia Bluetooth para que lo tome.
    (cd "$BLUEFERRY_SRC" && ./build.sh -si)
    printf '%s\n' "$head" > "$BLUEFERRY_BUILT"

    ok "BlueFerry instalado. Empareja el iPhone desde su app: blueferry-quickshell"
}

install_airpods() {
    say "LibrePods (AirPods)"
    local helper
    helper="$(aur_helper)"

    # `librepods` a secas: cualquier versión que lo provea cuenta.
    if [[ -z "$(missing_packages librepods)" ]] || command -v librepods >/dev/null; then
        ok "ya instalado"
    elif [[ -z "$helper" ]]; then
        warn "LibrePods está en el AUR ($AIRPODS_AUR) y no hay paru ni yay: instálalo a mano."
    else
        "$helper" -S --needed "$AIRPODS_AUR"
        ok "LibrePods instalado. Reinicia la shell (pkill qs; qs -d): ella lo arranca."
    fi

    apple_mode
}

# ¿Ya está el DeviceID de Apple, activo (sin comentar)?
apple_mode_on() {
    grep -qiE '^[[:space:]]*DeviceID[[:space:]]*=[[:space:]]*bluetooth:004c:' "$BT_CONF" 2>/dev/null
}

# Reescribe main.conf: quita cualquier DeviceID activo (y la marca de aquí) y,
# con "on", pone el de Apple justo debajo de [General]. Lo demás queda igual.
# Antes guarda una copia en tu carpeta de respaldo.
write_apple_mode() {
    local mode="$1" tmp
    tmp="$(mktemp)"

    if [[ -f "$BT_CONF" ]]; then
        mkdir -p "$BACKUP"
        cp "$BT_CONF" "$BACKUP/bluetooth-main.conf"
        ok "copia de $BT_CONF en $BACKUP/bluetooth-main.conf"
    fi

    awk -v mode="$mode" -v mark="$APPLE_MARK" -v line="DeviceID = $APPLE_DEVICE_ID" '
        /^[[:space:]]*DeviceID[[:space:]]*=/ { next }
        index($0, "# dotfiles: modo Apple") == 1 { next }
        { print }
        mode == "on" && !done && /^[[:space:]]*\[General\][[:space:]]*$/ {
            print mark; print line; done = 1
        }
        END {
            if (mode == "on" && !done) { print "[General]"; print mark; print line }
        }
    ' "$( [[ -f "$BT_CONF" ]] && echo "$BT_CONF" || echo /dev/null )" > "$tmp"

    sudo install -Dm644 "$tmp" "$BT_CONF"
    rm -f "$tmp"

    # Sin reiniciar, bluetoothd sigue con la identidad vieja.
    sudo systemctl restart bluetooth
}

apple_mode() {
    say "Modo Apple (funciones completas de los AirPods)"

    if apple_mode_on; then
        ok "activado: tu PC se presenta como un aparato de Apple"
        if ask "¿Quitarlo y volver a la identidad normal? (reinicia Bluetooth)"; then
            write_apple_mode off
            ok "quitado. Vuelve a conectar tus AirPods para que lo noten."
        fi
        return
    fi

    cat <<EOF
   Los AirPods guardan algunas funciones para los aparatos de Apple. Para
   tenerlas, tu PC puede presentarse como uno: se agrega a $BT_CONF
       DeviceID = $APPLE_DEVICE_ID
   Tu MAC no cambia. LibrePods lo marca "bajo tu propio riesgo": la PC se
   presenta así ante TODOS tus aparatos Bluetooth, también el iPhone.
   Se reinicia Bluetooth: lo conectado se desconecta unos segundos.
   Se quita igual: vuelve a correr ./install.sh --airpods.
EOF

    if ask "¿Presentar tu PC como un aparato de Apple?"; then
        write_apple_mode on
        ok "activado. Si tus AirPods no lo notan, olvídalos en Ajustes › Bluetooth y vuelve a emparejarlos."
    else
        ok "se queda con la identidad normal"
    fi
}

check() {
    say "Revisión"
    local problems=0

    local missing
    mapfile -t missing < <(missing_packages "${PACKAGES[@]}")
    if (( ${#missing[@]} )); then
        warn "paquetes que faltan: ${missing[*]}"; problems=$((problems + 1))
    else
        ok "paquetes de los repos"
    fi

    mapfile -t missing < <(missing_packages "${AUR_PACKAGES[@]}")
    if (( ${#missing[@]} )); then
        warn "paquetes del AUR que faltan: ${missing[*]}"; problems=$((problems + 1))
    else
        ok "paquetes del AUR"
    fi

    local version
    version="$(Hyprland --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true)"
    if [[ -n "$version" ]] && version_ge "$version" "$MIN_HYPRLAND"; then
        ok "Hyprland $version"
    else
        warn "Hyprland ${version:-no encontrado}: la config Lua necesita $MIN_HYPRLAND o más"
        problems=$((problems + 1))
    fi

    # qs escribe su versión por stderr.
    version="$(qs --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true)"
    if [[ -n "$version" ]] && version_ge "$version" "$MIN_QUICKSHELL"; then
        ok "Quickshell $version"
    else
        warn "Quickshell ${version:-no encontrado}: la shell necesita $MIN_QUICKSHELL o más"
        problems=$((problems + 1))
    fi

    local target name
    for target in hypr quickshell; do
        if [[ "$(readlink -f "$CONFIG/$target" 2>/dev/null)" == "$(readlink -f "$DOTFILES/$target")" ]]; then
            ok "$CONFIG/$target → dotfiles"
        else
            warn "$CONFIG/$target no apunta a $DOTFILES/$target"; problems=$((problems + 1))
        fi
    done

    # `fc-list -q` y no `fc-list | grep -q`: con pipefail, grep cierra el tubo
    # al encontrarla, fc-list muere por SIGPIPE y la revisión decía que no está.
    if fc-list -q lucide 2>/dev/null; then
        ok "fuente lucide"
    else
        warn "la fuente lucide no está registrada (./install.sh --links)"; problems=$((problems + 1))
    fi

    name="$(cut -d. -f1 /etc/hostname 2>/dev/null | tr -d '[:space:]' || true)"
    if [[ -n "$name" && -f "$DOTFILES/hypr/hosts/$name.lua" ]]; then
        ok "perfil de máquina: hosts/$name.lua"
    else
        warn "sin hosts/${name:-<hostname>}.lua: se usa hosts/default.lua (un monitor, latam)"
        warn "  para personalizarlo: cp hypr/hosts/default.lua hypr/hosts/$name.lua"
    fi

    # El agente de emparejamiento corre con el python3 del sistema: es ese
    # el que tiene que encontrar gi (python-gobject).
    if python3 -c 'import gi; gi.require_version("Gio", "2.0")' 2>/dev/null; then
        ok "python-gobject (emparejar teclados con código)"
    else
        warn "python3 no encuentra python-gobject: no podrás emparejar teclados desde Ajustes"
        problems=$((problems + 1))
    fi

    if plocate_ready; then
        ok "índice de plocate (Spotlight › Archivos)"
    else
        warn "sin índice de plocate: Spotlight no encuentra archivos (sudo updatedb)"
        problems=$((problems + 1))
    fi

    if command -v blueferry >/dev/null; then
        ok "BlueFerry $(pacman -Q blueferry-backend 2>/dev/null | cut -d' ' -f2 || true)"
        command -v blueferry-quickshell-bridge >/dev/null \
            || warn "falta blueferry-quickshell-bridge: no podrás responder desde la isla"
        # Los BlueFerry viejos arrancan bluetoothd solo con -E, sin -P hfp, y
        # con eso las llamadas no llegan (blueferry/install.sh se detiene).
        if [[ -f "$BLUEFERRY_DROPIN" ]] && ! grep -q -- '-P hfp' "$BLUEFERRY_DROPIN"; then
            warn "tu BlueFerry es de antes de -P hfp: actualízalo (./install.sh --blueferry)"
            problems=$((problems + 1))
        fi
    else
        warn "BlueFerry no está: sin notificaciones del iPhone (./install.sh --blueferry)"
    fi

    if command -v librepods >/dev/null; then
        ok "LibrePods (AirPods)"
        if apple_mode_on; then
            ok "modo Apple activado (funciones completas de los AirPods)"
        else
            ok "modo Apple desactivado (para activarlo: ./install.sh --airpods)"
        fi
    else
        warn "LibrePods no está: tus AirPods suenan, pero sin control de ruido (./install.sh --airpods)"
    fi

    if (( problems == 0 )); then
        ok "todo en orden"
    else
        warn "$problems cosa(s) por revisar"
    fi
}

usage() {
    sed -n '3,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}


# ── Principal ─────────────────────────────────────────────────────────

main() {
    local only_links=false only_check=false with_blueferry=false with_calls=false
    local with_airpods=false arg
    for arg in "$@"; do
        case "$arg" in
            --links)     only_links=true ;;
            --check)     only_check=true ;;
            --blueferry) with_blueferry=true ;;
            --calls)     with_calls=true ;;
            --airpods)   with_airpods=true ;;
            -h|--help)   usage; exit 0 ;;
            *)           usage; die "opción desconocida: $arg" ;;
        esac
    done

    command -v pacman >/dev/null || die "esto es para Arch Linux (no encuentro pacman)"
    [[ $EUID -eq 0 ]] && die "córrelo como tu usuario, no con sudo: pide la contraseña cuando la necesita"

    if $only_check; then
        check
        return
    fi

    if $only_links; then
        install_links
        return
    fi

    install_packages
    install_links
    enable_services
    $with_blueferry && install_blueferry
    $with_calls && "$DOTFILES/blueferry/install.sh"
    $with_airpods && install_airpods

    echo
    check
    echo
    say "Listo. Si Hyprland ya estaba abierto:"
    say "  hyprctl reload        (atajos, reglas, hosts)"
    say "  pkill qs; qs -d       (la shell)"
    say "  hyprsunset --identity &   (solo la primera vez; luego lo arranca el autostart)"
}

main "$@"
