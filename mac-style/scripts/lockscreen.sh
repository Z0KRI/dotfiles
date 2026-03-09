#!/bin/bash

# 1. Comprobar si pasaste un argumento (el video)
VIDEO_PATH=$1

if [ -z "$VIDEO_PATH" ]; then
    echo "Uso: ./lock-video.sh /ruta/al/video.mov"
    exit 1
fi

# 2. Lanzar mpvpaper en segundo plano con la capa overlay
mpvpaper -vs -o "no-audio --loop" --layer overlay all "$VIDEO_PATH" &

# Guardamos el ID del proceso (PID) de mpvpaper que acabamos de lanzar
MPV_PID=$!

# 3. Pequeña espera para que el video cargue antes del bloqueo
sleep 0.6

# 4. Ejecutar hyprlock (el script se detiene aquí hasta que desbloquees)
hyprlock

# 5. Al desbloquear, matamos específicamente el proceso que lanzamos
kill $MPV_PID