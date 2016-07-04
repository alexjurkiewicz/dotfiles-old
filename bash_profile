export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# Aliases
alias g=git
alias t=tmux

# Default options
export LESS="-iRMq"

# Colour
export CLICOLOR=1
export LESS_TERMCAP_mb=$'\E[01;31m' # Pretty manpages
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'


# Use vim if available even if I type 'vi'
if [[ -x $(which vim) ]] ; then
    export EDITOR=vim ; export VISUAL=vim ; alias vi=vim
else
    export EDITOR=vi ; export VISUAL=vi
fi
# Fail instead of opening directories in vim
vim () {
    for i in $@ ; do
        if [[ -d $i ]] ; then
            echo "$i is a directory!"
            return 1
        fi
    done
    command vim "$@"
}

# Prompt
function find_git_branch {
    local branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    if [[ -n $branch ]] ; then
        git_branch=" $branch"
    else
        git_branch=''
    fi
}
PROMPT_COMMAND="find_git_branch; $PROMPT_COMMAND"
# Prompt is: '\t \h \W[ \$git_branch]* \$ '
# * when applicable
export PS1="\[\033[38;5;8m\]\t \[\033[38;5;10m\]\h \[$(tput sgr0)\]\[\033[38;5;3m\]\W\[$(tput bold)\]\[\033[38;5;13m\]\$git_branch \[\033[38;5;7m\]\\$ \[$(tput sgr0)\]"

# Keys
# To find terminal code for key combos, use `sed -n l`
# These remaps are designed to make an OSX laptop behave like
# a Windows textarea
# ctrl-arrow moves by word
# home/end (aka option-arrow) moves to start/end
# In Karabiner, remap fn to l_control, and l_control to l_options
# For a similar experience to a Windows keyboard
bind '"\033[H":backward-word'
bind '"\033[F":forward-word'
bind '"\033\033[D":beginning-of-line'
bind '"\033\033[C":end-of-line'
# Make C-w delete to previous whitespace or / character
stty werase undef  # Unmap C-w
bind '"\C-w":unix-filename-rubout'

# Completion
for file in /usr/local/etc/bash_completion.d/* ; do
  . $file
done
if which -s aws_completer ; then
  complete -C '/usr/local/bin/aws_completer' aws
fi
# Use git completion for `g` too, since it's an alias
__git_complete g _git
