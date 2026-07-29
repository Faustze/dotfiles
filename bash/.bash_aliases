# ~/.bash_aliases
#
# Ubuntu's stock ~/.bashrc already sources this file if it exists, which is why
# this package is only the aliases and not a whole .bashrc — that file also
# carries machine-local PATH exports that have no business in a shared repo.
#
# The list itself lives in the `shell` package so zsh and bash can't drift.
# Note this is sourced *after* the stock ll/la/l definitions above it in
# .bashrc, so the shared ones win.

[ -f "$HOME/.config/shell/aliases.sh" ] && . "$HOME/.config/shell/aliases.sh"
