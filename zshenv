# Disable some termcap munging in /etc/zsh/zshrc that ruins my putty & unix-compatible arrow/ctrl-arrow bindkey setup
# AFAICT the debian config is "more correct" but completely incompatible with putty
export DEBIAN_PREVENT_KEYBOARD_CHANGES=1
