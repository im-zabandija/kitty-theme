#!/usr/bin/env bash
# install.sh — instala el switcher de temas y tipografías de kitty (comando `theme`).
# Uso remoto (recomendado, un solo comando):
#   curl -fsSL https://raw.githubusercontent.com/im-zabandija/kitty-theme/main/install.sh | bash
# Uso local (repo ya clonado):
#   ./install.sh
#
# Es idempotente y no destructivo: solo agrega archivos y, si hace falta,
# líneas `include theme-active.conf` / `include font-active.conf` al final
# de tu kitty.conf.
set -euo pipefail

REPO_URL="https://github.com/im-zabandija/kitty-theme.git"
KITTY_DIR="${THEME_KITTY_DIR:-$HOME/.config/kitty}"
BIN_DIR="$HOME/.local/bin"
DEFAULT_THEME="Dracula"

info()  { printf '  %s\n' "$1"; }
ok()    { printf '✅ %s\n' "$1"; }
warn()  { printf '⚠️  %s\n' "$1" >&2; }
die()   { printf '✗ %s\n' "$1" >&2; exit 1; }

command -v kitty   >/dev/null 2>&1 || warn "no encuentro 'kitty' en PATH — instalá el terminal primero."
command -v fzf     >/dev/null 2>&1 || warn "falta 'fzf' (lo necesita el comando 'theme' para elegir). Instalalo con tu gestor de paquetes."
command -v fc-list >/dev/null 2>&1 || warn "falta 'fc-list' (paquete fontconfig, lo necesita el picker de fuentes). Instalalo con tu gestor de paquetes."
command -v awk     >/dev/null 2>&1 || warn "falta 'awk' (lo necesita el generador de temas propios). Instalalo con tu gestor de paquetes."

# ─────────────────────── ubicar el código fuente ──────────────────────────
# Si el script corre desde un checkout local (con themes/ al lado), lo usa
# directo. Si no (p. ej. vía curl | bash), clona el repo a un temporal.
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" && pwd)"
CLEANUP_DIR=""
cleanup() { [ -n "$CLEANUP_DIR" ] && rm -rf "$CLEANUP_DIR"; return 0; }
trap cleanup EXIT

if [ ! -f "$SRC_DIR/theme" ] || [ ! -d "$SRC_DIR/themes" ]; then
    command -v git >/dev/null 2>&1 || die "falta 'git' para descargar el repo."
    CLEANUP_DIR="$(mktemp -d)"
    info "Descargando kitty-theme..."
    git clone --depth 1 -q "$REPO_URL" "$CLEANUP_DIR" || die "no se pudo clonar $REPO_URL"
    SRC_DIR="$CLEANUP_DIR"
fi

# ────────────────────────────── instalar ───────────────────────────────────
mkdir -p "$KITTY_DIR/themes" "$BIN_DIR"

# -ef: si ~/.local/bin/theme ya ES este archivo (p. ej. symlink de desarrollo
# al checkout), cp fallaría con "same file" y set -e abortaría la instalación.
if [ ! "$SRC_DIR/theme" -ef "$BIN_DIR/theme" ]; then
    cp "$SRC_DIR/theme" "$BIN_DIR/theme"
fi
chmod +x "$BIN_DIR/theme"
ok "comando 'theme' -> $BIN_DIR/theme"

cp "$SRC_DIR"/themes/*.conf "$KITTY_DIR/themes/"
ok "$(ls "$SRC_DIR"/themes/*.conf | wc -l | tr -d ' ') temas -> $KITTY_DIR/themes/"

# theme-active.conf: no lo piso si ya existe (respeta tu selección previa).
if [ ! -f "$KITTY_DIR/theme-active.conf" ]; then
    printf 'include themes/%s.conf\n' "$DEFAULT_THEME" > "$KITTY_DIR/theme-active.conf"
    ok "tema activo inicial: $DEFAULT_THEME"
fi

# dank-theme.conf: fallback para que el modo "Dinámico" del picker no rompa
# kitty si no tenés DMS instalado. Si más adelante instalás DMS, él mismo
# sobreescribe este archivo con la paleta del wallpaper.
if [ ! -f "$KITTY_DIR/dank-theme.conf" ]; then
    cp "$KITTY_DIR/themes/$DEFAULT_THEME.conf" "$KITTY_DIR/dank-theme.conf"
fi

# font-active.conf: no lo piso si ya existe. Vacío por defecto -> kitty usa
# la fuente que ya tenías configurada hasta que elijas una con `theme`.
if [ ! -f "$KITTY_DIR/font-active.conf" ]; then
    printf '# Tipografía activa de kitty — la gestiona el comando `theme`.\n# Vacío: kitty usa la fuente definida más arriba en kitty.conf (o su default).\n' > "$KITTY_DIR/font-active.conf"
    ok "fuente activa: sin cambios (la de tu kitty.conf)"
fi

# cursor-active.conf: no lo piso si ya existe. Por defecto replica el trail
# "ninja" que ya tenías hardcodeado en kitty.conf (200ms, decay 0.1/0.4,
# threshold 2, forma block, parpadeo sí) — instalar no cambia nada visible.
if [ ! -f "$KITTY_DIR/cursor-active.conf" ]; then
    {
        printf 'cursor_shape                 block\n'
        printf 'cursor_blink_interval         1\n'
        printf 'cursor_trail                 200\n'
        printf 'cursor_trail_decay           0.1 0.4\n'
        printf 'cursor_trail_start_threshold 2\n'
        printf 'cursor_trail_color           none\n'
    } > "$KITTY_DIR/cursor-active.conf"
    ok "cursor activo inicial: trail medio, bloque, parpadeo sí"
fi

# window-active.conf: no lo piso si ya existe. Por defecto replica la
# transparencia/blur/padding que ya tenías hardcodeados en kitty.conf.
if [ ! -f "$KITTY_DIR/window-active.conf" ]; then
    {
        printf 'background_opacity   0.75\n'
        printf 'background_blur      32\n'
        printf 'window_padding_width 4\n'
    } > "$KITTY_DIR/window-active.conf"
    ok "ventana activa inicial: opacidad 0.75, blur 32, padding 4"
fi

# tabs-active.conf: no lo piso si ya existe. Por defecto replica el estilo
# que ya trae dank-tabs.conf (powerline curvo, arriba).
if [ ! -f "$KITTY_DIR/tabs-active.conf" ]; then
    {
        printf 'tab_bar_style        powerline\n'
        printf 'tab_powerline_style  slanted\n'
        printf 'tab_bar_edge         top\n'
    } > "$KITTY_DIR/tabs-active.conf"
    ok "tabs activas inicial: powerline curvo, arriba"
fi

# kitty.conf: agrega los includes solo si no están ya.
KITTY_CONF="$KITTY_DIR/kitty.conf"
touch "$KITTY_CONF"
if ! grep -q '^include theme-active.conf' "$KITTY_CONF"; then
    printf '\n# Esquema de color: lo controla el comando `theme`\ninclude theme-active.conf\n' >> "$KITTY_CONF"
    ok "agregado 'include theme-active.conf' a tu kitty.conf"
else
    info "kitty.conf ya tenía el include de color, no se tocó."
fi
if ! grep -q '^include font-active.conf' "$KITTY_CONF"; then
    printf '\n# Tipografía: la controla el comando `theme`\ninclude font-active.conf\n' >> "$KITTY_CONF"
    ok "agregado 'include font-active.conf' a tu kitty.conf"
else
    info "kitty.conf ya tenía el include de fuente, no se tocó."
fi

if ! grep -q '^include cursor-active.conf' "$KITTY_CONF"; then
    printf '\n# Cursor (forma/parpadeo/trail ninja): lo controla el comando `theme`\ninclude cursor-active.conf\n' >> "$KITTY_CONF"
    ok "agregado 'include cursor-active.conf' a tu kitty.conf"
else
    info "kitty.conf ya tenía el include de cursor, no se tocó."
fi

if ! grep -q '^include window-active.conf' "$KITTY_CONF"; then
    printf '\n# Ventana (transparencia/blur/padding): lo controla el comando `theme`\ninclude window-active.conf\n' >> "$KITTY_CONF"
    ok "agregado 'include window-active.conf' a tu kitty.conf"
else
    info "kitty.conf ya tenía el include de ventana, no se tocó."
fi

if ! grep -q '^include tabs-active.conf' "$KITTY_CONF"; then
    printf '\n# Tabs (estilo/posición): lo controla el comando `theme`\ninclude tabs-active.conf\n' >> "$KITTY_CONF"
    ok "agregado 'include tabs-active.conf' a tu kitty.conf"
else
    info "kitty.conf ya tenía el include de tabs, no se tocó."
fi

case ":$PATH:" in
    *":$BIN_DIR:"*) : ;;
    *) warn "$BIN_DIR no está en tu PATH. Agregá esto a tu ~/.bashrc o ~/.zshrc:
     export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

echo
ok "Listo. Abrí una terminal nueva de kitty y corré: theme"
