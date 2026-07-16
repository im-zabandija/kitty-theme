# kitty-theme

Switcher interactivo de **colores** y **tipografía** de kitty, con
hot-reload sin reiniciar la terminal. Selección con flechas/fuzzy (`fzf`)
y panel de preview en vivo para cada opción: ~169 temas de color incluidos,
cualquier fuente monoespaciada que ya tengas instalada, y un **creador de
temas propios** que te arma una paleta entera a partir de un solo color.

## Instalar

Un solo comando, no hace falta clonar nada a mano:

```bash
curl -fsSL https://raw.githubusercontent.com/im-zabandija/kitty-theme/main/install.sh | bash
```

Requiere `kitty`, [`fzf`](https://github.com/junegunn/fzf), `fontconfig`
(`fc-list`) y `awk` (los tres últimos vienen preinstalados en casi todas
las distros) (`apt install fzf fontconfig`, `brew install fzf`, `pacman -S
fzf fontconfig`, etc.). El instalador es idempotente: se puede correr de
nuevo sin romper nada.

Qué hace:
- Copia el comando `theme` a `~/.local/bin/theme`.
- Copia los temas de color a `~/.config/kitty/themes/`.
- Agrega `include theme-active.conf` e `include font-active.conf` al final
  de tu `kitty.conf` (solo si no están ya) — **nunca pisa tu configuración
  existente**.
- Crea `~/.config/kitty/theme-active.conf` con un tema por defecto
  (Dracula) si todavía no existe.
- Crea `~/.config/kitty/font-active.conf` vacío si todavía no existe (kitty
  sigue usando la fuente que ya tenías hasta que elijas una con `theme`).

## Usar

```bash
theme
```

El menú principal ofrece cuatro opciones:
- **🎨 Color · Fijo** — cualquier tema de la colección, con preview en vivo.
- **🎨 Color · Dinámico** — si además tenés [DMS](https://github.com/AvengeMedia/DankMaterialShell)
  instalado, sigue el wallpaper.
- **🖌️ Color · Propio** — creá tu propio tema: elegís base (oscuro/claro) y
  un color semilla (de una lista con swatches de color, o tipeás cualquier
  `#rrggbb`), y se genera una **paleta entera** (fondo, texto, cursor,
  selección y los 16 colores ANSI) derivada de ese color. Se aplica en vivo
  mientras la armás; podés pedir **otra variación**, cambiar la semilla o el
  modo, y recién ahí guardarla con nombre. Queda como un tema más de tu
  colección.
- **🔤 Fuente** — cualquier familia monoespaciada instalada en tu sistema
  (detectada vía `fontconfig`, no hace falta que esté en el repo). El panel
  muestra las variantes disponibles (Regular/Bold/Italic/Bold Italic) y si
  trae glifos Nerd Font.

Al confirmar, kitty recarga en caliente (`SIGUSR1`) — no hace falta
reabrir la ventana.

## Cómo funciona

Ni el color ni la fuente viven directamente en `kitty.conf`. Sus últimas
líneas son `include theme-active.conf` e `include font-active.conf`,
archivos que el comando `theme` reescribe:
- `theme-active.conf`: `include dank-theme.conf` (dinámico) o
  `include themes/<NOMBRE>.conf` (fijo).
- `font-active.conf`: `font_family`/`bold_font`/`italic_font`/
  `bold_italic_font` apuntando a la familia elegida.

El creador de temas propios deriva toda la paleta en **HSL**: cada color
ANSI conserva su matiz semántico (rojo = error, verde = ok…) pero tintado
hacia el matiz de tu semilla para que todo combine. La generación es
determinística (misma semilla → misma paleta) y "Otra variación" aplica un
jitter controlado. El tema guardado es un `.conf` normal de kitty.

Después manda `pkill -SIGUSR1 -x kitty` para recargar en caliente.
Idempotente y no destructivo: solo toca esos dos archivos.

## Licencia

MIT — ver [LICENSE](LICENSE).
