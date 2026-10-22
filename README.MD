# dotfiles

Mi escritorio en Arch Linux: **Hyprland** (config Lua) con una shell propia en
**Quickshell** al estilo macOS — barra de menús, isla dinámica, Spotlight,
Centro de control y Ajustes — y el iPhone conectado por **BlueFerry**.

Los mismos archivos sirven en la PC de casa y en la del trabajo; lo que cambia
entre máquinas vive en `hypr/hosts/`.

## Instalar

```bash
git clone https://github.com/Z0KRI/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
./install.sh                 # paquetes + enlaces + servicios
./install.sh --blueferry     # opcional: iPhone (notificaciones y mensajes)
./install.sh --calls         # opcional: contestar llamadas del iPhone (oFono)
./install.sh --check         # revisar qué falta, sin cambiar nada
```

`install.sh` usa `pacman` (y `paru`/`yay` para el AUR), pide `sudo` solo cuando
hace falta y se puede correr las veces que quieras. Lo que encuentra en
`~/.config` y no es un enlace suyo lo mueve a `~/.dotfiles_backup/<fecha>/`.

| Enlace | Apunta a |
|---|---|
| `~/.config/hypr` | `hypr/` |
| `~/.config/quickshell` | `quickshell/` |
| `~/.local/share/applications/quickshell-settings.desktop` | `applications/` |
| `~/.local/share/fonts/dotfiles/lucide.ttf` | `fonts/` |

Cada paquete de `install.sh` lleva al lado el archivo que lo usa. Si quitas algo
de la config, quita su paquete.

## Estructura

```
hypr/
├── hyprland.lua                 entrada: solo carga módulos + autostart
├── theme/config/
│   ├── programs.lua             terminal, gestor de archivos, comandos de la shell
│   ├── keybindings.lua          atajos
│   ├── look_feel.lua            bordes, sombras, animaciones
│   ├── workspace_windows_rules.lua
│   └── workspaces.lua           primario por monitor + fullscreen automático
└── hosts/
    ├── init.lua                 carga hosts/<hostname>.lua o, si no existe, default.lua
    └── default.lua              respaldo y plantilla (un monitor, teclado latam)

quickshell/                      capas, como en S.I.R.A:
├── core/                        componentes (atoms → templates), tema y utilidades
├── data/                        lo único que habla con el sistema (Pipewire, BlueZ, hyprctl…)
├── domain/                      las reglas (qué se muestra, cuándo, cómo se guarda)
└── modules/                     las features: bar, island, launcher, settings, capture

blueferry/                       llamadas del iPhone: oFono + WirePlumber (opcional)
applications/                    el .desktop de Ajustes
fonts/                           Lucide (íconos de la shell)
```

Regla de dependencias de la shell: `modules → domain → data`, y todos pueden
usar `core`. `core` no conoce a nadie.

## Una máquina nueva

`hypr/hosts/<hostname>.lua` no se sube al repo (monitores y cosas de cada
equipo). Sin él se carga `default.lua`. Para tener el tuyo:

```bash
cp hypr/hosts/default.lua "hypr/hosts/$(cut -d. -f1 /etc/hostname).lua"
hyprctl monitors        # nombres para hl.monitor y ws.primario
```

## Atajos

| Atajo | Qué hace |
|---|---|
| `SUPER + Espacio` | Spotlight |
| `SUPER + ,` | Ajustes |
| `SUPER + Enter` / `SUPER + E` | terminal / archivos |
| `SUPER + Q` | cerrar ventana (si el workspace queda vacío, vuelve al 1) |
| `CTRL + SUPER + F` | pantalla completa en un workspace propio (otra vez: la regresa) |
| `SUPER + V` | flotar / desflotar |
| `CTRL + ←/→` | workspace anterior / siguiente |
| `SUPER + ALT + 1…0` | mandar la ventana al workspace 1…10 |
| `SUPER + S` / `SUPER + ALT + S` | scratchpad: ver / mandar ventana |
| `SUPER + SHIFT + 3` | captura del monitor (Imágenes/Capturas + portapapeles) |
| `SUPER + SHIFT + S` | captura de zona |
| `SUPER + flechas` / `+ SHIFT` | mover el foco / intercambiar ventanas |
| `SUPER + SHIFT + Q` | salir de Hyprland |

## La shell por IPC

Lo que hacen los atajos también se puede llamar a mano:

```bash
qs ipc call launcher open|close|toggle
qs ipc call settings open|close|toggle
qs ipc call settings go wifi        # bluetooth, iphone, sound, displays, about…
qs ipc call capture region|screen|color
```

Las preferencias de la shell (`preferences.json`, `usage.json`) se guardan en
`~/.local/state/quickshell/by-shell/<id>/`, no en el repo.

## iPhone (BlueFerry)

`./install.sh --blueferry` clona BlueFerry, arma sus paquetes de Arch y los
instala. Después se empareja desde su app (`blueferry-quickshell`). Su servicio
arranca solo al iniciar sesión, y su paquete ya deja `bluetoothd` con
`-E -P hfp`: no hace falta tocar `bluetooth.service`.

- **Notificaciones y SMS/iMessage**: llegan a la isla; los mensajes se pueden
  responder desde ahí. Los de WhatsApp no: llegan por ANCS, que no tiene dónde
  mandar texto.
- **Llamadas** (experimental): `./install.sh --calls` instala oFono del AUR,
  le da permiso a tu usuario, enlaza `blueferry/wireplumber/51-bluez-ofono.conf`
  y las enciende. `blueferry/install.sh --status` revisa cómo va.

## Pendiente

- **Bloquear pantalla** (menú de Arch) usa `loginctl lock-session`, que necesita
  un bloqueador escuchando (hypridle + hyprlock). Aún no está configurado.
- **No suspender** (Centro de control) inhibe la inactividad, pero sin un
  demonio de inactividad todavía no hay nada que inhibir.
- **Spotlight: modo Archivos** con `plocate` (`plocate-updatedb.timer`).
- El portapapeles ya se guarda con `cliphist`; falta el modo Portapapeles en
  Spotlight.
