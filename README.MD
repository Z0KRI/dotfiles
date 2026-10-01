<!-- Waybar -->
sudo pacman -S waybar

<!-- cliphist -->
sudo pacman -S cliphist
sudo pacman -S wl-clipboard
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &

sudo pacman -S plocate
sudo systemctl enable --now plocate-updatedb.timer
sudo updatedb