**Note, this repository is no longer actively maintained.**

# ~/.dotfiles

This repository contains dotfiles that I use, as well as a system for installing and keeping them up to date. You are welcome to use this too, and I try to make that easy!

## Key Points

* `zsh` for main shell
* Don't try and add too much high-level magic, just reduce the sharp edges and pain points the Linux environment has (ie, Make It All Work The Way I Want It To)
* Unobtrusive, opt-in automatic updates.
* Backwards compatibility is good, but flawless backwards compatibility isn't a goal.

## System Requirements

1. A Github account
3. Linux, OS X or FreeBSD with git & zsh installed

## Installation

`wget -O ~/.zshrc https://raw.github.com/alexjurkiewicz/dotfiles/master/zshrc && exec zsh -il`

Then you can:

* Create your local CONFIG file.
* Install/update all other dotfiles in the respository using `dotfiles-install`.
* Receive new updates with `dotfiles-update`.

## Uninstallation

1. Delete `~/.zshrc` and `~/.dotfiles/`.
2. If you installed the other dotfiles in this repo you'll need to remove them by hand.

## Tell me more about the zshrc highlights

* Selects **prompt colour schemes** based on hostname (home, work, unknown, plus red for root sessions)
* **Extra keyboard navigation shortcuts** that I've picked up elsewhere over the years
* **Hostname autocomplete entries are passed through to remote hosts.** Super useful when bouncing around servers!
* **ssh-agent interface improvements.** Run ssh-agent to create an initial ssh-agent process on a server. Run ssh-agent later to reconnect to the *same* agent.
* **Prompt, window title and screen/tmux title handling.** Prompt includes git information when you're inside a git repository.
* A whole bunch of aliases, prettiness, easter eggs, etc

## Tell me more about the other dotfiles

These other files are shorter and easier for you to understand at a quick glance.

* **screen and tmux** should look and behave similarly. In particular, tmux has screen's shortcut keys for all the commands I regularly use.
* **vim** gets syntax highlighting support for a number of sysadminey file formats that aren't included by default.
* **vim** config subscribes to the One True Indent Style of 4-space tabs.
* **git** has some one-char aliases.

## Tell me more about the automatic updates

A simple process.

* `git fetch` runs in the ~/.dotfiles repository a maximum of once per day.
* If there are pending updates, you are prompted on shell start.
* The file 'MAP' stores a mapping of repository files to real locations, and is used by the dotfiles-install command.

## Tell me more

* Web: https://github.com/alexjurkiewicz/dotfiles
