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
| `gsa` / `gsd` / `gsr` | add / delete / replace a surrounding — `mini.surround`, via the `coding.mini-surround` extra. Note these are *not* tpope's `ysiw"` / `cs"'` |
| `<space>e` / `<space>E` | yazi, at the current file / at cwd. These are LazyVim's explorer keys, repointed: `snacks.explorer` is disabled here, so there is no sidebar and `<space>fe`/`<space>fE` are unbound |
| `<space>-` / `<space>cw` / `<C-Up>` | yazi at the current file / at cwd / resume the last session. `<space>-` therefore no longer splits the window below — use `<C-w>s` |

Everything else (`<space>ff` find files, `<space>/` grep, `gd` go to
definition, etc.) is stock LazyVim — see `:LazyExtras` for what's enabled and
`:Lazy` for installed plugins.

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
- **Colorscheme:** `custom` — a plain vimscript colorscheme in
  `nvim/.config/nvim/colors/custom.vim`, no plugin involved (background
  `#202020`). catppuccin and tokyonight are still installed but unused by
  nvim; catppuccin mocha is what themes tmux's status bar and lazygit, which
  is why it stays.
- **Cursor:** insert mode uses the same solid block as normal/visual instead
  of nvim's default thin bar, tinted through an `InsertCursor` group whose
  colour is mixed towards `Normal`'s background at load and re-mixed on
  `ColorScheme`. A terminal cursor has no alpha channel — DECSCUSR carries a
  shape, OSC 12 a single opaque colour — so the translucent look comes from
  that blend plus leaving the character under the cursor its normal
  foreground rather than inverting it. `smear-cursor.nvim` adds the movement
  trail; it draws half-block glyphs through extmarks rather than graphics,
  which is why it survives GNOME Terminal and tmux. It also appends
  `a:SmearCursorHideable` to `guicursor` on load, which outranks
  `InsertCursor` — see the re-append in
  `nvim/.config/nvim/lua/plugins/smear-cursor.lua`.
- **tmux/lazygit plugins are plain `git clone`s**, not a plugin manager
  (no TPM), matching how `zsh-autosuggestions`/`zsh-syntax-highlighting` are
  already handled in this repo — one less abstraction, and `cat` on any
  plugin script tells you exactly what it does.
- **Keyboard-layout widget (`lua/plugins/kb-layout.lua`) asks X, not GNOME.**
  The layout lives outside nvim, so it has to be polled, and the owner
  differs per machine: under WSL it's Windows (PowerShell), here it's the X
  server. `~/.profile` runs `setxkbmap -layout us,ru -option
  grp:ctrl_shift_toggle`, so Ctrl+Shift flips the XKB group inside X and
  gnome-settings-daemon never finds out — `org.gnome.desktop.input-sources
  current` sits at 0 permanently while the real group is 1, which pinned the
  widget to `US`. The X11 backend reads `XkbGetState` through LuaJIT FFI
  (neither `xkb-switch` nor `xkblayout-state` is packaged for Ubuntu, and FFI
  keeps a poll a function call rather than a process spawn) and is tried
  ahead of GNOME, so a GNOME session that still switches through raw XKB
  can't answer confidently and wrongly. Falls through untouched when
  `DISPLAY` is unset, so the file stays safe to stow anywhere.
- **`tmux-sessionizer`'s project list is a fixed array**, not a scan of
  `$HOME` — `$HOME` has DB dumps, six duplicate checkouts of the same
  internal work repo, and assorted archives that would show up as noise.
  Edit the `projects=(...)` array in `tmux/.local/bin/tmux-sessionizer`
  directly to add/remove entries.

## Known caveats

These were hit setting this up on Ubuntu 22.04 - fixes are in
[SETUP.md](SETUP.md#5-first-neovim-launch), summary here. **This machine has
since moved to Ubuntu 24.04.4 (glibc 2.39)**, so the glibc one no longer
applies here; it's kept because SETUP.md still targets 22.04.

- **Icons are off** in both LazyVim's UI and lazygit - the terminal font
  (`Terminus (TTF)`) isn't Nerd-Font-patched. Applies to whichever terminal
  is in use: `ghostty`'s config is in this repo, but the day-to-day terminal
  on this box is GNOME Terminal, whose font lives in its own profile
  (`gsettings`, not a dotfile). A patched `JetBrainsMonoNL Nerd Font` is
  already installed at `~/.local/share/fonts` for whenever you want to switch
  and flip icons back on. Terminus also lacks the Legacy Computing block at
  `U+1FB00`, which is why the cursor trail renders at half-cell rather than
  quarter-cell granularity.
- **Treesitter parsers fail to compile** (`GLIBC_2.39' not found`) - mason's
  `tree-sitter-cli` needs a newer glibc than Ubuntu 22.04 ships. Moot on
  24.04.
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

**Adding a *new* file needs a re-stow.** Stow links file by file, not
directory by directory, wherever a package's directory contains anything it
didn't create - so a new `lua/plugins/foo.lua` will not appear under
`~/.config/nvim` on its own, and lazy.nvim simply won't see the spec (no
error, the plugin just never installs):

```bash
cd ~/dotfiles && stow -t ~ -R nvim
```

Related trap when inspecting the links: some directories *are* folded into a
single symlink (`~/.config/nvim/colors`, `~/.config/nvim/after`,
`~/.config/lazygit`). Files inside them are not symlinks themselves, so
testing a file with `[ -L ]` reports "not linked" while the path resolves
into this repo perfectly well - and any `rm` on such a path deletes the
original here. Compare `realpath` of both sides instead.

## Left for you to explore

Per how I like to learn this stuff — these are intentionally not explained
away above, so you dig in yourself when curious:

- **`:LazyExtras`** inside nvim — the actual list of what's enabled
  (`coding.mini-surround`, `formatting.prettier`, `lang.dotnet`,
  `lang.typescript`, `lang.vue`, `linting.eslint`) and what else LazyVim
  ships that isn't turned on here. Deliberately *not* enabled: `lang.tailwind`
  (no Tailwind in any of these projects), `editor.leap` (duplicate of flash),
  `coding.nvim-cmp` (duplicate of blink), the extra file explorers and
  `editor.fzf` (telescope is already here). `test.core`, `util.mini-hipatterns`
  and `dap.core` are worth revisiting once there's a concrete need.
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
