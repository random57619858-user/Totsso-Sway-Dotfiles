<div align="center">

# Totsso-Sway-Dotfiles

Un dotfile dinámico que se integra con Sway, Waybar, Kitty, Rofi, Mako y Matugen. Pensado para **Artix Linux con OpenRC**.

<img width="1366" height="768" alt="image" src="https://github.com/user-attachments/assets/40c3c0d4-49cc-4bac-ab86-b66b6fe73bdb" />


</div>

---

## Novedades

**Lanzador rediseñado** — Rofi con campo de búsqueda tipo pastilla, filas sin cebra, resaltado con `primary-container` y scrollbar fino, todo derivado de Matugen.

**Lanzador unificado** — Un solo `SUPER + D` abre Rofi con tres apartados: **apps** (drun), **wallpapers** y **clipboard**. Se cambian con las flechas izquierda/derecha o clicando los botones de arriba.

**Portapapeles visual** — El historial de `cliphist` se explora dentro del mismo lanzador con miniaturas reales de las imágenes copiadas, vista previa de una línea para texto y borrado con `Ctrl+X`. Al copiar una entrada se muestra una notificación breve para confirmarlo y las imágenes se restauran con su tipo MIME original (`image/png`).

**Selector de wallpapers** — Cada imagen de `~/Pictures` aparece con su miniatura (cacheada en `~/.cache/totsso-wallpapers`), marca `●` en la que está activa y aplica Matugen al elegirla. Las fotos enormes (8K) también generan miniatura.

**Menú de apagado con wlogout** — Cuadrícula de tarjetas redondeadas (cerrar sesión, suspender, reiniciar, apagar) tematizada con Matugen. Si `wlogout` no está instalado, cae al menú de Rofi.

**Waybar ampliada** — Grupos de hardware y sistema, taskbar de ventanas, temperatura del CPU, SSID completo de la red y controles de MPRIS con clic y scroll.

**Modo No Molestar** — Módulo interactivo en Waybar que silencia Mako con un clic, cambiando icono y color según el estado.

**Tooltips enriquecidos** — CPU, RAM, MPRIS y Reloj muestran información detallada al pasar el ratón, incluyendo un calendario completo.

**Integración Matugen** — Todas las interfaces heredan la paleta Material You generada desde el fondo de pantalla, incluidos los colores nombrados de GTK3 y GTK4/libadwaita.

---

## Instalación

### Requisitos

- Instalación limpia de **Artix Linux con OpenRC**.

- Conexión a internet.

> No necesitas instalar nada más: si falta `git`, `curl`, `wget` o `unzip`, el instalador los instala primero (requiere `sudo`).


### Clonar y ejecutar

```bash
git clone https://github.com/random57619858-user/Totsso-Sway-Dotfiles
cd Totsso-Sway-Dotfiles
./install.sh
```

> Añade `--yes` para el modo desatendido: acepta todas las confirmaciones e instala la **opción recomendada** de cada app opcional. Si no quieres ninguna de esas apps, no uses `--yes`.

> El instalador compila **`matugen`** desde el código fuente con `cargo install --locked` (no está empaquetado en los repos oficiales de Artix) y usa **trizen** como helper de AUR para las aplicaciones opcionales.

---

## Componentes

### Entorno base

- **Sway** — Compositor Wayland (con soporte para Xwayland y `libinput`).

- **Waybar** — Barra de estado con workspaces, taskbar, cava, MPRIS, hardware, red y sesión.

- **Rofi** — Lanzador unificado (apps, wallpapers, clipboard) con tarjetas redondeadas y apartados intercambiables con `←` `→`.

- **Kitty** — Terminal.

- **Fish** — Shell interactiva (opcional, se desactiva el saludo).

- **Cava** — Visualizador de audio integrado en Waybar.


### Tematización y fondos

- **Swaybg** — Gestión de fondos estáticos.

- **Matugen** — Paletas Material You (compilado desde fuente con `cargo`).

- **Mako** — Notificaciones dinámicas.


### Utilidades

- **Cliphist** — Historial del portapapeles.

- **Grim + Slurp** — Capturas de pantalla optimizadas para tuberías en POSIX/Bash.

- **PipeWire + WirePlumber** — Servidor de audio.

- **hyprlock** — Bloqueo de pantalla con la paleta del fondo.

- **wlogout** — Menú de apagado tematizado.

- **Fastfetch** — Resumen del sistema con los colores del fondo.

- **CUPS** — Soporte de impresoras (opcional).

- **Flatpak** — Repositorio Flathub configurado (opcional; las apps se instalan manualmente).


> El audio se gestiona con los servicios de usuario de OpenRC. El instalador verifica que el init sea OpenRC antes de continuar y configura los servicios de PipeWire; el arranque de Sway en `tty1` se ofrece como opción al final.

---

## Optional Apps (instalación interactiva)

Durante la instalación en **Artix**, el script te preguntará qué aplicaciones opcionales quieres instalar (todas vía **trizen** desde AUR). Puedes elegir **0) Skip** para no instalar ninguna:

- **Navegador:** `brave-bin`, `ungoogled-chromium`, `zen-browser-bin`
- **Cliente de Discord:** `serein-bin`, `legcord-bin`, `dissent-bin`
- **Música streaming:** `simpmusic-bin`, `limusic-bin`
- **Suite de ofimática:** `onlyoffice-bin`, `openoffice-bin`
- **Editor de código:** `vscodium-bin`, `lapce-git`

---

## Atajos principales

- `SUPER + Q` — Terminal (Kitty)

- `SUPER + D` — Lanzador unificado: apps / wallpapers / clipboard (`←` `→` cambia de apartado)

- `SUPER + M` — Reproducir / pausar

- `SUPER + SHIFT + X` — Menú de apagado (wlogout)


- `SUPER + C` — Cerrar ventana activa

- `SUPER + V` — Alternar flotante


- `SUPER + L` — Bloquear pantalla con `hyprlock`

- `SUPER + 1-0` — Cambiar workspace

- `SUPER + SHIFT + 1-0` — Mover ventana a workspace

- `SUPER + Print` — Captura de pantalla y copiado automático al portapapeles


---

## Estructura del repositorio

```text
Totsso-Sway-Dotfiles/
├── install.sh
├── scripts/
│   ├── common.sh
│   └── artix.sh
├── sway/
│   └── scripts/
├── waybar/
├── kitty/
├── rofi/
├── hypr/
├── matugen/
├── mako/
├── wlogout/
├── fastfetch/
└── wallpapers/
```

---

## Respaldos y logs

Antes de modificar cualquier archivo en `~/.config/`, el instalador pregunta si deseas respaldar la configuración actual en `backup/`.

Toda la actividad se registra en `install.log`. Si se produce un error, el script indica la línea exacta y sugiere revisar ese archivo para obtener más detalles.

---

<div align="center">
  <i>No es el mejor dotfile del mundo pero espero que te guste :)</i>
</div>
