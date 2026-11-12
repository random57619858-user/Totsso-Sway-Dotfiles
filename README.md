<div align="center">

# Totsso-Sway-Dotfiles (v1.0)

<img width="1366" height="768" alt="image" src="https://github.com/user-attachments/assets/13cd11ec-a994-4829-a249-aba24fe100b7" />


Una configuración de **Sway** exclusiva para **Ubuntu**. 

*Olvíddate de los temas estáticos.* Este dotfile convierte tu escritorio en un entorno **dinámico**. Extrae la paleta de colores de tu fondo de pantalla y la aplica en tiempo real a los bordes de Sway, Waybar, Kitty, Rofi e Hyprlock usando **Matugen**.

</div>

> **Nota sobre el porteo:** Este repositorio es la evolución del proyecto original para Hyprland/Arch. Se ha adaptado todo el ecosistema para funcionar de forma nativa en **Sway sobre Ubuntu**. Se eliminaron las dependencias de Arch y se implementó la compilación local para herramientas que no están en los repositorios oficiales. **No está garantizado que funcione en otras distribuciones**, incluso si son derivadas de Ubuntu.



## Instalación

### Requisitos previos
- Una instalación limpia de **Ubuntu**.
- `git` y `sudo` instalados.
- Conexión a internet.

### Clonar el repositorio

Ejecuta esto en tu terminal:

```bash
git clone https://github.com/random57619858-user/Totsso-Sway-Dotfiles
cd Totsso-Sway-Dotfiles
```

### Ejecutar el instalador

El script se encargará de instalar los paquetes oficiales vía `apt`, compilar las herramientas faltantes (como `matugen` con `cargo`), desplegar las configuraciones y crear los respaldos necesarios.

```bash
chmod +x install.sh
./install.sh
```

---

## ¿Qué instala?

### 🖥️ Entorno Base (Wayland)
| Paquete | Función |
| :--- | :--- |
| **Sway** | Compositor de ventanas. |
| **Waybar** | Barra de estado. |
| **Rofi** | Lanzador de aplicaciones y selector de wallpapers. |
| **Kitty** | Terminal. |
| **Cava** | Visualizador de audio. |

### Fondos y Tematización
| Paquete | Función |
| :--- | :--- |
| **Swaybg** | Gestión de fondos estáticos. |
| **Matugen** | Generación de paletas Material You (vía `cargo`). |

### Utilidades del Sistema
| Paquete | Función |
| :--- | :--- |
| **GDM3** | Display Manager (gestor de inicio). |
| **Hyprlock** | Pantalla de bloqueo. |
| **Cliphist** | Historial del portapapeles. |
| **Grim + Slurp** | Capturas de pantalla. |
| **PipeWire + WirePlumber** | Servidor de audio. |
| **CUPS** | Soporte de impresoras (opcional). |
| **Flatpak** | Soporte para aplicaciones sandbox (opcional). |

---

## Keybindings (Atajos Principales)

| Atajo | Acción |
| :--- | :--- |
| `SUPER + Q` | Abrir terminal (Kitty) |
| `SUPER + D` | Lanzador de aplicaciones (Rofi) |
| `SUPER + W` | **Selector de Wallpaper** |
| `SUPER + C` | Cerrar ventana activa |
| `SUPER + V` | Alternar ventana flotante |
| `SUPER + A` | Historial de portapapeles |
| `SUPER + L` | Bloquear pantalla (Hyprlock) |
| `SUPER + 1-0` | Cambiar de Workspace |
| `SUPER + SHIFT + 1-0` | Enviar ventana a Workspace |
| `SUPER + SHIFT + E` | Menú de energía (Wlogout) |
| `SUPER + Print` | Captura de pantalla |

---

## Respaldos

Antes de tocar cualquier archivo en `~/.config/`, te preguntará si deseas respaldar tu configuración actual en una carpeta `backup/` dentro del repositorio.

---

<div align="center">
  <i>No es el mejor dotfile del mundo, pero ahora es dinámico, estable en Ubuntu y espero que te guste :)</i>
</div>
