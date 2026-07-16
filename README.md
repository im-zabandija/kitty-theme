# kitty-theme

Switcher interactivo del esquema de colores de **kitty**, con hot-reload sin
reiniciar la terminal. Selección con flechas/fuzzy (`fzf`) y panel de
preview en vivo (paleta de 16 colores + mock-up de terminal) para cada uno
de los ~169 temas incluidos.

## Instalar

Un solo comando, no hace falta clonar nada a mano:

```bash
curl -fsSL https://raw.githubusercontent.com/im-zabandija/kitty-theme/main/install.sh | bash
```

Requiere `kitty` y [`fzf`](https://github.com/junegunn/fzf) instalados
(`apt install fzf`, `brew install fzf`, `pacman -S fzf`, etc.). El
instalador es idempotente: se puede correr de nuevo sin romper nada.

Qué hace:
- Copia el comando `theme` a `~/.local/bin/theme`.
- Copia los temas a `~/.config/kitty/themes/`.
- Agrega `include theme-active.conf` al final de tu `kitty.conf` (solo si
  no está ya) — **nunca pisa tu configuración existente**.
- Crea `~/.config/kitty/theme-active.conf` con un tema por defecto
  (Dracula) si todavía no existe.

## Usar

```bash
theme
```

Elegís **Fijo** (cualquier tema de la colección, con preview en vivo) o
**Dinámico** (si además tenés [DMS](https://github.com/AvengeMedia/DankMaterialShell)
instalado, sigue el wallpaper). Al confirmar, kitty recarga los colores al
instante — no hace falta reabrir la ventana.

## Cómo funciona

El color de kitty no vive en `kitty.conf`; su última línea es
`include theme-active.conf`, un archivo de una sola línea que el comando
`theme` reescribe (`include dank-theme.conf` o `include themes/<NOMBRE>.conf`)
y después manda `pkill -SIGUSR1 -x kitty` para recargar en caliente.
Idempotente y no destructivo: solo toca esa línea.

## Licencia

MIT — ver [LICENSE](LICENSE).
