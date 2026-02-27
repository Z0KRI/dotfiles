#!/bin/bash

# 1. Obtener el ID del workspace actual
CURRENT_WS=$(hyprctl activeworkspace -j | jq '.id')

# 2. Empezar a buscar desde el siguiente número
NEXT_WS=$((CURRENT_WS + 1))

# 3. Obtener la lista de todos los workspaces ocupados actualmente
OCCUPIED_WS=$(hyprctl workspaces -j | jq '.[].id')

# 4. Bucle para encontrar el primer ID superior al actual que esté libre
while echo "$OCCUPIED_WS" | grep -q -w "$NEXT_WS"; do
    ((NEXT_WS++))
done

# 5. Mover la ventana al workspace encontrado y cambiar el foco
hyprctl dispatch movetoworkspace "$NEXT_WS"

# 6. Pequeña pausa para que la animación de Hyprland respire
sleep 0.1

# 7. Activa el modo fullscreen (0 = total)
hyprctl dispatch fullscreen 0