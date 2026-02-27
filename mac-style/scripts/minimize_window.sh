#!/usr/bin/env bash

# Archivo para guardar el estado del workspace original
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/hypr_last_normal_ws"

# Obtener el nombre del workspace de la ventana activa
win_ws=$(hyprctl -j activewindow | jq -r '.workspace.name // empty')

# Si la ventana NO está en el "special workspace", la "minimizamos"
if [[ "$win_ws" != "special" ]]; then
    curr_id=$(hyprctl -j activeworkspace | jq -r '.id')
    [[ -n "$curr_id" ]] && printf '%s\n' "$curr_id" > "$STATE_FILE"
    hyprctl dispatch movetoworkspacesilent special
    exit 0
fi

# Si ya está en el special, la devolvemos al workspace original
target_ws="1"
if [[ -f "$STATE_FILE" ]]; then
    read -r target_ws < "$STATE_FILE"
fi

hyprctl dispatch movetoworkspace "$target_ws"