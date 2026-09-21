<!-- Spotlight -->
sudo pacman -S rofi

<!-- Waybar -->
sudo pacman -S waybar

<!-- cliphist -->
sudo pacman -S cliphist
sudo pacman -S wl-clipboard
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &

yay -S rofi-blocks-git
sudo pacman -S plocate
sudo systemctl enable --now plocate-updatedb.timer
sudo updatedb