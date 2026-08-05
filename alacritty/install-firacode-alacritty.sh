#!/usr/bin/env bash
#
# install-firacode-alacritty.sh
# Installs FiraCode Nerd Font and points Alacritty at it.
#
# Usage:
#   ./install-firacode-alacritty.sh            # install font + configure Alacritty
#   ./install-firacode-alacritty.sh --font-only
#   ./install-firacode-alacritty.sh --size 14
#
set -euo pipefail

FONT_NAME="FiraCode"
FONT_SIZE="12.0"
FONT_ONLY=0
RELEASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT_NAME}.zip"

# ---------- args ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --font-only) FONT_ONLY=1; shift ;;
    --size)      FONT_SIZE="${2:?--size needs a value}"; shift 2 ;;
    -h|--help)   sed -n '3,10p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

for cmd in curl unzip; do
  command -v "$cmd" >/dev/null || die "'$cmd' is required but not installed."
done

# ---------- 1. install the font ----------
case "$(uname -s)" in
  Darwin) FONT_DIR="$HOME/Library/Fonts" ;;
  Linux)  FONT_DIR="$HOME/.local/share/fonts" ;;
  *)      die "Unsupported OS: $(uname -s)" ;;
esac

if fc-list 2>/dev/null | grep -qi "firacode nerd font" ||
   ls "$FONT_DIR" 2>/dev/null | grep -qi "firacode.*nerd"; then
  info "FiraCode Nerd Font already present, skipping download."
else
  info "Downloading FiraCode Nerd Font..."
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  curl -fL --progress-bar -o "$TMP/$FONT_NAME.zip" "$RELEASE_URL" \
    || die "Download failed. Check your connection or the release URL."

  info "Installing to $FONT_DIR"
  mkdir -p "$FONT_DIR/$FONT_NAME"
  unzip -qo "$TMP/$FONT_NAME.zip" -d "$FONT_DIR/$FONT_NAME" -x "*.txt" "*.md" "LICENSE*"

  if command -v fc-cache >/dev/null; then
    info "Rebuilding font cache..."
    fc-cache -f "$FONT_DIR" >/dev/null
  fi
fi

# Resolve the exact family name fontconfig registered (varies between releases).
FAMILY="FiraCode Nerd Font"
if command -v fc-list >/dev/null; then
  DETECTED="$(fc-list : family | tr ',' '\n' | grep -i "firacode nerd font" | grep -vi "mono\|propo" | head -1 || true)"
  [[ -n "$DETECTED" ]] && FAMILY="$DETECTED"
fi
info "Using font family: \"$FAMILY\""

[[ $FONT_ONLY -eq 1 ]] && { info "Done (font only)."; exit 0; }

# ---------- 2. configure Alacritty ----------
command -v alacritty >/dev/null || warn "alacritty not found in PATH; writing config anyway."

CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty"
mkdir -p "$CONF_DIR"

# Alacritty >= 0.13 uses TOML; older uses YAML.
USE_TOML=1
if command -v alacritty >/dev/null; then
  VER="$(alacritty --version | awk '{print $2}')"
  MAJOR="${VER%%.*}"; REST="${VER#*.}"; MINOR="${REST%%.*}"
  if [[ "$MAJOR" -eq 0 && "$MINOR" -lt 13 ]]; then USE_TOML=0; fi
  info "Detected Alacritty $VER"
fi

if [[ $USE_TOML -eq 1 ]]; then
  CONF="$CONF_DIR/alacritty.toml"
else
  CONF="$CONF_DIR/alacritty.yml"
fi

if [[ -f "$CONF" ]]; then
  BACKUP="$CONF.bak.$(date +%Y%m%d%H%M%S)"
  cp "$CONF" "$BACKUP"
  warn "Existing config backed up to $BACKUP"
  warn "It will be replaced. Merge anything you need back in from the backup."
fi

if [[ $USE_TOML -eq 1 ]]; then
  cat > "$CONF" <<EOF
[font]
size = $FONT_SIZE

[font.normal]
family = "$FAMILY"
style = "Regular"

[font.bold]
family = "$FAMILY"
style = "Bold"

[font.italic]
family = "$FAMILY"
style = "Italic"

[font.bold_italic]
family = "$FAMILY"
style = "Bold Italic"
EOF
else
  cat > "$CONF" <<EOF
font:
  size: $FONT_SIZE
  normal:
    family: "$FAMILY"
    style: Regular
  bold:
    family: "$FAMILY"
    style: Bold
  italic:
    family: "$FAMILY"
    style: Italic
  bold_italic:
    family: "$FAMILY"
    style: Bold Italic
EOF
fi

info "Wrote $CONF"

# ---------- 3. verify ----------
echo
info "Glyph test — you should see icons, not boxes:"
printf '  powerline: \ue0b0 \ue0b2   git: \ue725 \uf09b   os: \uf17c \uf179   folder: \uf07b \uf115\n'
echo
info "Ligature test (FiraCode):  ->  =>  !=  >=  ===  <!--"
echo
info "Alacritty live-reloads its config; open a new window to see the change."
