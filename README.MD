# dotfiles

Mi escritorio en Arch Linux: **Hyprland** (config Lua) con una shell propia en
**Quickshell** al estilo macOS — barra de menús, isla dinámica, Spotlight,
Centro de control y Ajustes —, con el iPhone conectado por **BlueFerry**, las
AirPods manejados con **LibrePods** y los teclados (el Apple, el Dell, el ROG…)
integrados a la shell.

Los mismos archivos sirven en la PC de casa y en la del trabajo; lo que cambia
entre máquinas vive en `hypr/hosts/`.

## Instalar

```bash
git clone https://github.com/Z0KRI/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
./install.sh                 # paquetes + enlaces + servicios
./install.sh --blueferry     # opcional: iPhone (notificaciones y mensajes); también lo actualiza
./install.sh --calls         # opcional: contestar llamadas del iPhone (oFono)
./install.sh --airpods       # opcional: AirPods (control de ruido y batería)
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
    ├── init.lua                 carga hosts/<hostname>.lua o, si no existe, default.lua;
    │                            después, hosts/displays.lua y hosts/keyboard.lua si existen
    ├── displays.lua             lo escribe Ajustes › Pantallas (por máquina, no se sube)
    ├── keyboard.lua             lo escribe Ajustes › Teclado (distribución por teclado; no se sube)
    └── default.lua              respaldo y plantilla (un monitor, teclado latam)

quickshell/                      capas, como en S.I.R.A:
├── core/                        componentes (atoms → templates), tema y utilidades
├── data/                        lo único que habla con el sistema (Pipewire, BlueZ, hyprctl…)
├── domain/                      las reglas (qué se muestra, cuándo, cómo se guarda)
└── modules/                     las features: bar, island, launcher, settings, capture, keys

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
| `SUPER + Espacio` | Spotlight: apps, archivos y web |
| `SUPER + SHIFT + V` | Spotlight en el portapapeles (pega en la ventana donde estabas) |
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
| `F1` / `F2` (teclado Apple) | brillo, con su nivel en la isla |
| `F4` (Launchpad) | Spotlight en Aplicaciones; la lupa de los de 2021, la búsqueda general |
| `F7` / `F8` / `F9` | anterior / reproducir-pausar / siguiente |
| `F10` / `F11` / `F12` | silencio / bajar / subir volumen |

Las teclas F son las del teclado Apple: su driver convierte la fila de arriba
en brillo, música y volumen. En el Dell, el ROG o cualquier otro, F1–F12
siguen siendo F1–F12; si traen teclas de música o volumen propias (en muchos,
con Fn), también sirven. Con "Usar F1, F2… como estándar" (Ajustes › Teclado)
en el Apple salen con `fn`.

Con Spotlight abierto:

| Atajo | Qué hace |
|---|---|
| `SUPER + 1 / 2 / 3` (o `CTRL`) | Aplicaciones / Archivos / Portapapeles (otra vez: búsqueda general) |
| `Tab` / `SHIFT + Tab` | modo siguiente / anterior |
| `Enter` | abrir (si la app ya tiene ventana, va a ella) · pegar · buscar |
| `CTRL + Enter` | abrir otra ventana · mostrar en carpeta · solo copiar |
| `SHIFT + Supr` | borrar la entrada del portapapeles |
| `Retroceso` (campo vacío) | volver a la búsqueda general |
| `> comando` | ejecutar un comando |
| `Esc` | borrar lo escrito; con el campo vacío, cerrar |

## La shell por IPC

Lo que hacen los atajos también se puede llamar a mano:

```bash
qs ipc call launcher open|close|toggle
qs ipc call launcher mode clipboard # apps, files, clipboard o all
qs ipc call settings open|close|toggle
qs ipc call settings go wifi        # bluetooth, airpods, iphone, sound, about…
qs ipc call capture region|screen|color
qs ipc call brightness up|down      # un paso de 16, como macOS
qs ipc call media playPause|next|previous
```

Las preferencias de la shell (`preferences.json`, `usage.json`) se guardan en
`~/.local/state/quickshell/by-shell/<id>/`, no en el repo.

## iPhone (BlueFerry)

`./install.sh --blueferry` clona BlueFerry, arma sus paquetes de Arch y los
instala. Después se empareja desde su app (`blueferry-quickshell`). Su servicio
arranca solo al iniciar sesión, y su paquete ya deja `bluetoothd` con
`-E -P hfp`: no hace falta tocar `bluetooth.service`. Volver a correr
`--blueferry` lo actualiza si su código cambió (los BlueFerry viejos dejan
`bluetoothd` solo con `-E`, y así las llamadas no llegan).

- **Notificaciones y SMS/iMessage**: llegan a la isla; los mensajes se pueden
  responder desde ahí. Los de WhatsApp no: llegan por ANCS, que no tiene dónde
  mandar texto.
- **Llamadas** (experimental): `./install.sh --calls` instala oFono del AUR,
  le da permiso a tu usuario, enlaza `blueferry/wireplumber/51-bluez-ofono.conf`
  y las enciende. `blueferry/install.sh --status` revisa cómo va.
  Con eso las llamadas normales suenan en la isla con **Contestar** y
  **Rechazar** (con el nombre que puso el iPhone, aunque BlueFerry solo sepa el
  número) y, contestadas, se quedan como en el iPhone: plegada, el teléfono
  verde y el tiempo; desplegada, audio, silenciar, más y colgar. La shell las
  sigue con `gdbus monitor` y `busctl` (vienen con glib2 y systemd). Las de
  WhatsApp y otras apps se contestan con los botones del iPhone, en el iPhone.

## AirPods (LibrePods)

`./install.sh --airpods` instala LibrePods del AUR (`librepods-rust-git`). No
hace falta abrirlo ni ponerlo en el autostart: la shell lo arranca minimizado
al iniciar, porque necesita ser ella quien hospede la bandeja (LibrePods se
cierra si al arrancar no hay bandeja).

Con tus AirPods conectados:

- **El sonido se pasa a ellos** al conectarlos, como en macOS (una vez por
  conexión: si luego eliges otra salida, se respeta). Esto no necesita
  LibrePods.
- **Centro de control › Bluetooth** (o **Sonido**): tocarlos abre su página,
  como en macOS: batería de cada AirPod y del estuche, control de ruido
  (Desactivado, Transparencia, Adaptativo, Cancelación) y detección de
  conversación.
- **Ajustes › AirPods** aparece arriba de todo mientras están conectados; en
  Ajustes › Bluetooth, la (i) junto a ellos lleva ahí.
- **Isla dinámica**: al conectarlos enseña su nombre y su batería, y al cambiar
  de modo (también apretando el tallo) el modo nuevo. Se ensancha lo que pida
  el texto. Se apaga en Ajustes › Isla.

La shell no habla con los AirPods directamente: lee y "pulsa" el menú de la
bandeja de LibrePods (`quickshell/data/airpods/`). Lo que la shell no cubre
(renombrarlos, volumen personalizado, habilitar el modo Desactivado, controles
del tallo) está en la ventana de LibrePods: Ajustes › AirPods › Abrir
LibrePods….

**Modo Apple.** `--airpods` te pregunta (por defecto, no) si tu PC se presenta
como un aparato de Apple: agrega `DeviceID = bluetooth:004C:0000:0000` a
`/etc/bluetooth/main.conf`, guarda una copia en `~/.dotfiles_backup/<fecha>/` y
reinicia Bluetooth. No cambia tu MAC. Los AirPods le dan entonces lo que solo le
dan a Apple; en Linux, hoy, eso es sobre todo estar conectados a la vez al
iPhone y a la PC. LibrePods lo marca "bajo tu propio riesgo" porque la PC se
presenta así ante todos tus aparatos. Para quitarlo, vuelve a correr
`./install.sh --airpods`. Su estado sale en Ajustes › AirPods.

Sin LibrePods los AirPods funcionan como audífonos normales, solo sin esas
opciones. Si usas la versión vieja (Qt, `librepods-git`), cambia
`--start-minimized` por `--hide` en `LibrePodsRepository.qml`.

## Teclados

La shell funciona con cualquier teclado: el Apple, uno Dell, un ROG Strix Scope,
el de una laptop. Lo propio de Apple solo aparece cuando hay uno conectado.

**Emparejar** (Bluetooth): **Ajustes › Bluetooth › Dispositivos cercanos ›
Conectar**. Si el teclado pide un código, sale una hoja con el código en
grande: se escribe **en ese teclado** y luego Retorno/Enter. No se ve nada
mientras lo escribes (el teclado todavía no está conectado), y eso es normal.
Quickshell no trae un "agente de emparejamiento" (la pieza que enseña ese
código), así que la shell trae el suyo: `quickshell/data/bluetooth/pair-agent.py`,
en Python con `python-gobject`. Vive lo que dura un emparejamiento y se cierra
solo. Le sirve igual a un teléfono (compara el número) o a una bocina vieja
(te pide su PIN, casi siempre 0000).

**Ajustes › Teclado**:

- **Tus teclados**: los que estén conectados, de cualquier marca, cada uno una
  vez (aunque el sistema lo vea en varias partes: letras, multimedia…). Las
  cámaras, los audífonos y los mouses gamer que se anuncian como "teclado" no
  salen.
- **Distribución por teclado**: cada uno la suya (Latinoamérica, España,
  Inglés, Inglés internacional con AltGr para ñ y acentos); sin elegir, la de
  `hosts/<equipo>.lua`. Se aplica al momento y se guarda en
  `hypr/hosts/keyboard.lua`, que es de cada máquina: el Dell de la oficina y el
  ROG de casa no se pisan. En un teclado Apple, España e Inglés usan la
  variante `mac`.
- **Teclado Apple** (solo con uno conectado):
  - **F1–F12 como teclas estándar** y las teclas **° y <** de los teclados
    ISO: son opciones del driver `hid_apple` del kernel. Piden tu contraseña
    (pkexec) y se escriben en `/sys/module/hid_apple/parameters` y en
    `/etc/modprobe.d/hid_apple.conf`, sin tocar otras opciones de esa línea.
  - **Intercambiar ⌘ y ⌥**: no va en el driver sino en xkb, solo para el
    teclado Apple (`altwin:swap_lalt_lwin` en `hypr/hosts/keyboard.lua`): la ⌥
    izquierda hace de SUPER y la ⌘ de Alt, y la ⌥ derecha sigue siendo AltGr.
    No pide contraseña y se aplica solo a cualquier teclado Apple que
    conectes, también por cable.
  - **La fila de arriba**: qué hace cada tecla (ver Atajos).

  El driver de Apple solo maneja aparatos con el número de fabricante de
  Apple: el Dell y el ROG ni pasan por él. Algunos genéricos sí (los de chip
  SONiX, un Keychron en modo Mac…), porque se presentan como Apple; la shell
  los reconoce con la misma lista del kernel y no los trata como Apple. Por
  eso ⌘ y ⌥ van por xkb (en el driver se cambiarían también en ellos), y si
  hay uno conectado, la opción de ° y < lo advierte.

La lista de teclados se pone al día sola al conectar o desconectar uno, por
cable o Bluetooth: el kernel avisa y la shell lo escucha con `udevadm monitor`.

**Isla**: al conectar un teclado Bluetooth (de cualquier marca), su nombre y su
batería; al bajar de 20 % y de 10 %, el aviso en rojo. La batería la lee UPower
(los teclados la mandan por HID, no por BlueZ). Se apaga en Ajustes › Isla.

En el arranque dual: el menú de GRUB no ve teclados Bluetooth (para elegir
Windows, conéctalo con cable), y si lo emparejas en Windows y en Linux en la
misma PC, solo funciona en el último donde lo emparejaste: cada sistema guarda
su propia llave.

## Pendiente

- **Bloquear pantalla** (menú de Arch) usa `loginctl lock-session`, que necesita
  un bloqueador escuchando (hypridle + hyprlock). Aún no está configurado.
- **No suspender** (Centro de control) inhibe la inactividad, pero sin un
  demonio de inactividad todavía no hay nada que inhibir.
- **Spotlight**: calculadora, secciones de Ajustes como resultados y
  miniaturas de las imágenes del portapapeles.
- **Liquid Glass**: Spotlight ya lo tiene (átomo `GlassSurface` + `hl.layer_rule`
  con desenfoque). Falta llevarlo a la barra, la isla y el Centro de control:
  cada capa necesita su propia regla por namespace. La refracción de Apple
  (el vidrio que deforma lo de atrás en los bordes) no está: necesita un shader.
