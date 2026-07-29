# Setup guide: bootstrapping this dotfiles repo on a fresh machine

Linear walkthrough, in the order you'd actually hit each step. Everything
here was hit for real getting this running on Ubuntu 22.04 - the gotchas
aren't hypothetical.

For *what's in the repo and why*, see [README.md](README.md). This file is
just the runbook.

## 0. Prerequisites

```bash
sudo apt install stow zsh git curl unzip
```

`stow` links every package into `$HOME`. `curl`/`unzip` are needed for the
manual neovim install below.

## 1. Clone the repo

```bash
git clone https://github.com/Faustze/dotfiles.git ~/dotfiles
```

## 2. Install neovim (not via apt)

Ubuntu 22.04's `apt` only has neovim 0.6.1. LazyVim needs 0.9+, and this
setup was built against 0.12.x, so grab a current release directly instead:

```bash
curl -fLO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
tar -xzf nvim-linux-x86_64.tar.gz -C ~/.local/share/
mv ~/.local/share/nvim-linux-x86_64 ~/.local/share/nvim
ln -sf ~/.local/share/nvim/bin/nvim ~/.local/bin/nvim
rm nvim-linux-x86_64.tar.gz
```

Make sure `~/.local/bin` is on `$PATH` (it should already be, on most
Debian/Ubuntu setups - check with `echo $PATH | tr ':' '\n' | grep local/bin`).
Confirm: `nvim --version` should print 0.9+ (ideally 0.12+).

If you're not on Ubuntu 22.04 and your distro's neovim package is already
recent enough, just `apt install neovim` instead and skip this step.

## 3. Install lazygit and fzf

```bash
sudo apt install lazygit fzf
```

If your distro's apt doesn't have a recent-enough `lazygit` (Ubuntu 22.04's
own repos don't; this machine had a third-party source already configured
that did), grab a release binary directly from
https://github.com/jesseduffield/lazygit/releases instead.

## 4. Run install.sh

```bash
~/dotfiles/install.sh
```

This clones the plugins that aren't vendored in the repo
(`zsh-autosuggestions`, `zsh-syntax-highlighting`, `tmux-resurrect`,
`tmux-continuum`) and `stow --restow`s every package (`ghostty`, `shell`,
`zsh`, `bash`, `starship`, `nvim`, `tmux`, `lazygit`) into `$HOME`. It ends
with a check for required binaries not managed by this repo (`nvim`, `tmux`,
`lazygit`, `fzf`, `git`) - if anything's missing, go back to the relevant step
above.

## 5. First neovim launch

```bash
nvim
```

`lazy.nvim` bootstraps itself and installs every plugin - takes a minute or
two with a real network connection, and you'll see a progress UI. Once it
settles, quit and reopen once (`:qa` then `nvim` again) so filetype-specific
things (treesitter parsers, LSP servers) get a clean run.

**Treesitter parsers may fail to compile with a `GLIBC_2.39' not found`
error** if you're on Ubuntu 22.04 (glibc 2.35) - mason's `tree-sitter-cli` is
built against a newer glibc than that. Fix:

```bash
npm install -g tree-sitter-cli@0.24.7   # last release before the glibc bump
nvim --headless "+TSUpdate" +qa
```

(Needs Node/npm - if you don't have it yet, install via
[nvm](https://github.com/nvm-sh/nvm) or your distro's package.) Newer
distros (glibc >= 2.39) won't hit this at all.

**LSP servers (vtsls, vue_ls, eslint, tailwindcss, jsonls) install
automatically the first time you open a matching file** (`.ts`, `.vue`,
etc.) - mason installs them on demand via `mason-lspconfig`'s
`ensure_installed`. This only fires with a real UI attached (not
`nvim --headless`), so just open a real project file and wait; `:Mason`
shows install progress.

**`vue_ls` may crash on its first real request** with `TypeError: Cannot
read properties of undefined (reading 'protocol')` (check `:LspLog` to
confirm) if mason resolved a too-new `typescript` as vue-language-server's
bundled dependency and the language server hasn't caught up yet. Fix by
pinning an older one inside mason's copy of just that package:

```bash
cd ~/.local/share/nvim/mason/packages/vue-language-server
npm install typescript@5.7.3
```

This doesn't touch `vtsls` or any project's own TypeScript version - only
the copy `vue-language-server` uses internally.

## 6. tmux

```bash
tmux
```

Prefix is `C-a` (not the tmux default `C-b`). Try:
- `C-a f` - fuzzy-pick a project from the fixed list in
  `tmux/.local/bin/tmux-sessionizer` and jump to its session
- `C-a g` - open `lazygit` in a popup for the current pane
- `C-h/j/k/l` (no prefix) - move between panes, or into nvim splits if
  you're inside one

Session save/restore works with no extra steps: `tmux-continuum` autosaves
every 15 minutes and restores on tmux server start.

## 7. Optional: turn icons on

Both LazyVim's UI and lazygit default to expecting a Nerd Font and are
configured with icons off here because `ghostty`'s font isn't
Nerd-Font-patched. A patched `JetBrainsMonoNL Nerd Font` is already
installed at `~/.local/share/fonts` on this machine. To use it: point
`ghostty`'s `font-family` at `JetBrainsMonoNL Nerd Font`, then set
`gui.showIcons: true` + `gui.nerdFontsVersion: "3"` in
`lazygit/.config/lazygit/config.yml` (LazyVim/mini.icons picks up the font
automatically, no config change needed on the nvim side).

On a different machine, grab the font yourself from
https://github.com/ryanoasis/nerd-fonts/releases (the `JetBrainsMono.zip`
asset) if you want the same one.

## Troubleshooting quick reference

| Symptom | Fix |
|---|---|
| `nvim --version` shows 0.6.x | You're still on apt's neovim - see step 2 |
| `:TSUpdate` fails with `GLIBC_2.39' not found` | See step 5, treesitter fix |
| `vue_ls` client exits immediately, `:LspLog` shows a `ts.server.protocol` TypeError | See step 5, vue_ls fix |
| No LSP client attaches at all, `:Mason` shows nothing installing | Make sure you opened nvim normally (not `--headless`) - mason's auto-install is disabled without a real UI attached |
| Icons show as boxes/question marks | Expected - see step 7 |
| `tmux-sessionizer` doesn't list a project you expect | It's a fixed list, not an auto-scan - edit the `projects=(...)` array in `tmux/.local/bin/tmux-sessionizer` directly |
