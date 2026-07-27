# dotfiles

Personal config for `ghostty`, `zsh`, `starship`, `nvim` (LazyVim), `tmux`, and
`lazygit`, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

Each top-level directory is a stow package that mirrors `$HOME`:

```
ghostty/.config/ghostty/config
zsh/.zshrc
starship/.config/starship.toml
nvim/.config/nvim/...            # LazyVim
tmux/.tmux.conf
tmux/.local/bin/tmux-sessionizer
lazygit/.config/lazygit/config.yml
```

## Bootstrap on a new machine

Quick version:

```bash
sudo apt install stow zsh   # if not already installed
git clone https://github.com/Faustze/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` clones plugins that aren't vendored in this repo
(`zsh-autosuggestions`, `zsh-syntax-highlighting`, `tmux-resurrect`,
`tmux-continuum`) and symlinks every package into `$HOME` via `stow`. It
does *not* install `nvim`/`lazygit`/`fzf` themselves (Ubuntu's apt neovim is
too old for LazyVim) or handle the first-run gotchas (glibc vs. mason's
treesitter CLI, `vue_ls` vs. a too-new TypeScript).

**For the full step-by-step version - including every gotcha above, in the
order you'll actually hit them - see [SETUP.md](SETUP.md).**

To make zsh your login shell:

```bash
chsh -s "$(which zsh)"
```

## Keybindings cheat sheet

### tmux (prefix is `C-a`, not the default `C-b`)

| Key | Action |
|---|---|
| `C-a C-a` | send a literal `C-a` (e.g. to the shell/readline) |
| `C-h` / `C-j` / `C-k` / `C-l` | move between panes — and seamlessly into nvim splits, no prefix needed |
| `prefix h/j/k/l` | move between panes (vi-style, repeatable) |
| `prefix H/J/K/L` | resize the current pane (repeatable) |
| `prefix \|` / `prefix -` | split pane vertically / horizontally, in the current path |
| `prefix f` | fuzzy-pick a project from the fixed list in `tmux-sessionizer` and jump to its session |
| `prefix g` | open `lazygit` in a popup for the current pane's directory; closes itself on exit |

Session persistence is automatic: `tmux-continuum` saves every 15 minutes and
restores the last session when the tmux server starts (`tmux-resurrect`
under the hood, including nvim's own session if you `:mksession`).

### nvim (LazyVim)

Full default keymap: `:help lazyvim` or press `<space>` and wait for
which-key. A few non-default additions from this setup:

| Key | Action |
|---|---|
| `<C-h/j/k/l>` | move between nvim splits, or out into a tmux pane at the edge |
| `<C-h/j/k/l>` in a terminal buffer | same, straight from terminal mode — no `<C-\><C-n>` first. Inside a terminal `<C-h>`/`<C-l>` switch buffers instead (the terminal-mode stand-in for `<S-h>`/`<S-l>`, which would eat a capital H/L in the shell) |
| `<Esc><Esc>` in a terminal buffer | leave terminal mode in place, instead of `<C-\><C-n>` |

Everything else (`<space>ff` find files, `<space>/` grep, `<space>e` file
explorer, `gd` go to definition, etc.) is stock LazyVim — see `:LazyExtras`
for what's enabled and `:Lazy` for installed plugins.

### lazygit

Standard lazygit bindings (`?` for help inside it). Only the theme is
customized here to match nvim/tmux (catppuccin mocha).

## Why these specific choices

- **Formatting (`conform.nvim` via LazyVim's `formatting.prettier` +
  `linting.eslint` extras):** prettier only runs if the project actually has
  a `.prettierrc` (`vim.g.lazyvim_prettier_needs_config = true` in
  `nvim/.config/nvim/lua/config/options.lua`); otherwise `eslint --fix` runs
  via the eslint LSP on save. This matches two real conventions across my
  projects — antfu-style configs (`todo-app`, `svrv_tech/front`,
  `SUMO-project/front`) format via eslint with no prettier config at all,
  while `staff_app`-style projects ship their own `.prettierrc` (tabs,
  `printWidth: 150`). Nothing is hardcoded globally.
- **Colorscheme:** catppuccin mocha, picked over tokyonight (LazyVim's
  default) and onedark by eye — see chosen swatches in the conversation that
  set this up.
- **tmux/lazygit plugins are plain `git clone`s**, not a plugin manager
  (no TPM), matching how `zsh-autosuggestions`/`zsh-syntax-highlighting` are
  already handled in this repo — one less abstraction, and `cat` on any
  plugin script tells you exactly what it does.
- **`tmux-sessionizer`'s project list is a fixed array**, not a scan of
  `$HOME` — `$HOME` has DB dumps, six duplicate checkouts of the same
  internal work repo, and assorted archives that would show up as noise.
  Edit the `projects=(...)` array in `tmux/.local/bin/tmux-sessionizer`
  directly to add/remove entries.

## Known caveats

Three environment-specific gotchas were hit setting this up (all on Ubuntu
22.04) - fixes are in [SETUP.md](SETUP.md#5-first-neovim-launch), summary
here:

- **Icons are off** in both LazyVim's UI and lazygit - `ghostty`'s font
  (`Terminus (TTF)`) isn't Nerd-Font-patched. A patched `JetBrainsMonoNL
  Nerd Font` is already installed at `~/.local/share/fonts` for whenever you
  want to switch `ghostty`'s `font-family` and flip icons back on.
- **Treesitter parsers fail to compile** (`GLIBC_2.39' not found`) - mason's
  `tree-sitter-cli` needs a newer glibc than Ubuntu 22.04 ships.
- **`vue_ls` can crash on its first request** - mason resolves a `typescript`
  version for it that's newer than the language server has caught up to.

## Adding a new package

```bash
mkdir -p newpkg/.config/newtool
mv ~/.config/newtool/config newpkg/.config/newtool/config
stow --target="$HOME" newpkg
```

## Updating

Edit files directly in `~/dotfiles` (they're symlinked into `$HOME`, so
changes apply immediately), then commit and push.

## Left for you to explore

Per how I like to learn this stuff — these are intentionally not explained
away above, so you dig in yourself when curious:

- **`:LazyExtras`** inside nvim — the actual list of what's enabled
  (typescript, vue, tailwind, json, eslint, prettier, telescope, blink+luasnip)
  and what else LazyVim ships that isn't turned on here.
- **`:Mason`** — which LSP servers/formatters got auto-installed for the
  extras above, and where their binaries live.
- **`lua/config/lazy.lua`** — how the `spec` table decides load order and how
  `{ import = "..." }` pulls in a whole extra's plugin spec, options, and
  keymaps at once.
- **`is_vim` in `tmux.conf`** — the actual shell one-liner that detects
  "is the current pane running vim" to decide whether `C-h` etc. should be
  forwarded to nvim or handled by tmux.
- **`tmux-resurrect`'s save format** — a plain text file, no magic, after a
  manual `prefix + C-s` (continuum triggers this automatically too). Falls
  back to `~/.local/share/tmux/resurrect/last` since `~/.tmux/resurrect`
  itself doesn't exist as a directory (only `~/.tmux/plugins` does) — worth
  reading `resurrect_dir()` in `tmux-resurrect`'s `helpers.sh` to see why.
