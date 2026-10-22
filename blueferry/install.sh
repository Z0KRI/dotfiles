#!/usr/bin/env bash
#
# Deja el sistema listo para CONTESTAR LLAMADAS del iPhone desde esta
# computadora (BlueFerry + oFono). Es opcional y experimental: para las
# notificaciones y para responder mensajes no hace falta nada de esto.
#
#   ./install.sh            instala oFono si falta, copia/enlaza lo suyo y enciende las llamadas
#   ./install.sh --status   solo diagnostica, no cambia nada
#
# Requisito: BlueFerry ya instalado (../install.sh --blueferry lo compila).
#
# Lo que NO hace, a propósito: tocar bluetooth.service. El paquete de Arch de
# BlueFerry ya trae un drop-in que arranca bluetoothd con "-E -P hfp":
#   -E      las interfaces experimentales que necesita ANCS (notificaciones)
#   -P hfp  apaga el manos libres propio de BlueZ 5.87+, que si no le gana
#           el canal a oFono
# Un drop-in nuestro con solo "-P hfp" le quitaría el -E y se perderían las
# notificaciones. Aquí solo se comprueba que el proceso corra con las dos.

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
me="${SUDO_USER:-$USER}"

dbus_policy="/etc/dbus-1/system.d/ofono-local.conf"
vendor_dropin="/usr/lib/systemd/system/bluetooth.service.d/blueferry.conf"
wp_dir="${XDG_CONFIG_HOME:-$HOME/.config}/wireplumber/wireplumber.conf.d"
wp_link="$wp_dir/51-bluez-ofono.conf"

say()  { printf '\033[1;34m::\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m::\033[0m %s\n' "$1"; }
die()  { printf '\033[1;31m::\033[0m %s\n' "$1" >&2; exit 1; }

# ── diagnóstico ───────────────────────────────────────────────────
#
# Se mira el PROCESO que corre, no la unidad: un drop-in mal puesto o un
# bluetooth sin reiniciar no se notan de otra forma.
bluetoothd_flags_ok() {
    local cmd
    cmd="$(pgrep -a bluetoothd 2>/dev/null || true)"
    [[ "$cmd" == *" -E"* ]] && [[ "$cmd" =~ -P[=\ ]*hfp ]]
}

aur_helper() {
    command -v paru 2>/dev/null || command -v yay 2>/dev/null || true
}

status() {
    say "BlueFerry instalado:   $(command -v blueferry >/dev/null && echo sí || echo NO)"
    say "oFono instalado:       $(command -v ofonod >/dev/null && echo sí || echo NO)"
    say "oFono activo:          $(systemctl is-active ofono 2>/dev/null || true)"
    say "política de D-Bus:     $([[ -f "$dbus_policy" ]] && echo instalada || echo falta)"
    say "bluetoothd -E -P hfp:  $(bluetoothd_flags_ok && echo sí || echo NO)"
    say "fragmento WirePlumber: $([[ -e "$wp_link" ]] && echo enlazado || echo falta)"
    if command -v blueferry >/dev/null; then
        say "estado de llamadas:"
        blueferry calls || true
    fi
}

if [[ "${1:-}" == "--status" ]]; then
    status
    exit 0
fi

[[ $EUID -eq 0 ]] && die "córrelo como tu usuario, no con sudo: pide la contraseña cuando la necesita"

# ── requisitos ────────────────────────────────────────────────────
command -v blueferry >/dev/null || die \
    "BlueFerry no está instalado. Desde la raíz de los dotfiles: ./install.sh --blueferry"

if ! command -v ofonod >/dev/null; then
    # oFono no está en los repos oficiales de Arch: viene del AUR. El AUR trae
    # la 2.14 y BlueFerry se probó con la 2.18; si el módem no aparece, ese es
    # el primer sospechoso (ofono-git es la alternativa).
    helper="$(aur_helper)"
    [[ -n "$helper" ]] || die "oFono está en el AUR y no encontré paru ni yay. Instálalo a mano y repite."
    say "instalando oFono del AUR con $(basename "$helper")"
    "$helper" -S --needed ofono
fi

bluetoothd_flags_ok || {
    if [[ -f "$vendor_dropin" ]]; then
        warn "bluetoothd no corre con -E -P hfp, pero el drop-in de BlueFerry existe:"
        warn "    sudo systemctl daemon-reload && sudo systemctl restart bluetooth"
    else
        warn "bluetoothd no corre con -E -P hfp y no encuentro $vendor_dropin."
        warn "Ese archivo lo instala el paquete blueferry-backend: reinstálalo."
    fi
    die "arregla eso primero y vuelve a correr este script"
}

# ── 1. permiso sobre oFono ────────────────────────────────────────
#
# A /etc se COPIA, no se enlaza: si apuntara a tu home y un día el repo cambia
# de sitio, el sistema arrancaría sin la política y la llamada fallaría sin
# decir por qué.
say "instalando la política de D-Bus para el usuario $me"
sed "s/@USER@/$me/" "$here/etc/dbus-1/system.d/ofono-local.conf.in" \
    | sudo install -Dm644 /dev/stdin "$dbus_policy"

# ── 2. el fragmento de WirePlumber ────────────────────────────────
#
# Este sí va enlazado: es tu configuración y vive en tu home. Se enlaza el
# ARCHIVO y no la carpeta: BlueFerry escribe su propio fragmento en esa misma
# carpeta, y no queremos que termine dentro del repo.
say "enlazando el fragmento de WirePlumber"
mkdir -p "$wp_dir"
ln -sfn "$here/wireplumber/51-bluez-ofono.conf" "$wp_link"

# ── 3. el orden importa ───────────────────────────────────────────
#
# oFono y WirePlumber se pelean por el mismo perfil de Bluetooth al arrancar,
# y es una carrera sin resolver: si oFono sube primero, el estado se queda en
# `searching`. Así que oFono va al final, siempre.
say "recargando D-Bus"
sudo systemctl reload dbus 2>/dev/null || true

say "reiniciando wireplumber"
systemctl --user restart wireplumber 2>/dev/null \
    || warn "wireplumber no es un servicio de usuario: reinícialo tú"

say "habilitando y reiniciando ofono"
sudo systemctl enable --now ofono
sudo systemctl restart ofono

# ── 4. el interruptor de BlueFerry ────────────────────────────────
say "encendiendo las llamadas en BlueFerry"
blueferry calls enable

echo
status
echo
say "si el estado no dice 'ready', reconecta el iPhone y vuelve a mirar."
say "si se queda en 'searching': sudo systemctl restart ofono (después de wireplumber)."
