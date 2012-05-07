# .zshrc -- Alex Jurkiewicz
# http://alex.jurkiewi.cz/.zshrc
# alex@bluebottle.net.au

# This is a very heavy RC file. If you're logging into a heavily loaded
# system, consider using a simpler shell until you fix it: ssh -t host /bin/sh

[[ -r ~/.zshrc.local.before ]] && . ~/.zshrc.local.before

#####
# Basic Information
#####
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:$PATH

# Initial colours setup -- required by a few things further in
[[ -x $(which dircolors) ]] && eval `dircolors` >/dev/null 2>&1
autoload colors && colors

# What are we?
export FULLHOST=$(hostname --fqdn 2>/dev/null || hostname -f 2>/dev/null || hostname)
export SHORTHOST=$(echo $FULLHOST | cut -d. -f1-2)

# Where are we?
case $FULLHOST in
*.bluebottle.net.au|*.home|ajlaptop*|ajvm*|*.local)
        ourloc=home
        ucolor=$fg_bold[green]
        ;;
*.siteminder.com|*.siteminder.com.au|*.smuat|*.smtpi|*.bbuat|*.bbtpi|*.siteminder.co.uk|*.syd|*.dev)
        ourloc=work
        ucolor=$fg_bold[cyan]
        ;;
*)
        ourloc=unknown
        ucolor=$fg_bold[white] ;;
esac

#####
# Environment Setup
#####

# Some global zlogout files (RHEL...) clear the screen. Gross.
grep -q clear /etc/zlogout 2>/dev/null && unsetopt GLOBAL_RCS

unset MAILCHECK
unset MAIL

# Autodetect $LANG. Since this is slow, cache the result so it's not run every time.
if [[ ! -f ~/.zshrc.local.before ]] ; then
	touch ~/.zshrc.local.before
fi
if ! egrep -q "^export LANG=" ~/.zshrc.local.before ; then
	echo -n "Autodetecting \$LANG... "
	if [[ -n "$(locale -a | egrep -i "en_(AU|US)\.utf-?8" | head -1)" ]] ; then
		# Linux: en_AU.utf8
		# FreeBSD / OSX: en_AU.UTF-8
		# Use AU or US utf8, or fall back to C
		export LANG=$(locale -a | egrep -i "en_(AU|US)\.utf-?8" | head -1)
	else
		export LANG=C
	fi
	echo $LANG
	echo "export LANG=$LANG" >> ~/.zshrc.local.before
fi

autoload -U tcp_open
zmodload zsh/stat
echo ${^fpath}/url-quote-magic(N) | grep -q url-quote-magic && autoload -U url-quote-magic && zle -N self-insert url-quote-magic
autoload -U zed
autoload -U zargs
autoload -U zcalc
autoload -U zmv

WORDCHARS='*?_-.[]~=&;!#$%^(){}<>' #Removed '/'

HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt nobeep interactivecomments kshglob autocd histfindnodups noflowcontrol extendedglob extendedhistory
setopt autolist nolistambiguous # On first tab, complete as much as you can and list the choices
setopt histnostore              # Don't put 'history' into the history list
setopt histignoredups           # Don't add identical events in a row (ok in different parts of the file)
setopt incappendhistory         # Add to history as we go
setopt nocheckjobs nohup longlistjobs

stty -ixon #no XON/XOFF
bindkey -e
bindkey '\e[3~' delete-char
bindkey '^[[3;5~' kill-word
bindkey '^Q' kill-word
bindkey ' ' magic-space

# gnome terminal, konsole, terminator
        bindkey '^[5D' emacs-backward-word      # ctrl-left
        bindkey '^[5C' emacs-forward-word       # ctrl-right
        bindkey '^[[1;5C' emacs-forward-word    # ctrl-left - FreeBSD
        bindkey '^[[1;5D' emacs-backward-word   # ctrl-right - FreebSD
        bindkey '^A' beginning-of-line
        bindkey '^E' end-of-line
        bindkey '^[OH' beginning-of-line        # home
        bindkey '^[OF' end-of-line              # end
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
[[ -r ~/.ssh/known_hosts ]] && _ssh_hosts=(${${${${${${(f)"$(<$HOME/.ssh/known_hosts)"}:#[\|]*}%%\ *}%%,*}##\[}%%]:*}) || _ssh_hosts=() # fixed to ignore port specifiers: from oh-my-zsh pull request 440
[[ -r /etc/hosts ]] && : ${(A)_etc_hosts:=${(s: :)${(ps:\t:)${${(f)~~"$(</etc/hosts)"}%%\#*}##[:blank:]#[^[:blank:]]#}}} || _etc_hosts=()
[[ -n $LC_XHOSTS ]] && _lc_hosts=(${(s: :)LC_XHOSTS})
_hosts=(
	"$_ssh_hosts[@]"
	"$_etc_hosts[@]"
	"$_lc_hosts[@]"
	localhost
)
alias ssh="LC_XHOSTS=\"$_hosts[*]\" ssh"

# Other autocomplete
zstyle ':completion:*:hosts' hosts $_hosts
zstyle ':completion:*:hosts' ignored-patterns ip6-localhost ip6-loopback localhost.localdomain
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:users' ignored-patterns _dhcp _pflogd adm apache avahi avahi-autoipd backup bin bind clamav cupsys cyrusdaemon daemon Debian-exim dictd dovecot games gnats gdm ftp halt haldaemon hplip ident identd irc junkbust klog kmem libuuid list lp mail mailnull man messagebus mysql munin named news nfsnobody nobody nscd ntp ntpd operator pcap polkituser pop postfix postgres proftpd proxy pulse radvd rpc rpcuser rpm saned shutdown smmsp spamd squid sshd statd stunnel sync sys syslog toor tty uucp vcsa varnish vmail vde2-net www www-data xfs couchdb kernoops libvirt-qemu rtkit speech-dispatcher usbmux dbus gopher
zstyle ':completion:*:*:(^rm):*:*files' ignored-patterns '*?~' # Ignore files ending in ~ for all commands but rm
zstyle ':completion:*:processes' command "ps -Ao pid,user,command -w"
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:kill:*' force-list always # Show processlist even if only one entry
# zstyle ':completion:*:*:-command-:*' ignored-patterns '*.cmd'	# Ignore *.cmd in $PATH # for AWS
zstyle '*' single-ignored show # If there's only one match but it's ignored, show it
export ZLE_REMOVE_SUFFIX_CHARS='' && export ZLE_SPACE_SUFFIX_CHARS='' # Don't modify completions after printing them

#####
# Alias, Default Programs, Program Options Setup
#####
alias ssh="LC_XHOSTS=\"$_hosts[*]\" ssh"
if [[ -x $(which vim) ]] ; then
	export EDITOR=vim ; export VISUAL=vim ; alias vi=vim
else
	export EDITOR=vi ; export VISUAL=vi
fi

# Colours
if ls -F --color=always >&/dev/null; then
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
		echo "alias vess=$vess" >> ~/.zshrc.local.before
	else
		echo "not found!"
		alias vess=$PAGER
		echo "alias vess=$PAGER" >> ~/.zshrc.local.before
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
setenv() { export $1=$2 } # Woohoo csh
sudo() { [[ $1 == (vi|vim) ]] && ( shift && sudoedit "$@" ) || command sudo "$@"; } # sudo vi/vim => sudoedit
excuse() { nc bofh.jeffballard.us 666 | tail -1 | sed -e 's/.*: //' }
hl() { pattern=$(echo $1 | sed 's!\/!\\/!g') ; sed "s/$pattern/[1m[31m&[0m/g;" } # Like grep, but prints non-matching lines
alias clean='sed -e "s/[ \t]*$//"'
[[ -f /usr/share/pyshared/bzrlib/patiencediff.py ]] && alias pdiff="python /usr/share/pyshared/bzrlib/patiencediff.py"
alias portsnap-update='sudo portsnap fetch && sudo portsnap update' # FreeBSD
whence motd &>/dev/null || alias motd="[[ -f /etc/motd ]] && cat /etc/motd"
sleeptil () {
    [[ $1 == "-q" ]] && local quiet=1 && shift

    local until=$(date -d "$*" +%s) # this is somewhere that the $@/$* difference matters
    local untilnice="$(date -d @$until "+%a %b %d %H:%M:%S")"
    local now=$(date +%s)
    local delta=$(($until-$now))

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
				revname=$(git name-rev --always --name-only HEAD)
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

# Perform a git checkout of the files if they don't already exist
if ! [[ -d ~/.dotfiles/.git ]] ; then
    echo "$fg_bold[white]Cloning dotfiles repository to ~/.dotfiles...$reset_color"
    git clone -q git://github.com/alexjurkiewicz/dotfiles.git ~/.dotfiles
    echo "$fg_bold[white]Done, run dotfiles-install to install all dotfiles$reset_color"
else
    ( # Run in a subshell so if you ctrl-c during this you don't end up with strange CWD.
        # If we can see a newer revision in origin/master, tell the user, otherwise fetch origin/master and check on next shell initialisation.
        cd ~/.dotfiles
        if [[ $(git rev-parse HEAD) != $(git rev-parse origin/master) ]] ; then
            if [[ -n "$(git rev-list HEAD..origin/master)" ]] ; then
                # We're behind. If this was blank, we'd be ahead, and in that case assume the user is aware of what's going on.
                echo "$fg_bold[white]Dotfile updates are available:$reset_color"
                git log --oneline HEAD..origin/master | cat
                echo "$fg_bold[white]Run update-dotfiles to apply all changes$reset_color"
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
                ( out=$(git fetch 2>&1) || echo "\n$fg_bold[white]Could not fetch ~/.dotfiles repository: $out$reset_color" ) &|
            fi
        fi
    )
fi

# Install all dotfiles
dotfiles-install() {
    OLD_IFS=$IFS # I hate having to do this
    IFS='
'
    for line in $(cat ~/.dotfiles/MAP | egrep -v '^#') ; do
        src=$(echo $line | awk '{print $1}')
        dst=$(echo $line | awk '{print $2}')
        dst=${(e)dst} # Perform parameter substitution on $dst
        if ! [[ -e $dst ]] ; then
            # The file doesn't exist, create a link to it from the repo
            if ! [[ -d $(dirname $dst) ]] ; then
                mkdir -pv $dst | tail -1
            fi
            ln -vs ~/.dotfiles/$src $dst
        else
            # The file does exist. It's either already been linked or is something else. In either case we won't touch it, but tell the user so they can be assured the command works in the former case and take action if desired in the latter.
            if [[ -h $dst ]] && [[ $(zstat -L +link $dst) = */.dotfiles/$src ]] ; then
                #echo "$dst is already installed: ($(zstat -L +link $dst))"
            else
                echo "$dst: file already exists, not installing."
            fi
        fi
    done
    IFS=$OLD_IFS # Is this even neccessary? Probably.

    # Special snowflake config file handling:
    # htop: uses /home/aj/.config/htop/htoprc in preference if it's there, so nuke it
    [[ -f $HOME/.config/htop/htoprc ]] && echo "$fg_bold[white]Warning: $HOME/.config/htop/htoprc exists and will override the installed $HOME/.htoprc$reset_color"
}

dotfiles-update() {
    cd ~/.dotfiles
    if [[ -n "$(git status --porcelain)" ]] ; then
        echo "~/.dotfiles repository unclean, not proceeding."
    else
        git pull >/dev/null
        echo "Updated to $(git rev-parse --short HEAD)"
    fi
}

# Login prettiness
#####

# If this is a login shell do a basic fingerprint on the system
# tmux by default creates login shells so don't when we're in there
if [[ -o login ]] && [[ -z "$TMUX" ]] ; then
	echo
	hostname
	if [[ -f /etc/issue.net ]] ; then
		head -n 1 /etc/issue.net
	elif [[ -f /etc/issue ]] ; then
		head -n 1 /etc/issue
	elif [[ `uname` = Darwin ]] ; then
		sw_vers -productName | tr '\n' ' ' ; sw_vers -productVersion
	fi
	uname -srm
	echo
fi

# Run the local override file if it's there
[[ -r ~/.zshrc.local.after ]] && . ~/.zshrc.local.after

echo -n # Prime $?

# vim:ft=zsh et ts=4
