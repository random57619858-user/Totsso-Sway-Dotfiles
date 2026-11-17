<div align="center">

# Totsso-Sway-Dotfiles

Un dotfile dinámico para **Artix Linux** y **Alpine Linux** que se integra con Sway, Waybar, Kitty, Rofi, Hyprlock, Mako y Rofi NowPlaying mediante Matugen.

<img width="1366" height="768" alt="Totsso Sway Preview" src="https://github.com/user-attachments/assets/e332f2b3-1e4e-418e-8497-22d0b9902a50" />

<img width="1366" height="768" alt="image" src="https://github.com/user-attachments/assets/054f0b76-f56d-44df-b5ce-fe80f89b2f22" />

</div>

---

## Novedades

**Soporte oficial para Alpine Linux** — Detección automática de distribución, migración a repositorios `edge`, gestión nativa con OpenRC, `seatd` y `greetd` + `tuigreet`.

**Rofi NowPlaying** — Reproductor flotante con carátula, título, artista y controles. Se abre con `SUPER + M`.

**Modo No Molestar** — Módulo interactivo en Waybar que silencia Mako con un clic, cambiando icono y color según el estado.

**Tooltips enriquecidos** — CPU, RAM, MPRIS y Reloj muestran información detallada al pasar el ratón, incluyendo un calendario completo.

**Integración Matugen** — Todas las interfaces heredan la paleta Material You generada desde el fondo de pantalla.

---

## Instalación

### Requisitos

- Instalación limpia de **Artix Linux** o **Alpine Linux**.
- git, unzip, curl, git wget y gestor de privilegios (`sudo` en Artix / `doas` en Alpine, posiblemente en este tengas que instalas bash).
- Conexión a internet.

### Clonar y ejecutar

```bash
git clone https://github.com/random57619858-user/Totsso-Sway-Dotfiles
cd Totsso-Sway-Dotfiles
chmod +x install.sh
./install.sh
```

> El instalador detecta automáticamente si estás en **Artix** o **Alpine** y ejecuta el módulo correspondiente.

---

## Componentes

### Entorno base

- **Sway** — Compositor Wayland.
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
- **Grim + Slurp** — Capturas de pantalla.
- **PipeWire + WirePlumber** — Servidor de audio con compatibilidad PulseAudio (`pipewire-pulse`).
- **CUPS + Avahi** — Soporte de impresoras con descubrimiento automático `.local` (opcional).
- **Flatpak** — Aplicaciones aisladas desde Flathub (opcional).

> **Gestión de servicios:** En Artix (OpenRC) el audio se inicia mediante servicios de usuario; en otros inits o en Alpine Linux se emplea `start-services.sh` en el autostart de Sway para levantar la cadena de PipeWire (`pipewire`, `pipewire-pulse` y `wireplumber`), mientras que `dbus`, `seatd`, `greetd`, `cupsd` y `avahi-daemon` corren como servicios de sistema en OpenRC.

---

## Atajos principales

- `SUPER + Q` — Terminal (Kitty)
- `SUPER + D` — Lanzador (Rofi)
- `SUPER + M` — Rofi NowPlaying
- `SUPER + W` — Selector de fondo
- `SUPER + C` — Cerrar ventana activa
- `SUPER + V` — Alternar flotante
- `SUPER + A` — Historial de portapapeles
- `SUPER + L` — Bloquear pantalla
- `SUPER + 1-0` — Cambiar workspace
- `SUPER + SHIFT + 1-0` — Mover ventana a workspace
- `SUPER + Print` — Captura de pantalla

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
