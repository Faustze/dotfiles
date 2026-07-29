# Aliases shared by zsh and bash.
#
# Sourced from zsh/.zshrc and bash/.bash_aliases, so everything here has to be
# plain POSIX sh — no zsh-only globs, no bashisms. Shell-specific aliases stay
# in their own rc file.

alias ls='ls --color=auto'
alias ll='ls -lh'
alias la='ls -lAh'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias cc='clear'

alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gco='git checkout'
alias gbr='git branch'

alias dtb='dotnet build'
alias dtr='dotnet run'
