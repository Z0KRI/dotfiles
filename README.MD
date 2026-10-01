<!-- Waybar -->
sudo pacman -S waybar

<!-- cliphist -->
sudo pacman -S cliphist
sudo pacman -S wl-clipboard
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &

<!-- Notificaciones  -->
sudo pacman -Syu
git clone https://github.com/erikwb/blueferry.git

sudo pacman -S plocate
sudo systemctl enable --now plocate-updatedb.timer
sudo updatedb