<div align="center">

# Totsso-Sway-Dotfiles

Un dotfile dinámico que se integra con Sway, Waybar, Kitty, Rofi, Hyprlock, Mako y Rofi NowPlaying mediante Matugen. Con soporte nativo para **Artix** y **Alpine Linux**.

<img width="1366" height="768" alt="Totsso Sway Preview" src="https://github.com/user-attachments/assets/e332f2b3-1e4e-418e-8497-22d0b9902a50" />

<img width="1366" height="768" alt="image" src="https://github.com/user-attachments/assets/1f0b3d6d-5d1c-48ab-bfab-4892c2b8a15c" />

</div>

---

## Novedades

**Soporte de Artix y Alpine** — Diseñado para funcionar tanto en entornos GNU (glibc) como en sistemas minimalistas basados en Musl y BusyBox.

**Rofi NowPlaying** — Reproductor flotante con carátula, título, artista y controles. Se abre con `SUPER + M`.

**Modo No Molestar** — Módulo interactivo en Waybar que silencia Mako con un clic, cambiando icono y color según el estado.

**Tooltips enriquecidos** — CPU, RAM, MPRIS y Reloj muestran información detallada al pasar el ratón, incluyendo un calendario completo.

**Integración Matugen** — Todas las interfaces heredan la paleta Material You generada desde el fondo de pantalla.

---

## Instalación

### Requisitos

- Instalación limpia de **Artix** o **Alpine**.

- `git`, `unzip`, `curl`, `wget` instalados (en el caso de Alpine, también se requiere `bash`).

- Conexión a internet.


### Clonar y ejecutar

```bash
git clone [https://github.com/random57619858-user/Totsso-Sway-Dotfiles](https://github.com/random57619858-user/Totsso-Sway-Dotfiles)
cd Totsso-Sway-Dotfiles
chmod +x install.sh
./install.sh
```

---

## Componentes

### Entorno base

- **Sway** — Compositor Wayland (con soporte para Xwayland y `libinput`).

- **Waybar** — Barra de estado con tareas y DND.

- **Rofi** — Lanzador, selector de fondos y reproductor.

- **Kitty** — Terminal.

- **Cava** — Visualizador de audio.


### Tematización y fondos

- **Swaybg** — Gestión de fondos estáticos.

- **Matugen** — Paletas Material You vía `cargo`.

- **Mako** — Notificaciones dinámicas.

- **Rofi NowPlaying** — Reproductor flotante con `playerctl`.


### Utilidades

- **Hyprlock** — Pantalla de bloqueo.

- **Cliphist** — Historial del portapapeles.

- **Grim + Slurp** — Capturas de pantalla optimizadas para tuberías en POSIX/Bash.

- **PipeWire + WirePlumber** — Servidor de audio.

- **CUPS** — Soporte de impresoras (opcional).

- **Flatpak** — Aplicaciones aisladas (opcional).


> En Artix, el audio se gestiona con los servicios de usuario de OpenRC. En Alpine, el script configura automáticamente los servicios con OpenRC, los permisos de los grupos (`seat`, `input`, `video`), `sudo`/`doas`, el gestor de sesiones `greetd` con `tuigreet` y el wrapper universal `sway-run`.

---

## Atajos principales

- `SUPER + Q` — Terminal (Kitty)

- `SUPER + D` — Lanzador (Rofi)

- `SUPER + M` — Rofi NowPlaying

- `SUPER + W` — Selector de fondo (compatible con GNU `find` y BusyBox)

- `SUPER + C` — Cerrar ventana activa

- `SUPER + V` — Alternar flotante

- `SUPER + A` — Historial de portapapeles

- `SUPER + L` — Bloquear pantalla

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
│   ├── artix.sh
│   ├── alpine.sh
│   ├── sway-run.sh
│   └── start-services.sh
├── sway/
├── waybar/
├── kitty/
├── rofi/
├── hypr/
├── matugen/
├── mako/
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
