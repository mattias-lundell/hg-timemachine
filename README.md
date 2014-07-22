# Hg time machine

Shamelessly stolen from https://github.com/pidu/git-timemachine and
adapted to fit mercurial.

## Installation

Installation alternatives:

- Download hg-timemachine.el and drop it somewhere in your `load-path`.

## Usage

Visit a hg-controlled file and issue `M-x hg-timemachine` (or
bind it to a keybinding of your choice).

Use the following keys to navigate historic version of the file
 - `p` Visit previous historic version
 - `n` Visit next historic version
 - `w` Copy the hash of the current historic version
 - `q` Exit the time machine.
