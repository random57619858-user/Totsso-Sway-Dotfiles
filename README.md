<div align="center">

# Totsso-Sway-Dotfiles

**Entorno Wayland dinámico y minimalista para Artix Linux y Alpine Linux**  
*Integración total con Sway, Waybar, Kitty, Rofi, Hyprlock y Mako mediante paletas Material You generadas con Matugen.*


<br />

|  (Artix Linux) | (Alpine Linux) |
| :---: | :---: |
| "https://github.com/user-attachments/assets/e332f2b3-1e4e-418e-8497-22d0b9902a50" /> | <img width="1366" height="768" alt="image" src="https://github.com/user-attachments/assets/1692a668-1c93-45d7-98ac-540cedb3c3cd" />
 /> |

</div>

---

##  Novedades

* **Soporte de Alpine Linux:** Soporte para Artix Linux y Alpine Linux (con OpenRC, `seatd` y `greetd` + `tuigreet`).
* **Herramientas integradas:** Incluye reproductor flotante *Rofi NowPlaying* (`SUPER + M`), modo No Molestar (DND), tooltips detallados en Waybar y tematización automática con **Matugen**.

---

##  Instalación y Requisitos

Clona el repositorio y ejecuta el instalador automatizado:

```bash
git clone https://github.com
cd Totsso-Sway-Dotfiles
chmod +x install.sh
./install.sh
```

> **Nota:** El script detecta automáticamente tu distribución (**Artix** o **Alpine**), realiza respaldos en `backup/` y registra el proceso en `install.log`.

---

## Componentes y Atajos

| Categoría | Herramientas principales |
| :--- | :--- |
| **Core Wayland** | `sway` · `waybar` · `swaybg` |
| **Interfaz y Temas** | `rofi-wayland` · `matugen` · `mako` |
| **Terminal y Audio** | `kitty` · `fish` · `cava` · `pipewire` |
| **Utilidades** | `hyprlock` · `cliphist` · `grim` · `slurp` |

<details>
<summary><b>  Ver atajos de teclado principales</b></summary>
<br />

| Combinación | Acción | Combinación | Acción |
| :--- | :--- | :--- | :--- |
| `SUPER + Q` | Terminal (**Kitty**) | `SUPER + V` | Ventana flotante |
| `SUPER + D` | Lanzador (**Rofi**) | `SUPER + C` | Cerrar ventana |
| `SUPER + M` | Rofi NowPlaying | `SUPER + L` | Bloquear (**Hyprlock**) |
| `SUPER + W` | Selector de fondo | `SUPER + Print` | Captura de pantalla |
| `SUPER + A` | Historial portapapeles | `SUPER + 1..0` | Espacios de trabajo |

</details>

<details>
<summary><b> Detalles técnicos sobre la gestión de servicios</b></summary>
<br />

* **Artix Linux:** Gestión mediante servicios de usuario de OpenRC o `start-services.sh` en el inicio de Sway.
* **Alpine Linux:** Servicios de sistema (`dbus`, `seatd`, `greetd`, etc.) habilitados en OpenRC, con cadena de audio inicializada por sesión.

</details>

---

<div align="center">
  <i>No es el mejor dotfile del mundo, pero espero que te guste :)</i>
</div>
