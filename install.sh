#!/usr/bin/env bash
# Bootstraps this dotfiles repo on a new machine.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(ghostty zsh starship)

if ! command -v stow >/dev/null 2>&1; then
  echo "GNU Stow not found. Install it, e.g.:"
  echo "  sudo apt install stow"
  exit 1
fi

echo "==> Cloning zsh plugins"
ZSH_PLUGIN_DIR="$HOME/.zsh/plugins"
mkdir -p "$ZSH_PLUGIN_DIR"

clone_or_update() {
  local repo="$1" dest="$2"
  if [ -d "$dest/.git" ]; then
    git -C "$dest" pull --ff-only
  else
    git clone --depth 1 "$repo" "$dest"
  fi
}

clone_or_update https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGIN_DIR/zsh-autosuggestions"
clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting"

echo "==> Stowing packages: ${PACKAGES[*]}"
cd "$DOTFILES_DIR"
for pkg in "${PACKAGES[@]}"; do
  stow --restow --target="$HOME" "$pkg"
done

echo "==> Done. Open a new terminal (or 'exec zsh') to pick up changes."
echo "    If your login shell isn't zsh yet: chsh -s \"\$(which zsh)\""
