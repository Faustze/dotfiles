#!/usr/bin/env bash
# Bootstraps this dotfiles repo on a new machine.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(ghostty shell zsh bash starship nvim tmux lazygit)

if ! command -v stow >/dev/null 2>&1; then
  echo "GNU Stow not found. Install it, e.g.:"
  echo "  sudo apt install stow"
  exit 1
fi

clone_or_update() {
  local repo="$1" dest="$2"
  if [ -d "$dest/.git" ]; then
    git -C "$dest" pull --ff-only
  else
    git clone --depth 1 "$repo" "$dest"
  fi
}

echo "==> Cloning zsh plugins"
ZSH_PLUGIN_DIR="$HOME/.zsh/plugins"
mkdir -p "$ZSH_PLUGIN_DIR"
clone_or_update https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGIN_DIR/zsh-autosuggestions"
clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting"

echo "==> Cloning tmux plugins"
TMUX_PLUGIN_DIR="$HOME/.tmux/plugins"
mkdir -p "$TMUX_PLUGIN_DIR"
clone_or_update https://github.com/tmux-plugins/tmux-resurrect "$TMUX_PLUGIN_DIR/tmux-resurrect"
clone_or_update https://github.com/tmux-plugins/tmux-continuum "$TMUX_PLUGIN_DIR/tmux-continuum"

echo "==> Stowing packages: ${PACKAGES[*]}"
cd "$DOTFILES_DIR"
for pkg in "${PACKAGES[@]}"; do
  stow --restow --target="$HOME" "$pkg"
done

echo "==> Checking for required binaries (not managed by this repo)"
for bin in nvim tmux lazygit fzf git; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "    missing: $bin"
  fi
done

echo "==> Done. Open a new terminal (or 'exec zsh') to pick up changes."
echo "    If your login shell isn't zsh yet: chsh -s \"\$(which zsh)\""
