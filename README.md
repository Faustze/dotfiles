# dotfiles

Personal config for `ghostty`, `zsh`, and `starship`, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

Each top-level directory is a stow package that mirrors `$HOME`:

```
ghostty/.config/ghostty/config
zsh/.zshrc
starship/.config/starship.toml
```

## Bootstrap on a new machine

```bash
sudo apt install stow zsh   # if not already installed
git clone https://github.com/Faustze/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` clones `zsh-autosuggestions` and `zsh-syntax-highlighting` into
`~/.zsh/plugins` (not vendored in this repo) and symlinks every package into
`$HOME` via `stow`.

To make zsh your login shell:

```bash
chsh -s "$(which zsh)"
```

## Adding a new package

```bash
mkdir -p newpkg/.config/newtool
mv ~/.config/newtool/config newpkg/.config/newtool/config
stow --target="$HOME" newpkg
```

## Updating

Edit files directly in `~/dotfiles` (they're symlinked into `$HOME`, so
changes apply immediately), then commit and push.
