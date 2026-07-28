#!/usr/bin/env bash
#
# install.sh — copies these dotfiles into $HOME.
# Any pre-existing file/dir that would be overwritten is backed up
# (zipped) into ~/.oldenv.zip before being replaced.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$(mktemp -d)"
BACKUP_ZIP="$HOME/.oldenv.zip"

# repo path -> $HOME-relative destination
FILES=(
    ".bashrc:.bashrc"
    ".bashrc.d:.bashrc.d"
    ".vimrc:.vimrc"
    ".tmux.conf:.tmux.conf"
    ".tmux:.tmux"
    "scripts:scripts"
)

info()  { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn()  { printf '\033[1;33m==>\033[0m %s\n' "$1"; }

command -v zip >/dev/null 2>&1 || { echo "zip is required but not installed. Aborting." >&2; exit 1; }

backed_up=0

for entry in "${FILES[@]}"; do
    src="${DOTFILES_DIR}/${entry%%:*}"
    dest="$HOME/${entry#*:}"

    if [[ -e "$dest" || -L "$dest" ]]; then
        warn "Backing up existing $dest"
        mkdir -p "$(dirname "${BACKUP_DIR}/${entry#*:}")"
        mv "$dest" "${BACKUP_DIR}/${entry#*:}"
        backed_up=1
    fi

    mkdir -p "$(dirname "$dest")"
    cp -r "$src" "$dest"
    info "Copied $src -> $dest"
done

if [[ "$backed_up" -eq 1 ]]; then
    (cd "$BACKUP_DIR" && zip -r -q -y "$BACKUP_ZIP" .)
    info "Backup of replaced files saved to $BACKUP_ZIP"
fi

rm -rf "$BACKUP_DIR"

info "Done."
