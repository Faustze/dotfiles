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

```bash
sudo apt install stow zsh lazygit fzf   # if not already installed
git clone https://github.com/Faustze/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` clones plugins that aren't vendored in this repo
(`zsh-autosuggestions`, `zsh-syntax-highlighting`, `tmux-resurrect`,
`tmux-continuum`) and symlinks every package into `$HOME` via `stow`.

**Neovim is not installed by `install.sh`.** Ubuntu's `apt` only has 0.6.1,
which is too old for LazyVim (needs 0.9+). Install a recent release
yourself, e.g.:

```bash
curl -fLO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
tar -xzf nvim-linux-x86_64.tar.gz -C ~/.local/share/
mv ~/.local/share/nvim-linux-x86_64 ~/.local/share/nvim
ln -sf ~/.local/share/nvim/bin/nvim ~/.local/bin/nvim   # needs ~/.local/bin on PATH
```

First launch of `nvim` after stowing will bootstrap `lazy.nvim` and install
all plugins automatically (needs network access, takes a minute or two).

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

## Known caveat: icons

LazyVim's UI (file explorer, bufferline, statusline) and lazygit both
default to expecting a Nerd Font for icon glyphs. `ghostty` is currently set
to `Terminus (TTF)`, which isn't Nerd-Font-patched, so icons are left off in
both configs to avoid broken-glyph boxes. A patched `JetBrainsMonoNL Nerd
Font` is already installed at `~/.local/share/fonts` if you want to switch
`ghostty`'s `font-family` to it later and turn icons back on
(`gui.showIcons: true` + `gui.nerdFontsVersion: "3"` in lazygit's
`config.yml`; LazyVim/mini.icons picks it up automatically once the terminal
font supports it).

## Known caveat: treesitter parsers vs. Ubuntu 22.04's glibc

Mason installs the latest `tree-sitter-cli` to compile treesitter parsers,
but recent releases are built against glibc 2.39 - Ubuntu 22.04 only ships
2.35, so `:TSUpdate` fails for almost every parser
(`GLIBC_2.39' not found`). Any `tree-sitter` binary on `$PATH` shadows
mason's own copy (nvim-treesitter resolves it via `$PATH`, not mason's
injected bin dir), so the fix is to put a compatible version there instead:

```bash
npm uninstall -g tree-sitter-cli   # if you already tried the latest and hit this
npm install -g tree-sitter-cli@0.24.7   # last release before the glibc bump
nvim --headless "+TSUpdate" +qa
```

## Known caveat: `vue_ls` crashing on startup

Mason installs `vue-language-server` together with the latest `typescript`
as an "extra package". If that resolves to a very new major (TypeScript 7 at
the time of writing), `@vue/language-server` 3.3.7 crashes on the first
request (`TypeError: Cannot read properties of undefined (reading
'protocol')` in `server.js`, visible via `:LspLog`) - it wasn't built against
that TS internal API shape yet. Fix by pinning an older `typescript` inside
mason's copy of the package:

```bash
cd ~/.local/share/nvim/mason/packages/vue-language-server
npm install typescript@5.7.3
```

`vtsls` and the project's own TypeScript are untouched by this - it only
overrides the copy `vue-language-server` bundles for itself.

Only relevant on Ubuntu 22.04 (or anything else on glibc < 2.39). Newer distros
won't hit this at all.

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
- **`tmux-resurrect`'s save format** — `~/.tmux/resurrect/last` after a
  manual `prefix + C-s` (continuum triggers this automatically too) — worth
  a look to see it's just a plain text file, no magic.
