#!/usr/bin/env bash

# Archivo para guardar el estado del workspace original
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/hypr_last_normal_ws"

# Buscamos si hay ALGUNA ventana guardada en el workspace especial
# (Usamos startswith porque en Hyprland puede llamarse "special" o "special:special")
hidden_window=$(hyprctl -j clients | jq -r '.[] | select(.workspace.name | startswith("special")) | .address' | head -n 1)

if [[ -n "$hidden_window" ]]; then
    # ==========================================
    # CASO 1: Hay una ventana minimizada. La recuperamos.
    # ==========================================
    target_ws="1"
    if [[ -f "$STATE_FILE" ]]; then
        read -r target_ws < "$STATE_FILE"
    fi

    # La movemos de vuelta usando su dirección (address) y la enfocamos
    hyprctl dispatch movetoworkspace "$target_ws,address:$hidden_window"
    hyprctl dispatch focuswindow "address:$hidden_window"
    
    # Limpiamos el archivo para el siguiente uso
    rm -f "$STATE_FILE"
    exit 0
fi

# ==========================================
# CASO 2: No hay nada oculto. Minimizamos la ventana activa.
# ==========================================
curr_ws=$(hyprctl -j activeworkspace | jq -r '.id')

# Guardamos de dónde viene
[[ -n "$curr_ws" ]] && printf '%s\n' "$curr_ws" > "$STATE_FILE"

# La enviamos al exilio de forma silenciosa
hyprctl dispatch movetoworkspacesilent special