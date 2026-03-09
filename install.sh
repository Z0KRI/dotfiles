# TODO: Hacer el archivo de instalacion en este se debera de instalar todo lo necesario

yay -S hypremoji

# Para hyprpm
# sudo pacman -S cmake cpio pkgconf git gcc base-devel hyprland-headers
#Despues
# hyprpm update

# Botones estilo mac
# hyprpm enable hyprbars

# Instalacion de mpvpaper
# 1.- 
# git clone https://github.com/GhostNaN/mpvpaper
# cd mpvpaper

# 2.-
# meson setup build --prefix=/usr/local

# 3.-
# ninja -C build
# sudo ninja -C build install

# Execution permissions for all scripts
chmod +x ~/.config/hypr/mac-style/scripts/*.sh

# REcarga de la terminal
# source ~/.bashrc