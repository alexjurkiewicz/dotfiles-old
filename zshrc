# .zshrc -- Alex Jurkiewicz
# http://alex.jurkiewi.cz/.zshrc
# alex@bluebottle.net.au

# This is a very heavy RC file. If you're logging into a heavily loaded
# system, consider using a simpler shell until you fix it: ssh -t host /bin/sh

[[ -r ~/.zshrc.local.cache ]] && . ~/.zshrc.local.cache
[[ -r ~/.zshrc.local.before ]] && . ~/.zshrc.local.before

#####
# Helper functions
#####
getdotfilesconfig() {
    if ! [[ -f ~/.dotfiles/CONFIG ]] ; then
        return
    fi
    if ! egrep -q "^$1 " ~/.dotfiles/CONFIG ; then
        return
    fi
    echo $(egrep "^$1 " ~/.dotfiles/CONFIG | cut -d\  -f2-)
}

#####
# Basic Information
#####
export PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/sbin:/bin:$PATH
if [[ -n $(getdotfilesconfig extrapath) ]] ; then
    export PATH=$(getdotfilesconfig extrapath):$PATH
fi

# Initial colours setup -- required by a few things further in
[[ -x $(which dircolors) ]] && eval `dircolors` >/dev/null 2>&1
autoload colors && colors

# What are we?
export FULLHOST=$(hostname --fqdn 2>/dev/null || hostname -f 2>/dev/null || hostname)
export SHORTHOST=$(echo $FULLHOST | cut -d. -f1-2)
insudo() {
    [[ -n $SUDO_USER ]] && [[ $USER != $SUDO_USER ]]
}

# Where are we?
case $FULLHOST in
    ${~$(getdotfilesconfig locations_home)}) # search zshexpn(1) for '${~' if you want to know what this param flag does
        ourloc=home
        ucolor=$fg_bold[green]
        ;;
    ${~$(getdotfilesconfig locations_work)})
        ourloc=work
        ucolor=$fg_bold[cyan]
        ;;
    *)
        ourloc=unknown
        ucolor=$fg_bold[white] ;;
esac

# How many CPUs do we have?
case $(uname -s) in
    Linux)
        NUM_CPUS=$(nproc)
        ;;
    Darwin|FreeBSD)
        NUM_CPUS=$(sysctl -n hw.ncpu)
        ;;
esac

#####
# Environment Setup
#####

# Some global zlogout files (RHEL...) clear the screen. Gross.
grep -q clear /etc/zlogout 2>/dev/null && unsetopt GLOBAL_RCS

unset MAILCHECK
unset MAIL

# Autodetect $LANG. Since this is slow, cache the result so it's not run every time.
if [[ ! -f ~/.zshrc.local.cache ]] ; then
    touch ~/.zshrc.local.cache
fi
if ! egrep -q "^export LANG=" ~/.zshrc.local.before ~/.zshrc.local.cache 2>/dev/null ; then
    echo -n "Autodetecting \$LANG... "
    real_locale=$(for locale in `getdotfilesconfig preferred_locale | tr ',' '\n'` ; do if real_locale=$(locale -a | grep $locale | egrep -i 'utf.?8') ; then echo $real_locale ; break ; fi ; done)
    if [[ -n $real_locale ]] ; then
        export LANG=$real_locale
    else
        export LANG=C
    fi
    echo $LANG
    echo "export LANG=$LANG" >> ~/.zshrc.local.cache
fi

zmodload zsh/stat
echo "${^fpath}/url-quote-magic(N)" | grep -q url-quote-magic && autoload -U url-quote-magic && zle -N self-insert url-quote-magic
autoload -U zargs

WORDCHARS='*?_-.[]~=&;!#$%^(){}<>' #Removed '/'

HISTFILE=~/.histfile.$FULLHOST
HISTSIZE=100000
SAVEHIST=100000
setopt nobeep interactivecomments kshglob autocd histfindnodups noflowcontrol extendedglob extendedhistory
setopt autolist nolistambiguous # On first tab, complete as much as you can and list the choices
setopt histnostore              # Don't put 'history' into the history list
setopt histignoredups           # Don't add identical events in a row (ok in different parts of the file)
setopt incappendhistory         # Add to history as we go
setopt nocheckjobs nohup longlistjobs

stty -ixon #no XON/XOFF
bindkey -e
bindkey '\e[3~' delete-char
bindkey '^Q' kill-word
bindkey ' ' magic-space
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
# gnome terminal, konsole, terminator, iTerm (basically everything except Putty)
bindkey '^[5D' emacs-backward-word      # ctrl-left (Linux)
bindkey '^[5C' emacs-forward-word       # ctrl-right (Linux)
bindkey '^[[1;5C' emacs-forward-word    # ctrl-left (FreeBSD)
bindkey '^[[1;5D' emacs-backward-word   # ctrl-right (FreeBSD)
                                        # OS X 10.10 (Yosemite) doesn't seem to allow ctrl-arrow reliably
                                        # Instead, use Karabiner to remap ctrl-arrow to opt-arrow and use
                                        # these binds:
bindkey '^[[1;9D' backward-word         # option-left
bindkey '^[[1;9C' forward-word          # option-right
bindkey '^[OH' beginning-of-line        # home (Linux, FreeBSD)
bindkey '^[OF' end-of-line              # end (Linux, FreeBSD)
bindkey '^[[H' beginning-of-line        # home (OS X)
bindkey '^[[F' end-of-line              # end (OS X)
bindkey '^[[3;5~' kill-word             # ^del (Linux)
bindkey '^[OM' accept-line              # numpad enter (OS X)
# PuTTY
bindkey '^[[1~' beginning-of-line       # home
bindkey '^[[4~' end-of-line             # end
bindkey '^[OC' emacs-forward-word       # ctrl-right
bindkey '^[OD' emacs-backward-word      # ctrl-left

# Autocomplete setup
autoload -U compinit && compinit -d ~/.zcompdump.$FULLHOST
autoload -U promptinit && promptinit
zmodload -i zsh/complist
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zcompcache

# SSH autocomplete
# This is cool. sshd is generally configured to allow passing LC_* envvars through, so we pass through our list of completion hosts in LC_XHOSTS and use it to build the host autocomplete list on the remote side!
[[ -r ~/.ssh/known_hosts ]] && _ssh_hosts=(${${${${${${(f)"$(<~/.ssh/known_hosts)"}:#[\|]*}%%\ *}%%,*}##\[}%%]:*}) || _ssh_hosts=() # fixed to ignore port specifiers: from oh-my-zsh pull request 440
[[ -r /etc/hosts ]] && : ${(A)_etc_hosts:=${(s: :)${(ps:\t:)${${(f)~~"$(</etc/hosts)"}%%\#*}##[:blank:]#[^[:blank:]]#}}} || _etc_hosts=()
[[ -n $LC_XHOSTS ]] && _lc_hosts=(${(s: :)LC_XHOSTS})
_hosts=(
    "$_ssh_hosts[@]"
    "$_etc_hosts[@]"
    "$_lc_hosts[@]"
    localhost
)
export LC_XHOSTS="$_hosts[*]"
#alias ssh="LC_XHOSTS=\"$_hosts[*]\" ssh"

# Other autocomplete
zstyle ':completion:*:hosts' hosts $_hosts
zstyle ':completion:*:hosts' ignored-patterns ip6-localhost ip6-loopback localhost.localdomain broadcasthost
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:users' ignored-patterns '_*' adm apache avahi avahi-autoipd backup bin bind clamav cupsys cyrusdaemon daemon Debian-exim dictd dovecot games gnats gdm ftp halt haldaemon hplip ident identd irc junkbust klog kmem libuuid list lp mail mailnull man messagebus mysql munin named news nfsnobody nobody nscd ntp ntpd operator pcap polkituser pop postfix postgres proftpd proxy pulse radvd rpc rpcuser rpm saned shutdown smmsp spamd squid sshd statd stunnel sync sys syslog toor tty uucp vcsa varnish vmail vde2-net www www-data xfs couchdb kernoops libvirt-qemu rtkit speech-dispatcher usbmux dbus gopher
zstyle ':completion:*:*:(^rm):*:*files' ignored-patterns '*?~' # Ignore files ending in ~ for all commands but rm
zstyle ':completion:*:processes' command "ps -Ao pid,user,command -w"
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:kill:*' force-list always # Show processlist even if only one entry
# zstyle ':completion:*:*:-command-:*' ignored-patterns '*.cmd' # Ignore *.cmd in $PATH # for AWS
zstyle '*' single-ignored show # If there's only one match but it's ignored, show it
export ZLE_REMOVE_SUFFIX_CHARS='' && export ZLE_SPACE_SUFFIX_CHARS='' # Don't modify completions after printing them

#####
# Alias, Default Programs, Program Options Setup
#####
if [[ -x $(which vim) ]] ; then
    export EDITOR=vim ; export VISUAL=vim ; alias vi=vim
else
    export EDITOR=vi ; export VISUAL=vi
fi
vim () {
    for i in $@ ; do
        if [[ -d $i ]] ; then
            echo "$i is a directory!"
            return 1
        fi
    done
    command vim "$@"
}

# Colours
if ls -F --color=auto >&/dev/null; then
    alias ls="ls --color=auto -F"
else
    alias ls="ls -F" # FreeBSD
fi
export GREP_OPTIONS='--color=auto'
export CLICOLOR=1 # FreeBSD
export LESS_TERMCAP_mb=$'\E[01;31m' # Pretty manpages
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'
export MYSQL_HISTFILE="/dev/null"
export ACK_PAGER="less -R"

# Try to reuse any existing SSH_AUTH_SOCK if one is not defined
if [[ -z $SSH_AUTH_SOCK ]] ; then
    case $(uname -s) in
        Darwin)
            pattern='*/launch-*/Listeners'
            ;;
        *)
            pattern='*/ssh*/agent*'
            ;;
    esac
    potential_socket=$(find /tmp/ -user ${SUDO_UID:-$UID} -type s -path $pattern 2>/dev/null | head -1)
    if [[ -r $potential_socket ]] ; then
        echo "Found an existing SSH auth socket: $potential_socket"
        export SSH_AUTH_SOCK=$potential_socket
    fi
fi
# SSH Agent. Store agent details in a file. Load the details and if they're invalid create a new agent.
ssh-agent () { 
    [[ -S $SSH_AUTH_SOCK ]] && echo "Agent socket already defined." && return
    if [[ -f ~/.agent.$FULLHOST ]] ; then # existing agent data, try it and break if it works
        eval `cat ~/.agent.$FULLHOST`
        ps -o "user,command" -p $SSH_AGENT_PID | tail -1 | egrep -q "^${USER}.*ssh-agent\$" && echo "Loaded existing agent." && return
    fi
    # else create new agent
    command ssh-agent | grep -v echo > ~/.agent.$FULLHOST
    eval `cat ~/.agent.$FULLHOST`
    echo "Created new agent."
}

# Pager
[[ -x $(which less) ]] && export PAGER=less || export PAGER=more
export LESS="-iRMq"
man --no-justification -w man &>/dev/null && export MANOPT="--no-justification"
if ! whence vess &>/dev/null ; then
    echo -n "Finding vess... "
    unsetopt nomatch
    vess=$(find /usr/local/share/vim/vim*/macros/less.sh /usr/share/vim/vim*/macros/less.sh 2>/dev/null | head -n 1)
    setopt nomatch
    if [[ -n $vess ]] ; then
        echo $vess
        alias vess=$vess
        echo "alias vess=$vess" >> ~/.zshrc.local.cache
    else
        echo "not found!"
        alias vess=$PAGER
        echo "alias vess=$PAGER" >> ~/.zshrc.local.cache
    fi
fi
# New commands
alias tmux="tmux -2" # 256colour support
alias hist='builtin history' # Show the last 15 events
alias history='history 1' # Show all events
alias j=jobs
alias sidp=sudo
alias t=tmux
alias s=screen
alias g=git
dstat --list &>/dev/null && alias dstat="dstat -tpcmdgn --top-cpu --top-bio" || alias dstat="dstat -tpcmdgn" # a little hacky, but I believe --top-cpu and --top-bio have always been core dstat plugins so just check if this dstat version has the plugin system
setenv() { export $1=$2l } # Woohoo csh
# convert 'sudo vim? $@' to 'sudoedit $@'
sudo() {
    if [[ $1 == (vi|vim) ]] ; then
        ( shift && sudoedit "$@" )
    else
        command sudo "$@"
    fi
}
excuse() { nc bofh.jeffballard.us 666 | tail -1 | sed -e 's/.*: //' }
hl() { pattern=$(echo $1 | sed 's!\/!\\/!g') ; sed "s/$pattern/[1m[31m&[0m/g;" } # Like grep, but prints non-matching lines
clean () {
    case `uname -s` in
        Darwin) # osx sucks, special case the -i
            sed -i '' -e's/[[:space:]]*$//' $1
            ;;
        *)
            sed -i'' -e's/[[:space:]]*$//' $1
            ;;
    esac
}
[[ -f /usr/share/pyshared/bzrlib/patiencediff.py ]] && alias pdiff="python /usr/share/pyshared/bzrlib/patiencediff.py"
alias portsnap-update='sudo portsnap fetch && sudo portsnap update' # FreeBSD
puppetup () {
    echo '$ sudo puppet agent -t'
    sudo puppet agent -t
}
puppet-syntax-check () {
    if [[ -f "${1=.}" ]] ; then
        puppet parser validate "${1=.}"
    else
        files="$(find "${1=.}" -name '*.pp' -print0)"
        numfiles=$(echo $files | tr '\0' '\n' | wc -l | awk '{print $1}')
        files_per_invoc=$(($numfiles / $NUM_CPUS + 1))
        echo "Testing $(($numfiles - 1)) *.pp files found in ${1=.}..."
        echo "$files" | nice xargs -0 -n $files_per_invoc -P $NUM_CPUS puppet parser validate
    fi
}
whence motd &>/dev/null || alias motd="[[ -f /etc/motd ]] && cat /etc/motd"
sleeptil () {
    if [[ $(uname -s) = "Darwin" ]] ; then
        echo "Sorry, OSX date isn't smart enough to do this."
        return 1
    fi
    [[ -z "$1" ]] && echo 'USAGE: `sleeptil [-q] <timespec>` eg `sleeptil 10pm`' && return 1
    [[ $1 == "-q" ]] && local quiet=1 && shift

    local until=$(date -d "$*" +%s) # this is somewhere that the $@/$* difference matters
    local untilnice="$(date -d @$until "+%a %b %d %H:%M:%S")"
    local now=$(date +%s)
    local delta=$(($until-$now))
    if [[ $delta -le 0 ]] ; then
        local until=$(date -d "$* tomorrow" +%s)
        local untilnice="$(date -d @$until "+%a %b %d %H:%M:%S")"
        local now=$(date +%s)
        local delta=$(($until-$now))
    fi

    [[ -z $quiet ]] && echo Sleeping $delta secs until $untilnice
    sleep $delta
    return
}

# Prompt
#####
typeset -ga preexec_functions
typeset -ga precmd_functions

# Called in preexec() and precmd() to set the window title and screen title (if in screen/tmux)
function title() {
    # $1 - the command running. Set to zsh if nothing is
    # $2 - truncated path
    local a
    # escape '%' chars in $1, make nonprintables visible
    a=${(V)1//\%/\%\%}
    # Truncate command, and join lines.
    a=$(print -Pn "$a" | tr -d "\n")
    # Remove 'sudo ' from the start of the command if it's there
    a=${a#sudo }
    # The format depends on how we're running
    case $TERM in
    screen*)
        # We're in screen or tmux, so set the terminal title and the screen window title
        # Screen/tmux tab title
        [[ $a = zsh ]] && print -Pn "\ek$2\e\\" # show the path if no program is running
        [[ $a != zsh ]] && print -Pn "\ek$a\e\\" # if a program is running show that

        # Terminal title
        if [[ -n $STY ]] ; then
            [[ $a = zsh ]] && print -Pn "\e]2;$SHORTHOST:S\[$WINDOW\]:$2\a"
            [[ $a != zsh ]] && print -Pn "\e]2;$SHORTHOST:S\[$WINDOW\]:${a//\%/\%\%}\a"
        elif [[ -n $TMUX ]] ; then
            # We're running in tmux, not screen
            [[ $a = zsh ]] && print -Pn "\e]2;$SHORTHOST:$2\a"
            [[ $a != zsh ]] && print -Pn "\e]2;$SHORTHOST:${a//\%/\%\%}\a"
        fi
        ;;
    xterm*|rxvt*)
        [[ $a = zsh ]] && print -Pn "\e]2;$SHORTHOST:$2\a"
        # extra processing here so you don't bork commandlines with % in them
        [[ $a != zsh ]] && print -Pn "\e]2;$SHORTHOST:${a//\%/\%\%}\a"
        ;;
    esac
}

#Choose the character (and colour) at the end of the prompt
if [[ `whoami` = root ]] ; then
    echo $fg_bold[white] "* NOTE: This is zsh, not the normal root shell" $reset_color
fi

# grey, aka #3E3E3E
grey='[38;5;248m'

# Prompt setup
# Fall back to a simple prompt if there's no colour support, or we're logged into the local console
if [[ -z $fg ]] ||  ( [[ `uname` == Linux ]] && [[ $TTY == /dev/tty* ]] ) || ( [[ `uname` == FreeBSD ]] && [[ $TTY == /dev/ttyv* ]] ) ; then
    PS1="%D{%H:%M:%S} %m %~ %(!.#.$) "
else
    PS1="%{$reset_color$grey%}%D{%H:%M:%S} %{%(#.$fg_bold[red].${ucolor})%}$SHORTHOST %{$reset_color$fg[yellow]%}%~ %{$fg_bold[magenta]%}%1v%{$fg_bold[green]%}%2v%{%(?.${ucolor}.$fg[red])%}%(!.#.$)%{$reset_color%} "
fi


# Set & reset the terminal title(s)
function title_precmd() {
    title "zsh" "%15<...<%~"
}
function title_preexec() {
    title "$1" "%15<...<%~"
}
precmd_functions+=title_precmd
preexec_functions+=title_preexec

# Use command-not-found if it's installed on the system
if [[ -x /usr/lib/command-not-found ]] ; then
    function command_not_found_handler() {
        /usr/lib/command-not-found -- $1
    }
fi

# VCS configuration
autoload -U is-at-least
if is-at-least 4.3.7 ; then
    autoload -Uz vcs_info
    zstyle ':vcs_info:*' enable git # only git for now
    zstyle ':vcs_info:*' get-revision true
    # These are saved by `vcs_info` as $vcs_info_msg_0_ to n
    # repo format (blank if not in one), revision, current branch, current action (merge etc) (only for actionformats)
    zstyle ':vcs_info:*' formats       "%s" "%i" "%b" "%a"
    zstyle ':vcs_info:*' actionformats "%s" "%i" "%b" "%a"
    
    autoload -U is-at-least
    function vcs_precmd() {
        vcs_info
        if [[ -n $vcs_info_msg_0_ ]] ; then # we're in a repository
            if [[ $vcs_info_msg_0_ = git ]] ; then
                revname=$(git name-rev --always --name-only HEAD 2>/dev/null)
                is-at-least 4.3.10 || vcs_info_msg_1_=$(git rev-list --max-count 1 HEAD) # older zsh missed this feature
                rev=$vcs_info_msg_1_[0,7] # 7 chars is enough revhash for anyone
                [[ -n $vcs_info_msg_3_ ]] && action="$vcs_info_msg_3_ " || action=""
            fi
            psvar[1]=("$revname ")
            psvar[2]=("$action")
        else
            psvar[1]=("")
            psvar[2]=("")
        fi
    }
    precmd_functions+=vcs_precmd
fi

# Update checking / management
#####

if ! insudo ; then
    # Perform a git checkout of the files if they don't already exist
    if ! [[ -d ~/.dotfiles/.git ]] ; then
        echo "$fg_bold[white]$ git clone -q git@github.com:alexjurkiewicz/dotfiles.git ~/.dotfiles$reset_color"
        if git clone -q git@github.com:alexjurkiewicz/dotfiles.git ~/.dotfiles ; then
            echo
            echo "$fg_bold[white]Done, create ~/.dotfiles/CONFIG from ~/.dotfiles/CONFIG.sample, then run dotfiles-install to install all dotfiles!$reset_color"
            echo
        fi
    else
        ( # Run in a subshell so if you ctrl-c during this you don't end up with strange CWD.
            # If we can see a newer revision in origin/master, tell the user, otherwise fetch origin/master and check on next shell initialisation.
            [[ -x $(which git) ]] || exit 0 # If there's no git on this system, don't try and auto-update
            cd ~/.dotfiles
            if [[ $(git rev-parse HEAD) != $(git rev-parse origin/master) ]] ; then
                if [[ -n "$(git rev-list HEAD..origin/master)" ]] ; then
                    # We're behind. If this was blank, we'd be ahead, and in that case assume the user is aware of what's going on.
                    echo "$fg_bold[white]Dotfile updates are available:$reset_color"
                    git log --oneline HEAD..origin/master | cat
                    echo "$fg_bold[white]Run dotfiles-update to accept all changes$reset_color"
                    if [[ -n "$(git rev-list origin/master..HEAD)" ]] ; then
                        echo "$fg_bold[white]Note: You have unpushed local changes."
                    fi
                fi
            else
                # Be nice to github, restrict autoupdate check to daily
                now=$(date +%s)
                if [[ -f ~/.dotfiles/.git/FETCH_HEAD ]] ; then
                    modified=$(zstat +mtime ~/.dotfiles/.git/FETCH_HEAD)
                else
                    # The file only exists after the first fetch, so fake it
                    touch ~/.dotfiles/.git/FETCH_HEAD
                    modified=0
                fi
                if [[ $(($now - $modified)) -gt 86400 ]] ; then
                    ( out=$(git fetch -q >/dev/null 2>&1) || echo "\n$fg_bold[white]Could not fetch ~/.dotfiles repository! Try \`git pull\` in ~/.dotfiles\n" ) &|
                fi
            fi
        )
    fi
fi

# Install all dotfiles
dotfiles-install() {
    if insudo ; then
        echo "Can't do this within sudo!"
        return 1
    fi
    if ! [[ -f ~/.dotfiles/CONFIG ]] ; then
        echo "You haven't created ~/.dotfiles/CONFIG yet!"
        return 1
    fi

    OLD_IFS=$IFS # I hate having to do this
    IFS='
'
    # For each file...
    for line in $(cat ~/.dotfiles/MAP | egrep -v '^#') ; do
        src=$(echo $line | awk '{print $1}')
        dst=$(echo $line | awk '{print $2}')
        dst=${(e)dst} # Perform parameter substitution on $dst
        flags=$(echo $line | awk '{print $3}')

        # Create the dest dir if it doesn't already exist
        if ! [[ -d $(dirname $dst) ]] ; then
            mkdir -pv $(dirname $dst) | tail -1
        fi
        # Now install the file
        case $flags in
            *s*)
                # This file isn't installed as a symlink, but as a real file,
                # because we need to substitute some values in it
                tempfile=$(mktemp .dotfiles.XXXXXX) ; chmod 600 $tempfile
                cat ~/.dotfiles/$src > $tempfile
                for line in $(cat ~/.dotfiles/CONFIG | egrep -v '^#') ; do
                    sub_name=$(echo $line | cut -d\  -f1)
                    sub_val=$(echo $line | cut -d\  -f2- | sed 's!\/!\\/!g') # XXX: Doesn't escape \n or &
                    sed -i'' -e "s/\!\!$sub_name\!\!/$sub_val/g" $tempfile
                done
                mv $tempfile $dst
                rm -f ${tempfile}-e # OSX (And FreeBSD?) sed generates these files due to different parsing of the above sed's options
                echo "Installed substituted copy of $src -> $dst"
                ;;
            *)
                # This is a normal file installed as a symlink
                if [[ -h $dst ]] && [[ $(zstat -L +link $dst) = */.dotfiles/$src ]] ; then
                    # correct symlink already exists
                    echo "Installed symlink of $src -> $dst"
                else
                    ln -vs ~/.dotfiles/$src $dst
                fi
                ;;
        esac
    done
    IFS=$OLD_IFS # Is this even neccessary? Probably.

    # Special snowflake config file handling:
    # htop: moved config file location, so warn about this
    if [[ -f ~/.config/htop/htoprc ]] && [[ -f ~/.htoprc ]] ; then
        echo "$fg_bold[white]Warning: ~/.config/htop/htoprc and ~/.htoprc both exist, you should probably delete the latter.$reset_color"
    fi
}

dotfiles-update() {
    if insudo ; then
        echo "Can't do this in sudo!"
        return 1
    fi
    ( # Run in a subshell so if you ctrl-c during this you don't end up with strange CWD.
        cd ~/.dotfiles
        if [[ -n "$(git status --porcelain)" ]] ; then
            echo "~/.dotfiles repository unclean, not proceeding."
        else
            oldrev=$(git rev-parse HEAD)
            git merge origin/master >/dev/null
            # Print changelog if there is one
            if [[ $oldrev != $(git rev-parse origin/master) ]] ; then
                echo "Changes:"
                git log --oneline $oldrev..HEAD | cat
            fi
        fi
    )
}

# Run the local override file if it's there
[[ -r ~/.zshrc.local.after ]] && . ~/.zshrc.local.after

echo -n # Prime $?

# vim:ft=zsh et ts=4
