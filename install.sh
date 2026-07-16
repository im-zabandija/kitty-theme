#!/usr/bin/env bash
# install.sh — instala el switcher de temas de kitty (comando `theme`).
# Uso remoto (recomendado, un solo comando):
#   curl -fsSL https://raw.githubusercontent.com/im-zabandija/kitty-theme/main/install.sh | bash
# Uso local (repo ya clonado):
#   ./install.sh
#
# Es idempotente y no destructivo: solo agrega archivos y, si hace falta,
# una línea `include theme-active.conf` al final de tu kitty.conf.
set -euo pipefail

REPO_URL="https://github.com/im-zabandija/kitty-theme.git"
KITTY_DIR="${THEME_KITTY_DIR:-$HOME/.config/kitty}"
BIN_DIR="$HOME/.local/bin"
DEFAULT_THEME="Dracula"

info()  { printf '  %s\n' "$1"; }
ok()    { printf '✅ %s\n' "$1"; }
warn()  { printf '⚠️  %s\n' "$1" >&2; }
die()   { printf '✗ %s\n' "$1" >&2; exit 1; }

command -v kitty >/dev/null 2>&1 || warn "no encuentro 'kitty' en PATH — instalá el terminal primero."
command -v fzf   >/dev/null 2>&1 || warn "falta 'fzf' (lo necesita el comando 'theme' para elegir). Instalalo con tu gestor de paquetes."

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

cp "$SRC_DIR/theme" "$BIN_DIR/theme"
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

# kitty.conf: agrega el include solo si no está ya.
KITTY_CONF="$KITTY_DIR/kitty.conf"
touch "$KITTY_CONF"
if ! grep -q '^include theme-active.conf' "$KITTY_CONF"; then
    printf '\n# Esquema de color: lo controla el comando `theme`\ninclude theme-active.conf\n' >> "$KITTY_CONF"
    ok "agregado 'include theme-active.conf' a tu kitty.conf"
else
    info "kitty.conf ya tenía el include, no se tocó."
fi

case ":$PATH:" in
    *":$BIN_DIR:"*) : ;;
    *) warn "$BIN_DIR no está en tu PATH. Agregá esto a tu ~/.bashrc o ~/.zshrc:
     export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

echo
ok "Listo. Abrí una terminal nueva de kitty y corré: theme"
