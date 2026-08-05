# ~/.zshrc

# --- History -----------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY

# --- General shell behavior --------------------------------------------
setopt AUTO_CD
setopt CORRECT
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP

# --- Completion ----------------------------------------------------------
autoload -Uz compinit
compinit -d "$HOME/.cache/zsh/zcompdump-$ZSH_VERSION"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# --- Aliases -------------------------------------------------------------
# Shared with bash — see the `shell` package. Zsh-only aliases go below the
# source line, not in that file.
[ -f "$HOME/.config/shell/aliases.sh" ] && source "$HOME/.config/shell/aliases.sh"

# --- Key bindings ----------------------------------------------------------
bindkey -e
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

# push-line moved off its default ^[q: tmux binds M-q to pane cycling and
# grabs the key before the shell ever sees it. ^[Q is no better — tmux takes
# M-Q too, for the reverse cycle. ^[v was free on both sides.
bindkey '^[v' push-line

# --- Plugins (cloned by install.sh into .zsh/plugins, not vendored here) ---
ZSH_PLUGIN_DIR="$HOME/.zsh/plugins"

[ -f "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
  source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"

# syntax-highlighting must be sourced last
[ -f "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
  source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# --- fzf ---------------------------------------------------------------
if command -v fzf >/dev/null 2>&1; then
  [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && \
    source /usr/share/doc/fzf/examples/key-bindings.zsh
  [ -f /usr/share/doc/fzf/examples/completion.zsh ] && \
    source /usr/share/doc/fzf/examples/completion.zsh
fi

# --- nvm ------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# --- Prompt --------------------------------------------------------------
eval "$(starship init zsh)"
export PATH="$HOME/.local/bin:$PATH"

# kimi-code
export PATH="/home/faust/.kimi-code/bin:$PATH"

# --- .NET ----------------------------------------------------------------
# dotnet стоит через snap — без DOTNET_ROOT сторонние .NET-тулы
# (csharpier, netcoredbg и прочие из Mason) не находят рантайм
export DOTNET_ROOT="/var/snap/dotnet/common/dotnet"
export PATH="$DOTNET_ROOT:$HOME/.dotnet/tools:$PATH"

# --- Go ------------------------------------------------------------------
# тулчейн из ~/.local/go (не системный apt-пакет) + бинарники go install
export PATH="$HOME/.local/go/bin:$HOME/go/bin:$PATH"

# opencode
export PATH=/home/faust/.opencode/bin:$PATH
export PATH="/opt/freerdp-nightly/bin:$PATH"
